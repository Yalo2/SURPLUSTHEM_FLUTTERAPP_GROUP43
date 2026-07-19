import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'main_navigation_screen.dart'; // Your bottom navigation
import '../../services/cloudinary_service.dart'; //introduces cloudinary service for image upload

class PostDonationScreen extends StatefulWidget {
  const PostDonationScreen({super.key});

  @override
  State<PostDonationScreen> createState() => _PostDonationScreenState();
}
class _PostDonationScreenState extends State<PostDonationScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Food';
  File? _selectedImage;
  bool _isUploading = false;

  final List<String> _categories = ['Food', 'Clothes', 'Household', 'Other'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _postDonation() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add a photo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload image to Firebase Storage
      String? photoUrl = await uploadToCloudinary(_selectedImage!);
      if (photoUrl == null) {
        throw Exception('Image upload failed. Please try again.');
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('donations').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'location': 'Kampala, Uganda', // You can make this dynamic later
        'photoUrl': photoUrl,
        'donorId': FirebaseAuth.instance.currentUser!.uid,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });
