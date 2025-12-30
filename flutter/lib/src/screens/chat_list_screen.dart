import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_thread_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  final ChatService _chat = ChatService();
  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in to view messages')));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chat.streamThreadsForUser(uid),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No conversations'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final last = data['lastMessage'] ?? '';
              final participants = (data['participants'] as List).cast<String>();
              final title = data['title']?.toString() ?? participants.join(', ');
              return ListTile(
                title: Text(title),
                subtitle: Text(last),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(threadId: d.id))),
              );
            },
          );
        },
      ),
    );
  }
}
