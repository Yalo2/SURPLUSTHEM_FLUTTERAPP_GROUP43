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

