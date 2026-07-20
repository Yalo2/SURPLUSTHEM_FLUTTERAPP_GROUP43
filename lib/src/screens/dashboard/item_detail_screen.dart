import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/claim_service.dart';
import 'donation_claims_screen.dart'; // Import the claims screen

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
  String? _donorId;

  @override
  void initState() {
    super.initState();
    _loadDonationInfo();
  }

  Future<void> _loadDonationInfo() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(widget.itemId)
            .get();
    if (doc.exists) {
      setState(() => _donorId = doc.data()?['donorId']);
    }
  }

  bool get isDonor => _donorId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Donation Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image + Item Info (add your existing UI here)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDonor)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DonationClaimsScreen(
                                  donationId: widget.itemId,
                                ),
                          ),
                        );
                      },
                      child: const Text('View Pending Claims'),
                    )
                  else ...[
                    const Text(
                      'Why do you need this item?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _needReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Explain your need...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _claimItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Request This Item',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimItem() async {
    final reason = _needReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please explain why you need this item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _claimService.createClaim(widget.itemId, reason);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim request sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

