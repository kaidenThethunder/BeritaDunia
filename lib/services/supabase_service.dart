import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' hide OAuthProvider;
import 'dart:typed_data';
import 'dart:io';

class SupabaseService {
  // Supabase credentials dari user
  static const String supabaseUrl = 'https://ncgeyofndsksturzbfzw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jZ2V5b2ZuZHNrc3R1cnpiZnp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNDg3MjYsImV4cCI6MjA2NDcyNDcyNn0.Vuu12phmE6U8Y0L-4g46lvnRrdTnf3DOfScbss-DZCE';
  // Service role key for admin operations (use with caution)
  static const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jZ2V5b2ZuZHNrc3R1cnpiZnp3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTE0ODcyNiwiZXhwIjoyMDY0NzI0NzI2fQ.70WYj8uwYasgRRc3IqrylXNFEMgV9wsojhg9Mumwn-w';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      print('Supabase initialized successfully');
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow;
    }
  }
  
  /// Upload image to Supabase Storage (Public access)
  static Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      print('Starting image upload to Supabase: $fileName');
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create unique file path for public access
      final filePath = 'public_images/$fileName';
      
      // Upload to Supabase Storage bucket 'news-images'
      final response = await client.storage
          .from('news-images')
          .uploadBinary(filePath, bytes);
      
      print('Upload response: $response');
      
      // Get public URL for the uploaded file
      final publicUrl = client.storage
          .from('news-images')
          .getPublicUrl(filePath);
      
      print('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      return null;
    }
  }
  
  /// Upload video to Supabase Storage (Public access)
  static Future<String?> uploadVideo(File videoFile, String fileName) async {
    try {
      print('Starting video upload to Supabase: $fileName');
      
      // Read file as bytes
      final bytes = await videoFile.readAsBytes();
      
      // Create unique file path for public access
      final filePath = 'public_videos/$fileName';
      
      // Upload to Supabase Storage bucket 'news-images'
      final response = await client.storage
          .from('news-images')
          .uploadBinary(filePath, bytes);
      
      print('Upload response: $response');
      
      // Get public URL for the uploaded file
      final publicUrl = client.storage
          .from('news-images')
          .getPublicUrl(filePath);
      
      print('Video uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading video to Supabase: $e');
      return null;
    }
  }
  
  /// Upload file from bytes (for web compatibility) - Public access
  static Future<String?> uploadFromBytes(Uint8List bytes, String fileName, {bool isVideo = false}) async {
    try {
      print('Starting file upload from bytes to Supabase: $fileName');
      
      // Create unique file path for public access
      final folderName = isVideo ? 'public_videos' : 'public_images';
      final filePath = '$folderName/$fileName';
      
      // Upload to Supabase Storage bucket 'news-images'
      final response = await client.storage
          .from('news-images')
          .uploadBinary(filePath, bytes);
      
      print('Upload response: $response');
      
      // Get public URL for the uploaded file
      final publicUrl = client.storage
          .from('news-images')
          .getPublicUrl(filePath);
      
      print('File uploaded successfully from bytes: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading file from bytes to Supabase: $e');
      return null;
    }
  }
  
  /// Delete file from Supabase Storage
  static Future<bool> deleteFile(String filePath) async {
    try {
      print('Deleting file from Supabase: $filePath');
      
      final response = await client.storage
          .from('news-images')
          .remove([filePath]);
      
      if (response.isEmpty) {
        print('File deleted successfully: $filePath');
        return true;
      } else {
        print('Delete failed: $response');
        return false;
      }
    } catch (e) {
      print('Error deleting file from Supabase: $e');
      return false;
    }
  }
  
  /// Generate unique filename with timestamp
  static String generateFileName(String originalName, {String? userId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    final userPrefix = userId != null ? '${userId}_' : '';
    return '${userPrefix}${timestamp}.$extension';
  }

  /// Sign in to Supabase using Firebase user
  static Future<void> signInWithFirebaseUser() async {
    try {
      // Check if already authenticated with Supabase
      final currentSupabaseUser = client.auth.currentUser;
      if (currentSupabaseUser != null) {
        print('Already authenticated with Supabase: ${currentSupabaseUser.id}');
        return;
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Firebase user found: ${user.uid}');
        
        // Get Firebase ID token
         final idToken = await user.getIdToken(true); // Force refresh token
         print('Firebase ID token obtained');
         
         if (idToken == null) {
           throw Exception('Failed to get Firebase ID token');
         }
         
         // Sign in to Supabase using Firebase ID token
         final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
        
        if (response.user != null) {
          print('Successfully signed in to Supabase with Firebase token: ${response.user!.id}');
        } else {
          print('Failed to sign in to Supabase with Firebase token');
          throw Exception('Failed to authenticate with Supabase');
        }
      } else {
        print('No Firebase user found');
        throw Exception('No Firebase user found. Please sign in with Firebase first.');
      }
    } catch (e) {
      print('Error signing in to Supabase: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated in Supabase
  static bool get isAuthenticated {
    return client.auth.currentUser != null;
  }

  /// Get current Supabase user ID
  static String? get currentUserId {
    return client.auth.currentUser?.id;
  }

  /// Sign out from Supabase
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      print('Signed out from Supabase');
    } catch (e) {
      print('Error signing out from Supabase: $e');
    }
  }
}