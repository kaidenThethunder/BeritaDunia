import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../utils/constants.dart';
import '../providers/news_provider.dart';
import '../services/supabase_service.dart';
import '../models/article.dart';

class EditNewsScreen extends StatefulWidget {
  final Article article;
  
  const EditNewsScreen({super.key, required this.article});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _authorController;
  
  XFile? _selectedImage;
  XFile? _selectedVideo;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _selectedCategory;
  String? _currentImageUrl;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing article data
    _titleController = TextEditingController(text: widget.article.title);
    _contentController = TextEditingController(text: widget.article.content);
    _authorController = TextEditingController(text: widget.article.author ?? '');
    _currentImageUrl = widget.article.urlToImage;
    _currentVideoUrl = widget.article.videoUrl;
    // Set category if available
    // _selectedCategory = widget.article.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        setState(() {
          _selectedVideo = video;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateNews() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to update news'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is the creator
    if (widget.article.userId != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak memiliki izin untuk mengedit artikel ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _currentImageUrl;
      String? videoUrl = _currentVideoUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';
        if (kIsWeb) {
          final bytes = await _selectedImage!.readAsBytes();
          imageUrl = await SupabaseService.uploadFromBytes(
            bytes,
            fileName,
            isVideo: false,
          );
        } else {
          final file = File(_selectedImage!.path);
          imageUrl = await SupabaseService.uploadImage(file, fileName);
        }
      }

      // Upload new video if selected
      if (_selectedVideo != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedVideo!.name}';
        if (kIsWeb) {
          final bytes = await _selectedVideo!.readAsBytes();
          videoUrl = await SupabaseService.uploadFromBytes(
            bytes,
            fileName,
            isVideo: true,
          );
        } else {
          final file = File(_selectedVideo!.path);
          videoUrl = await SupabaseService.uploadVideo(file, fileName);
        }
      }

      // Update article data
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _contentController.text.trim().substring(0, 
            _contentController.text.trim().length > 100 ? 100 : _contentController.text.trim().length),
        'content': _contentController.text.trim(),
        'author': _authorController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'category': _selectedCategory?.toLowerCase(),
      };

      if (imageUrl != null) {
        updateData['urlToImage'] = imageUrl;
      }

      if (videoUrl != null) {
        updateData['videoUrl'] = videoUrl;
      }

      // Update in Firestore
      if (widget.article.documentId != null) {
        await FirebaseFirestore.instance
            .collection('user_articles')
            .doc(widget.article.documentId!)
            .update(updateData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Artikel'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Artikel',
                        hintText: 'Masukkan judul artikel...',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul artikel tidak boleh kosong';
                        }
                        if (value.trim().length < 10) {
                          return 'Judul artikel minimal 10 karakter';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Author field
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Penulis',
                        hintText: 'Masukkan nama penulis...',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama penulis tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConstants.categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Silakan pilih kategori';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content field
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Konten Artikel',
                        hintText: 'Tulis konten artikel di sini...',
                        prefixIcon: Icon(Icons.article),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Konten artikel tidak boleh kosong';
                        }
                        if (value.trim().length < 50) {
                          return 'Konten artikel minimal 50 karakter';
                        }
                        return null;
                      },
                      maxLines: 10,
                      minLines: 5,
                    ),
                    const SizedBox(height: 24),

                    // Current image display
                    if (_currentImageUrl != null && _selectedImage == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gambar Saat Ini:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, size: 50),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Image picker
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(_selectedImage != null 
                            ? 'Gambar baru dipilih' 
                            : 'Pilih Gambar Baru (Opsional)'),
                        subtitle: _selectedImage != null 
                            ? Text('File: ${_selectedImage!.name}')
                            : const Text('Tap untuk memilih gambar'),
                        trailing: _selectedImage != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _pickImage,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Video picker
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.videocam),
                        title: Text(_selectedVideo != null 
                            ? 'Video baru dipilih' 
                            : 'Pilih Video Baru (Opsional)'),
                        subtitle: _selectedVideo != null 
                            ? Text('File: ${_selectedVideo!.name}')
                            : _currentVideoUrl != null
                                ? const Text('Video sudah ada')
                                : const Text('Tap untuk memilih video'),
                        trailing: _selectedVideo != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedVideo = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _pickVideo,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Update button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateNews,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Perbarui Artikel',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}