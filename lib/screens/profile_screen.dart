import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _selectedImage;
  String? _profilePictureUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _profilePictureUrl = userData.containsKey('profilePicture') ? userData['profilePicture'] : '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        };

        if (_selectedImage != null) {
          Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child('${user.uid}.png');
          await storageRef.putFile(_selectedImage!);
          String downloadUrl = await storageRef.getDownloadURL();
          updateData['profilePicture'] = downloadUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil güncelleme başarısız: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil Güncelleme"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : _profilePictureUrl != ''
                            ? NetworkImage(_profilePictureUrl!) as ImageProvider
                            : AssetImage("assets/placeholder.png"),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Ad Soyad"),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "E-posta"),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: "Telefon Numarası"),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: "Adres"),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                    onPressed: _updateUserProfile,
                    child: Text("Profili Güncelle"),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: Text("Çıkış Yap"),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.transparent,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}