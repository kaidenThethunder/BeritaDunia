import 'package:firebase_auth/firebase_auth.dart';

class AdminUtils {
  // Daftar email admin yang diizinkan
  static const List<String> adminEmails = [
    'ricoadriannaibaho5@gmail.com',
    // Tambahkan email admin lainnya di sini jika diperlukan
  ];

  /// Mengecek apakah email tertentu adalah admin
  static bool isAdmin(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase().trim());
  }

  /// Mengecek apakah user yang sedang login adalah admin
  static bool isCurrentUserAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return isAdmin(user?.email);
  }

  /// Mendapatkan email user yang sedang login
  static String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  /// Mendapatkan UID user yang sedang login
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}