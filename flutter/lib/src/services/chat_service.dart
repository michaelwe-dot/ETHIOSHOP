import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();

  CollectionReference get threadsRef => _db.collection('threads');

  Future<String> getOrCreateThread(List<String> participants, {String? title}) async {
    final q = await threadsRef
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.id;
    final doc = await threadsRef.add({
      'participants': participants,
      'title': title ?? '',
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<QuerySnapshot> streamThreadsForUser(String uid) {
    return threadsRef.where('participants', arrayContains: uid).orderBy('lastUpdated', descending: true).snapshots();
  }

  Stream<QuerySnapshot> streamMessages(String threadId, {int limit = 100}) {
    return threadsRef.doc(threadId).collection('messages').orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  Future<void> sendMessage({
    required String threadId,
    required String from,
    String? text,
    List<File>? attachments,
  }) async {
    final messagesRef = threadsRef.doc(threadId).collection('messages');
    final msgDoc = messagesRef.doc();
    final createdAt = FieldValue.serverTimestamp();

    List<String> attachmentUrls = [];
    if (attachments != null && attachments.isNotEmpty) {
      for (var file in attachments) {
        final path = 'threads/$threadId/${_uuid.v4()}.jpg';
        final ref = _storage.ref().child(path);
        final task = await ref.putFile(file);
        final url = await task.ref.getDownloadURL();
        attachmentUrls.add(url);
      }
    }

    await msgDoc.set({
      'id': msgDoc.id,
      'from': from,
      'text': text ?? '',
      'attachments': attachmentUrls,
      'createdAt': createdAt,
      'readBy': [from],
    });

    await threadsRef.doc(threadId).set({
      'lastMessage': text ?? (attachmentUrls.isNotEmpty ? '📷 Image' : ''),
      'lastUpdated': createdAt,
    }, SetOptions(merge: true));
  }
}
