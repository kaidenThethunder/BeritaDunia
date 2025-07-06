import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/news_provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
import 'utils/constants.dart'; // Import AppConstants
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'screens/login_screen.dart'; // Import LoginScreen
import 'services/supabase_service.dart'; // Import SupabaseService

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter News App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF), // Warna biru yang lebih modern
            brightness: Brightness.light,
            primary: const Color(0xFF007AFF),
            secondary: const Color(0xFF5AC8FA),
            surface: Colors.white, // Warna permukaan untuk input fields, dll.
            surfaceVariant: Colors.grey[200], // Warna varian permukaan untuk chip non-aktif
            onPrimary: Colors.white, // Warna teks/ikon di atas warna primer
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily, // Menggunakan font Poppins dari google_fonts
          scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Latar belakang yang lebih cerah dan modern
          appBarTheme: AppBarTheme( // Menambahkan tema untuk AppBar
            backgroundColor: const Color(0xFFF8F9FA), // Warna AppBar sama dengan scaffold
            elevation: 0, // Menghilangkan bayangan AppBar
            iconTheme: const IconThemeData(color: Color(0xFF007AFF)), // Warna ikon AppBar
            titleTextStyle: GoogleFonts.poppins( // Gaya teks judul AppBar
              color: const Color(0xFF007AFF),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme( // Menambahkan tema untuk TextField
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.searchBarBorderRadius), // Menggunakan konstanta dari AppConstants
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.searchBarBorderRadius),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.searchBarBorderRadius),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
            ),
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
          chipTheme: ChipThemeData( // Menambahkan tema untuk Chip
            backgroundColor: Colors.grey[200], // Warna default chip
            selectedColor: const Color(0xFF007AFF), // Warna chip yang dipilih
            labelStyle: GoogleFonts.poppins(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            secondaryLabelStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), // Untuk teks chip yang dipilih
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.chipBorderRadius), // Menggunakan konstanta dari AppConstants
              side: BorderSide(color: Colors.grey[300]!) // Sisi default chip
            ),
          ),
          cardTheme: CardTheme(
            elevation: 4, // Sedikit menaikkan elevasi kartu
            shadowColor: Colors.black.withOpacity(0.1), // Bayangan yang lebih halus
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), // Margin default kartu
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius), // Menggunakan konstanta dari AppConstants
            )
          ),
          textTheme: TextTheme( // Menyesuaikan beberapa gaya teks global
            headlineSmall: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF1D1D1F)),
            titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1D1D1F)),
            titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1D1D1F)),
            bodyLarge: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.5),
            bodyMedium: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, height: 1.4),
            labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), // Untuk tombol
          ),
          elevatedButtonTheme: ElevatedButtonThemeData( // Tema untuk ElevatedButton
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius), // Menggunakan konstanta dari AppConstants
              ),
            ),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
