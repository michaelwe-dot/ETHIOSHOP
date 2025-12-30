import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ETHIO🛍 Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/market'),
            child: const Text('Marketplace'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/post_listing'),
            child: const Text('Post Listing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/messages'),
            child: const Text('Messages'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
