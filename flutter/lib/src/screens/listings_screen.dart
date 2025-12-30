import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'listing_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});
  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs.listingsStream(limit: 30),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No listings yet'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final price = data['price'] != null ? data['price'].toString() : '—';
              final photos = (data['photos'] as List?) ?? [];
              final thumb = photos.isNotEmpty ? photos[0] : null;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: thumb != null
                      ? Image.network(thumb, width: 64, height: 64, fit: BoxFit.cover)
                      : Container(width: 64, height: 64, color: Colors.grey[300]),
                  title: Text(title),
                  subtitle: Text('ETB $price'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: doc.id)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/post_listing'),
      ),
    );
  }
}
