import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:io';

import 'package:petconnectflutter/screens/ad/detail.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic> chat = {};
  String receiverName = "";
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  String adTitle = "";
  bool _chatActive = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _scrollToBottom();
  }

  void _initChat() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final adDoc = await FirebaseFirestore.instance.collection('ads').doc(chatDoc['adId']).get();
    final receiverNameDoc = await FirebaseFirestore.instance.collection('users').doc(chatDoc['participants'].firstWhere((participant) => participant != FirebaseAuth.instance.currentUser!.uid)).get();
    setState(() {
      chat = chatDoc.data()!;
      _chatActive = adDoc.data()?['is_active'];
      adTitle = adDoc.data()?['title'] ?? "-";
      receiverName = receiverNameDoc.data()?['name'] ?? "-";
    });

    FirebaseFirestore.instance.collection('notifications').where('chatId', isEqualTo: widget.chatId).snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage(String content, String type) {
    final messagesRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages');

    messagesRef.add({
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': type,
    });

    _controller.clear();

    setState(() {
      _selectedImages.clear();
    });
    _scrollToBottom();
    _sendNotification(content, type);
  }

  Future<void> _sendNotification(String content, String type) async {
    final message = type == 'text' ? content : 'Görüntü';
    await FirebaseFirestore.instance.collection('notifications').add({
      'chatId': widget.chatId,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final jsonCredentials = await rootBundle.loadString('assets/service-account.json');
    final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
    final client = await auth.clientViaServiceAccount(creds, ['https://www.googleapis.com/auth/cloud-platform']);
    final notificationData = {
      'message': {
        'topic': chat['participants'].firstWhere((participant) => participant != FirebaseAuth.instance.currentUser!.uid),
        'notification': {
          'title': receiverName,
          'body': message
        },
        'data': {'chatId': widget.chatId },
      },
    };

    final response = await client.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/12814231115/messages:send'),
      headers: { 'content-type': 'application/json' },
      body: jsonEncode(notificationData),
    );

    client.close();
    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  Future<void> _sendImages() async {
    for (var image in _selectedImages) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      _sendMessage(downloadUrl, 'image');
    }
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
        leading: Icon(Icons.photo_library),
        title: Text('Galeriden Seç'),
        onTap: () async {
          Navigator.pop(context);
          final pickedFiles = await _picker.pickMultiImage();
          setState(() {
            _selectedImages = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
          });
        },
        ),
        ListTile(
        leading: Icon(Icons.camera_alt),
        title: Text('Kameradan Çek'),
        onTap: () async {
          Navigator.pop(context);
          final pickedFile = await _picker.pickImage(source: ImageSource.camera);
          if (pickedFile != null) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
          }
        },
        ),
      ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$receiverName - $adTitle'),
        actions: [
          if (_chatActive)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'details') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdDetailsScreen(adId: chat['adId'])));
                }
              },
              itemBuilder: (BuildContext context) {
                return {'İlan Detayına Git'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: 'details',
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10, left: isMe ? 80 : 10, right: isMe ? 10 : 80),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: message['type'] == 'text'
                            ? Text(
                                message['content'],
                                style: TextStyle(fontSize: 16),
                              )
                            : GestureDetector(
                                onTap: () => _showImageDialog(message['content']),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: CachedNetworkImage(
                                    imageUrl: message['content'],
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedImages.isNotEmpty)
            Container(
              height: 100,
              padding: EdgeInsets.all(8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (_chatActive)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.teal),
                      onPressed: _pickImages,
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Mesajınızı yazın...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.teal),
                      onPressed: () {
                        if (_selectedImages.isNotEmpty) {
                          _sendImages();
                        }
                        if (_controller.text.isNotEmpty) {
                          _sendMessage(_controller.text, 'text');
                        }
                      },
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