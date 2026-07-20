import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final claims = snapshot.data!.docs;

          if (claims.isEmpty) {
            return const Center(child: Text('No pending claims'));
          }


          return ListView.builder(
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claim = claims[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Reason:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(claim['needReason'] ?? ''),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                () => _updateClaimStatus(
                                  claims[index].id,
                                  'approved',
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Approve'),
                          ),
                          ElevatedButton(
                            onPressed:
                                () => _updateClaimStatus(
                                  claims[index].id,
                                  'rejected',
                                ),
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

  Future<void> _updateClaimStatus(String claimId, String status) async {
    await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
      'status': status,
      'reviewedAt': Timestamp.now(),
    });
  }
}

