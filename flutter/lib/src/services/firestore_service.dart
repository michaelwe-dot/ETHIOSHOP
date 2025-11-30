import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference get listingsRef => _db.collection('listings');

  Stream<QuerySnapshot> listingsStream({int limit = 20, DocumentSnapshot? startAfter}) {
    var query = listingsRef.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.snapshots();
  }

  Future<DocumentReference> createListingDraft(Map<String, dynamic> data) async {
    final docRef = listingsRef.doc();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef;
  }

  Future<String> _uploadFile(File file, String path, {bool makePublic = true}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<File> compressFile(File file, {int quality = 70}) async {
    final targetPath = '${file.parent.path}/${_uuid.v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
    );
    return result ?? file;
  }

  Future<void> uploadListingImagesAndSave({
    required String listingId,
    required List<File> images,
    required Map<String, dynamic> listingData,
    required void Function(int, int) onProgress,
  }) async {
    final paths = <String>[];
    int uploaded = 0;
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      final compressed = await compressFile(img, quality: 75);
      final path = 'listings/$listingId/${_uuid.v4()}.jpg';
      final url = await _uploadFile(compressed, path);
      paths.add(url);
      uploaded++;
      onProgress(uploaded, images.length);
    }

    final docRef = listingsRef.doc(listingId);
    listingData['photos'] = paths;
    listingData['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(listingData, SetOptions(merge: true));
  }
}
