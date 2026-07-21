import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/rating_dialog.dart';

class DonationClaimsScreen extends StatelessWidget {
  final String donationId;

  const DonationClaimsScreen({super.key, required this.donationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Pending Claims'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('claims')
                .where('donationId', isEqualTo: donationId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending claims'));
          }

          final claims = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claim = claims[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need Reason:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(claim['needReason'] ?? 'No reason provided'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                () => _approveClaim(claims[index].id, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Approve'),
                          ),
                          ElevatedButton(
                            onPressed: () => _rejectClaim(claims[index].id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveClaim(String claimId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
      'status': 'approved',
      'approvedAt': Timestamp.now(),
    });

    // Show rating dialog
    showDialog(
      context: context,
      builder: (_) => RatingDialog(claimId: claimId),
    );
  }

  Future<void> _rejectClaim(String claimId) async {
    await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
      'status': 'rejected',
      'rejectedAt': Timestamp.now(),
    });
  }
}
