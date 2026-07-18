import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Check if user can make a claim
  Future<bool> canUserClaim() async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    int claimsThisWeek = data['claimsThisWeek'] ?? 0;
    Timestamp? lastReset = data['lastResetDate'];

    final now = Timestamp.now();
    if (lastReset == null ||
        now.toDate().difference(lastReset.toDate()).inDays >= 7) {
      // Reset counter
      await _firestore.collection('users').doc(userId).update({
        'claimsThisWeek': 0,
        'lastResetDate': now,
      });
      return true;
    }

    return claimsThisWeek < 2;
  }

  // Create a claim request (pending approval)
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

    // Increment claim count
    await _firestore.collection('users').doc(userId).update({
      'claimsThisWeek': FieldValue.increment(1),
    });
  }
}
