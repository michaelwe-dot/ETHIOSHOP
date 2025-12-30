import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailScreen({required this.listingId, super.key});

  Future<DocumentSnapshot> _loadDoc() => FirebaseFirestore.instance.collection('listings').doc(listingId).get();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Detail')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadDoc(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>;
          final photos = (data['photos'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (photos.isNotEmpty)
                SizedBox(
                  height: 280,
                  child: PageView(
                    children: photos.map((p) => Image.network(p, fit: BoxFit.cover)).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(data['title'] ?? 'No title', style: Theme.of(context).textTheme.headline6),
              const SizedBox(height: 8),
              Text('ETB ${data['price'] ?? '—'}', style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 12),
              Text(data['description'] ?? ''),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Message Seller'),
                onPressed: () {
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
