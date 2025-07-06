import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Diganti dengan Supabase
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../utils/constants.dart';
import '../providers/news_provider.dart';
import '../services/supabase_service.dart'; // Import Supabase Service

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  
  XFile? _selectedImage;
  XFile? _selectedVideo;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Set default author name from current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      _authorController.text = user.displayName!;
    }
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
          _selectedVideo = null; // Clear video if image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
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
          _selectedImage = null; // Clear image if video is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadFile(XFile file, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: User not authenticated');
        return null;
      }

      print('Starting upload for file: ${file.name} to Supabase Storage');
      
      // Generate unique filename with user ID
      final fileName = SupabaseService.generateFileName(file.name, userId: user.uid);
      
      print('Upload path: $folder/$fileName');
      
      String? downloadUrl;
      
      if (kIsWeb) {
        // For web, use bytes upload
        final bytes = await file.readAsBytes();
        print('File size: ${bytes.length} bytes');
        
        // Determine if it's a video file
        final isVideo = folder.contains('video') || _isVideoFile(file.name);
        
        downloadUrl = await SupabaseService.uploadFromBytes(
          bytes, 
          fileName, 
          isVideo: isVideo
        );
      } else {
        // For mobile platforms, use file upload
        final fileObj = File(file.path);
        if (!await fileObj.exists()) {
          print('Error: File does not exist at path: ${file.path}');
          return null;
        }
        print('File size: ${await fileObj.length()} bytes');
        
        if (folder.contains('video') || _isVideoFile(file.name)) {
          downloadUrl = await SupabaseService.uploadVideo(fileObj, fileName);
        } else {
          downloadUrl = await SupabaseService.uploadImage(fileObj, fileName);
        }
      }
      
      if (downloadUrl != null) {
        print('Upload successful to Supabase. Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload gagal ke Supabase Storage');
      }
    } catch (e) {
      print('Supabase Storage Error: $e');
      
      String errorMessage;
      if (e.toString().contains('object-not-found')) {
        errorMessage = 'File tidak ditemukan di server. Silakan coba upload ulang.';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'Tidak memiliki izin untuk mengakses storage. Silakan login ulang.';
      } else if (e.toString().contains('canceled')) {
        errorMessage = 'Upload dibatalkan. Silakan coba lagi.';
      } else {
        errorMessage = 'Upload gagal: ${e.toString()}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }
  
  bool _isVideoFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create news'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      String? videoUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        print('Uploading image...');
        
        // Validasi file sebelum upload
        try {
          final bytes = await _selectedImage!.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('File gambar kosong atau rusak.');
          }
          
          // Cek ukuran file (maksimal 10MB)
          if (bytes.length > 10 * 1024 * 1024) {
            throw Exception('Ukuran file gambar terlalu besar. Maksimal 10MB.');
          }
          
          imageUrl = await _uploadFile(_selectedImage!, 'user_images');
          if (imageUrl == null) {
            throw Exception('Gagal upload gambar. Silakan coba lagi.');
          }
          print('Image uploaded successfully: $imageUrl');
        } catch (e) {
          print('Error validating/uploading image: $e');
          throw Exception('Error upload gambar: ${e.toString()}');
        }
      }

      // Upload video if selected
      if (_selectedVideo != null) {
        print('Uploading video...');
        
        // Validasi file sebelum upload
        try {
          final bytes = await _selectedVideo!.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('File video kosong atau rusak.');
          }
          
          // Cek ukuran file (maksimal 50MB)
          if (bytes.length > 50 * 1024 * 1024) {
            throw Exception('Ukuran file video terlalu besar. Maksimal 50MB.');
          }
          
          videoUrl = await _uploadFile(_selectedVideo!, 'user_news_videos');
          if (videoUrl == null) {
            throw Exception('Gagal upload video. Silakan coba lagi.');
          }
          print('Video uploaded successfully: $videoUrl');
        } catch (e) {
          print('Error validating/uploading video: $e');
          throw Exception('Error upload video: ${e.toString()}');
        }
      }

      // Create news document
      final newsData = {
        'title': _titleController.text.trim(),
        'description': _contentController.text.trim().substring(0, 
            _contentController.text.trim().length > 100 ? 100 : _contentController.text.trim().length),
        'content': _contentController.text.trim(),
        'author': _authorController.text.trim(),
        'source': {'name': 'User Generated'},
        'userEmail': user.email,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'publishedAt': FieldValue.serverTimestamp(),
        'isUserGenerated': true,
        'isApproved': false, // Default false, needs admin approval
        'category': _selectedCategory?.toLowerCase(),
      };

      if (imageUrl != null) {
        newsData['urlToImage'] = imageUrl;
      }

      if (videoUrl != null) {
        newsData['videoUrl'] = videoUrl;
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('user_articles').add(newsData);

      if (mounted) {
        // Refresh user-generated news in NewsProvider
        final newsProvider = Provider.of<NewsProvider>(context, listen: false);
        await newsProvider.fetchUserGeneratedNews();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel berhasil dibuat dan menunggu persetujuan admin!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating news: ${e.toString()}'),
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
        title: const Text('Tambah Berita'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _submitNews,
              child: const Text(
                'PUBLISH',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
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
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Berita *',
                        hintText: 'Masukkan judul berita yang menarik',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul berita harus diisi';
                        }
                        if (value.trim().length < 10) {
                          return 'Judul berita minimal 10 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Author Field
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Penulis *',
                        hintText: 'Masukkan nama penulis',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama penulis harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Field
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Berita *',
                        hintText: 'Pilih kategori berita',
                        border: OutlineInputBorder(),
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
                          return 'Kategori berita harus dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content Field
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Isi Berita *',
                        hintText: 'Tulis isi berita secara lengkap dan informatif',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Isi berita harus diisi';
                        }
                        if (value.trim().length < 50) {
                          return 'Isi berita minimal 50 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Media Section
                    const Text(
                      'Media (Opsional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih gambar atau video untuk melengkapi berita Anda',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih Gambar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickVideo,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Pilih Video'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selected Media Preview
                    if (_selectedImage != null) ...
                      [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future: _selectedImage!.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            );
                                          } else {
                                            return Container(
                                              width: double.infinity,
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : FutureBuilder<Uint8List>(
                                        future: _selectedImage!.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            );
                                          } else {
                                            return Container(
                                              width: double.infinity,
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gambar dipilih',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],

                    if (_selectedVideo != null) ...
                      [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_file, size: 40, color: Colors.grey),
                                    Text('Video dipilih', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _selectedVideo = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Video dipilih',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitNews,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'PUBLISH BERITA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Info Text
                    const Text(
                      'Dengan mempublikasikan berita, Anda menyetujui bahwa konten yang dibuat adalah original dan tidak melanggar hak cipta.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}