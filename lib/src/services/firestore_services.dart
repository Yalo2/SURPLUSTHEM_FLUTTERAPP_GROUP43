import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String get currentUserId => _auth.currentUser!.uid;

  // Check if user can claim (Weekly limit = 2)
  Future<bool> canUserClaim() async {
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();

    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    int claimsThisWeek = data['claimsThisWeek'] ?? 0;
    Timestamp lastReset = data['lastResetDate'] ?? Timestamp.now();

    // Reset counter if new week
    final now = Timestamp.now();
    final daysSinceReset = now.toDate().difference(lastReset.toDate()).inDays;

    if (daysSinceReset >= 7) {
      await _resetClaimsCounter();
      return true;
    }

    return claimsThisWeek < 2;
  }

  // Reset claims every week
  Future<void> _resetClaimsCounter() async {
    await _firestore.collection('users').doc(currentUserId).update({
      'claimsThisWeek': 0,
      'lastResetDate': Timestamp.now(),
    });
  }

  // Record a claim
  Future<void> recordClaim(String donationId, String needReason) async {
    // Create claim document
    await _firestore.collection('claims').add({
      'donationId': donationId,
      'recipientId': currentUserId,
      'needReason': needReason,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });

