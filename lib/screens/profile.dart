import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    final pickedImage = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
      return SafeArea(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Galeriden Seç'),
          onTap: () async {
            Navigator.pop(context, await ImagePicker().pickImage(source: ImageSource.gallery));
          },
          ),
          ListTile(
          leading: Icon(Icons.camera_alt),
          title: Text('Kamerayı Kullan'),
          onTap: () async {
            Navigator.pop(context, await ImagePicker().pickImage(source: ImageSource.camera));
          },
          ),
        ],
        ),
      );
      },
    );
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
        title: Text("Profil"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                  radius: 90,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover, width: 180, height: 180)
                      : (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: _profilePictureUrl!,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                          fit: BoxFit.cover,
                          width: 180,
                          height: 180,
                        )
                        : Image.asset('assets/placeholder.png', fit: BoxFit.cover, width: 180, height: 180)),
                  ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Ad Soyad",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "E-posta",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: "Telefon Numarası",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: "Adres",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _updateUserProfile,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Profili Güncelle"),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    FirebaseMessaging messaging = FirebaseMessaging.instance;
                    await messaging.unsubscribeFromTopic(_auth.currentUser!.uid);
                    await FirebaseAuth.instance.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Çıkış Yap"),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Profil güncelleniyor...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}