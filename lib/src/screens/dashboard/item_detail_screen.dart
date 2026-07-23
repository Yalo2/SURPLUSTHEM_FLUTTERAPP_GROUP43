import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/claim_service.dart';
import 'donation_claims_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ClaimService _claimService = ClaimService();
  final TextEditingController _needReasonController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _itemData;
  Map<String, dynamic>? _donorData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _needReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.itemId)
          .get();

      if (doc.exists) {
        _itemData = doc.data();
        final donorId = _itemData?['donorId'];
        if (donorId != null) {
          final donorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(donorId)
              .get();
          if (donorDoc.exists) {
            _donorData = donorDoc.data();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading item detail: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  bool get isDonor =>
      _itemData?['donorId'] == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_itemData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Item Not Found',
          description: 'This donation post may have been removed by the donor.',
        ),
      );
    }

    final photoUrl = _itemData!['photoUrl'] as String?;
    final title = _itemData!['title'] ?? 'Untitled Item';
    final description = _itemData!['description'] ?? 'No description provided.';
    final category = _itemData!['category'] ?? 'General';
    final location = _itemData!['location'] ?? 'Kampala, Uganda';
    final status = _itemData!['status'] ?? 'available';

    final donorName = _donorData?['fullName'] ?? 'Community Donor';
    final donorRating = (_donorData?['rating'] ?? 5.0) as num;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Background Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: isDark
                              ? AppColors.darkSurfaceSubtle
                              : AppColors.lightSurfaceSubtle,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                  // Dark Scrim Gradient
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Location
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Donor Info Card
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                'Verified Donor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accentAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              donorRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Item Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Donor Action OR Recipient Claim Flow
                  if (isDonor) ...[
                    GradientButton(
                      text: 'View Pending Claims',
                      icon: Icons.list_alt_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DonationClaimsScreen(donationId: widget.itemId),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data?.data() as Map<String, dynamic>? ??
                            {};
                        final isVerified = data['phoneVerified'] == true;
                        if (isVerified) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your phone number isn\'t verified yet. Donors may be less likely to approve your request. Verify it in Settings.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Request This Surplus Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Briefly explain why you need this item to help the donor decide.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _needReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. For family meal prep / community shelter...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Submit Request',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _claimItem,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimItem() async {
    final reason = _needReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explain why you need this item'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _claimService.createClaim(widget.itemId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim request sent successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
