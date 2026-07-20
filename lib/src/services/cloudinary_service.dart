import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> uploadToCloudinary(File imageFile) async {
  const cloudName = 'qzxfamih'; // replace with your actual Cloud Name
  const uploadPreset = 'MAD_GROUP43'; // replace with your actual preset name
