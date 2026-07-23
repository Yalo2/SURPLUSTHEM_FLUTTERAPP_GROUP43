import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<bool> canUserClaim() async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    int claimsThisWeek = data['claimsThisWeek'] ?? 0;
    Timestamp? lastReset = data['lastResetDate'];

    final now = Timestamp.now();
    if (lastReset == null ||
        now.toDate().difference(lastReset.toDate()).inDays >= 7) {
      await _firestore.collection('users').doc(userId).update({
        'claimsThisWeek': 0,
        'lastResetDate': now,
      });
      return true;
    }

    return claimsThisWeek < 2;
  }

  Future<void> createClaim(String donationId, String needReason) async {
    if (!await canUserClaim()) {
      throw Exception('You have reached your weekly claim limit');
    }

    final donationRef = _firestore.collection('donations').doc(donationId);

    final existingClaims = await _firestore
        .collection('claims')
        .where('donationId', isEqualTo: donationId)
        .where('recipientId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    if (existingClaims.docs.isNotEmpty) {
      throw Exception('You have already requested this item');
    }

    await _firestore.runTransaction((transaction) async {
      final donationSnap = await transaction.get(donationRef);

      if (!donationSnap.exists) {
        throw Exception('This donation no longer exists');
      }

      final donationData = donationSnap.data() as Map<String, dynamic>;
      final donorId = donationData['donorId'];
      final status = donationData['status'] ?? 'available';

      if (donorId == userId) {
        throw Exception('You cannot claim your own donation');
      }

      if (status != 'available') {
        throw Exception('This item has already been claimed by someone else');
      }

      final claimRef = _firestore.collection('claims').doc();
      transaction.set(claimRef, {
        'donationId': donationId,
        'recipientId': userId,
        'donorId': donorId,
        'needReason': needReason,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
    });

    await _firestore.collection('users').doc(userId).update({
      'claimsThisWeek': FieldValue.increment(1),
    });
  }

  Future<void> approveClaim(String claimId) async {
    final claimRef = _firestore.collection('claims').doc(claimId);

    await _firestore.runTransaction((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      if (!claimSnap.exists) {
        throw Exception('Claim not found');
      }

      final claimData = claimSnap.data() as Map<String, dynamic>;
      final donationId = claimData['donationId'];
      final donationRef = _firestore.collection('donations').doc(donationId);
      final donationSnap = await transaction.get(donationRef);

      if (!donationSnap.exists) {
        throw Exception('Donation no longer exists');
      }

      final donationData = donationSnap.data() as Map<String, dynamic>;
      if ((donationData['status'] ?? 'available') != 'available') {
        throw Exception('This item has already been claimed');
      }

      transaction.update(donationRef, {
        'status': 'claimed',
        'claimedBy': claimData['recipientId'],
      });

      transaction.update(claimRef, {
        'status': 'approved',
        'approvedAt': Timestamp.now(),
      });
    });

    final claimSnap = await claimRef.get();
    final donationId = claimSnap.data()?['donationId'];
    final donorId = claimSnap.data()?['donorId'];

    // Increment the donor's total donations count
    if (donorId != null) {
      await _firestore.collection('users').doc(donorId).update({
        'totalClaims': FieldValue.increment(1),
      });
    }

    if (donationId != null) {
      final otherPending = await _firestore
          .collection('claims')
          .where('donationId', isEqualTo: donationId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in otherPending.docs) {
        if (doc.id != claimId) {
          await doc.reference.update({
            'status': 'rejected',
            'rejectedAt': Timestamp.now(),
            'rejectionReason': 'Item claimed by another recipient',
          });
        }
      }
    }
  }

  Future<void> rejectClaim(String claimId) async {
    await _firestore.collection('claims').doc(claimId).update({
      'status': 'rejected',
      'rejectedAt': Timestamp.now(),
    });
  }

  Future<void> rateRecipient(String claimId, double rating) async {
    final claimDoc = await _firestore.collection('claims').doc(claimId).get();
    final recipientId = claimDoc.data()?['recipientId'];
    if (recipientId == null) return;

    final userRef = _firestore.collection('users').doc(recipientId);
    final userDoc = await userRef.get();
    final currentRating = (userDoc.data()?['rating'] ?? 0.0) as num;
    final ratingCount = (userDoc.data()?['ratingCount'] ?? 0) as int;

    final newRatingCount = ratingCount + 1;
    final newAverage =
        ((currentRating * ratingCount) + rating) / newRatingCount;

    await userRef.update({'rating': newAverage, 'ratingCount': newRatingCount});

    await _firestore.collection('claims').doc(claimId).update({
      'ratingGiven': rating,
    });
  }
}