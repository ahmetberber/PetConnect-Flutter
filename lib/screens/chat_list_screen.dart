import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petconnectflutter/screens/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return Center(child: Text("No Chats Found"));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];
              return StreamBuilder(
                stream: FirebaseFirestore.instance.collection('chats').doc(chat.id).collection('messages')
                    .orderBy('timestamp', descending: true).limit(1).snapshots(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData) return Center(child: CircularProgressIndicator());
                  var messages = messageSnapshot.data!.docs;
                  var lastMessage = messages.isNotEmpty ? messages.first : null;
                  var receiverId = chat['participants'].firstWhere((element) => element != FirebaseAuth.instance.currentUser!.uid);
                  var receiverNameFuture = FirebaseFirestore.instance.collection('users').doc(receiverId).get();
                  return FutureBuilder(
                    future: receiverNameFuture,
                    builder: (context, receiverSnapshot) {
                      if (!receiverSnapshot.hasData) return Center(child: CircularProgressIndicator());
                      var receiverName = receiverSnapshot.data?.data()?['name'] ?? "No Name";
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(
                              receiverName[0].toUpperCase() ?? "",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            receiverName ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessage != null ? (lastMessage['type'] == 'text' ? lastMessage['content'] : "Sent an Image") : "No Messages Yet",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.id)),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}