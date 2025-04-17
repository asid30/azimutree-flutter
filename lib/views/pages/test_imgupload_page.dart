import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TestImageUploadPage extends StatefulWidget {
  const TestImageUploadPage({super.key});

  @override
  State<TestImageUploadPage> createState() => _TestImageUploadPageState();
}

class _TestImageUploadPageState extends State<TestImageUploadPage> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _cameraImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_image != null)
          Image.file(
            _image!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          )
        else
          Stack(
            children: [
              Container(color: Colors.grey, height: 300),
              Positioned(top: 150, left: 120, child: Text("No image selected")),
            ],
          ),

        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pickImage();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1F4226),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload, color: Colors.white),
                  Text(" Upload", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cameraImage();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1F4226),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white),
                  Text(" Camera", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
