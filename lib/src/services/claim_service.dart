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

    await _firestore.collection('claims').add({
      'donationId': donationId,
      'recipientId': userId,
      'needReason': needReason,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });

    await _firestore.collection('users').doc(userId).update({
      'claimsThisWeek': FieldValue.increment(1),
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

    await userRef.update({
      'rating': newAverage,
      'ratingCount': newRatingCount,
    });

    await _firestore.collection('claims').doc(claimId).update({
      'ratingGiven': rating,
    });
  }
}
