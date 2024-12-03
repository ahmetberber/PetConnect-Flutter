import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;

    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil güncellendi')),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profilim'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'İsim',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Profili Güncelle'),
            ),
            SizedBox(height: 20),
            Text(
              'Email: ${_user?.email ?? ''}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
