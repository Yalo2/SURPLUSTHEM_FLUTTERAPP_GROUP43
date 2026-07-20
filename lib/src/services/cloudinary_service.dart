import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> uploadToCloudinary(File imageFile) async {
  const cloudName = 'qzxfamih'; // replace with your actual Cloud Name
  const uploadPreset = 'MAD_GROUP43'; // replace with your actual preset name

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );
  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

