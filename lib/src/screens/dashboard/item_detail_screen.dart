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
