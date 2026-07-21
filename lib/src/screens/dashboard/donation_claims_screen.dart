import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/rating_dialog.dart';

class DonationClaimsScreen extends StatelessWidget {
  final String donationId;

  const DonationClaimsScreen({super.key, required this.donationId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Claims'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('claims')
            .where('donationId', isEqualTo: donationId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.checklist_rounded,
              title: 'No Pending Claims',
              description:
                  'When community members request this item, their applications will appear here.',
            );
          }

          final claims = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claimId = claims[index].id;
              final claim = claims[index].data() as Map<String, dynamic>;
              final needReason = claim['needReason'] ?? 'No reason provided';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Recipient Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const StatusBadge(status: 'PENDING'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Reason for Need:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        needReason,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Approve / Reject Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectClaim(claimId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accentRose,
                                side: const BorderSide(color: AppColors.accentRose),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              text: 'Approve',
                              height: 48,
                              onPressed: () => _approveClaim(claimId, context),
                            ),
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

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => RatingDialog(claimId: claimId),
      );
    }
  }

  Future<void> _rejectClaim(String claimId) async {
    await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
      'status': 'rejected',
      'rejectedAt': Timestamp.now(),
    });
  }
}
