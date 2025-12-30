import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ChatThreadScreen extends StatefulWidget {
  final String threadId;
  const ChatThreadScreen({required this.threadId, super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ChatService _chat = ChatService();
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;

  Future<void> _send({List<File>? attachments}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = _controller.text.trim();
    if ((text.isEmpty) && (attachments == null || attachments.isEmpty)) return;
    setState(() => _sending = true);
    try {
      await _chat.sendMessage(threadId: widget.threadId, from: uid, text: text.isEmpty ? null : text, attachments: attachments);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _pickImageAndSend() async {
    final pick = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pick == null) return;
    final file = File(pick.path);
    await _send(attachments: [file]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chat.streamMessages(widget.threadId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No messages'));
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final isMe = data['from'] == FirebaseAuth.instance.currentUser?.uid;
                    final text = data['text'] ?? '';
                    final attachments = (data['attachments'] ?? []) as List;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Card(
                          color: isMe ? Colors.green[100] : Colors.grey[200],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (text.isNotEmpty) Text(text),
                              for (var a in attachments) Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(a, height: 160, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 4),
                              Text((data['createdAt'] as Timestamp?)?.toDate().toLocal().toString() ?? '', style: const TextStyle(fontSize: 10)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(onPressed: _pickImageAndSend, icon: const Icon(Icons.photo)),
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type a message'))),
                IconButton(
                  onPressed: _sending ? null : () => _send(),
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
