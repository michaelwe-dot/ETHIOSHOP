import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});
  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _fs = FirestoreService();
  final _picker = ImagePicker();

  List<File> _images = [];
  bool _uploading = false;
  double _progress = 0.0;

  int _step = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picks = await _picker.pickMultiImage(imageQuality: 85);
    if (picks != null) {
      setState(() {
        _images = picks.map((p) => File(p.path)).toList();
      });
    }
  }

  Future<void> _takePhoto() async {
    final pick = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (pick != null) {
      setState(() {
        _images.add(File(pick.path));
      });
    }
  }

  void _nextStep() => setState(() => _step = (_step + 1).clamp(0, 2));
  void _prevStep() => setState(() => _step = (_step - 1).clamp(0, 2));

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    final title = _titleController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final desc = _descController.text.trim();

    if (title.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and at least 1 photo required')));
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    final listingId = FirebaseFirestore.instance.collection('listings').doc().id;

    final listingData = {
      'title': title,
      'price': price,
      'description': desc,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'location': {'city': 'Addis Ababa'},
    };

    try {
      await _fs.uploadListingImagesAndSave(
        listingId: listingId,
        images: _images,
        listingData: listingData,
        onProgress: (uploaded, total) {
          setState(() => _progress = uploaded / total);
        },
      );
      setState(() {
        _uploading = false;
        _progress = 1.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing published')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Widget _buildStepImages() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var f in _images)
              Stack(children: [
                Image.file(f, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _images.remove(f));
                    },
                    child: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 14)),
                  ),
                ),
              ]),
            GestureDetector(
              onTap: _pickImages,
              child: Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.photo_library)),
            ),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.camera_alt)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 8),
        TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (ETB)')),
        const SizedBox(height: 8),
        TextField(controller: _descController, maxLines: 5, decoration: const InputDecoration(labelText: 'Description')),
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title: ${_titleController.text}'),
        const SizedBox(height: 8),
        Text('Price: ${_priceController.text}'),
        const SizedBox(height: 8),
        Text('Photos: ${_images.length}'),
        const SizedBox(height: 16),
        if (_uploading)
          Column(children: [
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).round()}% uploaded'),
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      Column(children: [_buildStepImages()]),
      Column(children: [_buildStepDetails()]),
      Column(children: [_buildStepReview()]),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Post Listing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          StepperIndicator(current: _step, total: steps.length),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: steps[_step])),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_step > 0) ElevatedButton(onPressed: _prevStep, child: const Text('Back')),
              if (_step < steps.length - 1)
                ElevatedButton(onPressed: _nextStep, child: const Text('Next'))
              else
                ElevatedButton(onPressed: _uploading ? null : _publish, child: const Text('Publish')),
            ],
          ),
        ]),
      ),
    );
  }
}

class StepperIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepperIndicator({required this.current, required this.total, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(color: active ? Colors.green : Colors.grey[300], borderRadius: BorderRadius.circular(4)),
          ),
        );
      }),
    );
  }
}
