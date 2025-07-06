import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/video_article.dart'; // Added for video articles
import '../services/news_service.dart';
import '../services/youtube_service.dart'; // Added for YouTube service
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for user-generated news

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  int _currentPage = 1;
  String? _selectedCategory;
  String? _searchQuery;
  String? _country = 'id'; // Default ke Indonesia

  // State for Video News
  final YoutubeService _youtubeService = YoutubeService();
  List<VideoArticle> _videoArticles = [];
  bool _isVideoLoading = true;
  int _currentVideoPage = 1; // Assuming YouTube API might support pagination or we might implement it differently

  // State for User-Generated News
  List<Article> _userGeneratedNews = [];
  bool _isUserNewsLoading = true;
  
  // State for Pending Articles (Admin)
  List<Article> _pendingArticles = [];
  bool _isPendingLoading = true;

  // Getters
  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  String get country => _country ?? 'id';

  // Getters for Video News
  List<VideoArticle> get videoArticles => _videoArticles;
  bool get isVideoLoading => _isVideoLoading;

  // Getters for User-Generated News
  List<Article> get userGeneratedNews => _userGeneratedNews;
  bool get isUserNewsLoading => _isUserNewsLoading;
  
  // Getters for Pending Articles
  List<Article> get pendingArticles => _pendingArticles;
  bool get isPendingLoading => _isPendingLoading;
  
  // Combined articles (API + User-generated approved only)
  List<Article> get allArticles {
    final approvedUserNews = _userGeneratedNews.where((article) => article.isApproved).toList();
    final combined = [..._articles, ...approvedUserNews];
    // Sort by published date, newest first
    combined.sort((a, b) {
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return combined;
  }
  
  // Get articles by category
  List<Article> getArticlesByCategory(String category) {
    final allArticlesList = allArticles;
    if (category.toLowerCase() == 'home' || category.isEmpty) {
      return allArticlesList;
    }
    
    // Since Article model doesn't have category field,
    // we'll filter based on the current selected category
    // or return all articles for now
    if (_selectedCategory?.toLowerCase() == category.toLowerCase()) {
      return allArticlesList;
    }
    
    // For now, return all articles since we don't have category filtering
    // In a real app, you might want to add category field to Article model
    return allArticlesList;
  }
  
  // Only approved user-generated articles
  List<Article> get userGeneratedArticles {
    return _userGeneratedNews.where((article) => article.isApproved).toList();
  }
  
  // Setter untuk kategori
  void setCategory(String? category) {
    _selectedCategory = category;
    _currentPage = 1; // Reset halaman saat mengubah kategori
    notifyListeners();
    fetchNews(resetPage: true);
    fetchVideoNews(resetPage: true); // Also fetch video news
    fetchUserGeneratedNews(); // Also fetch user-generated news
  }
  
  // Setter untuk pencarian
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _currentPage = 1; // Reset halaman saat melakukan pencarian baru
    notifyListeners();
    fetchNews(resetPage: true);
    fetchVideoNews(resetPage: true); // Also fetch video news
    fetchUserGeneratedNews(); // Also fetch user-generated news
  }
  
  // Setter untuk negara
  void setCountry(String? country) {
    _country = country;
    notifyListeners();
    fetchNews(resetPage: true);
    fetchVideoNews(resetPage: true); // Also fetch video news
    fetchUserGeneratedNews(); // Also fetch user-generated news
  }

  // Fungsi untuk mengambil berita
  Future<void> fetchNews({bool resetPage = false}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (resetPage) _currentPage = 1;
      
      print('NewsProvider: Memulai pengambilan berita');
      print('NewsProvider: Kategori: $_selectedCategory, Query: $_searchQuery, Negara: $_country, Halaman: $_currentPage');
      
      final articles = await _newsService.getTopHeadlines(
        query: _searchQuery,
        category: _selectedCategory,
        country: _country,
        page: _currentPage
      );
      
      if (articles.isEmpty) {
        print('NewsProvider: Tidak ada artikel yang ditemukan');
      } else {
        print('NewsProvider: Berhasil mendapatkan ${articles.length} artikel');
      }
      
      _articles = resetPage ? articles : [..._articles, ...articles];
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('NewsProvider: Error saat mengambil berita: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fungsi untuk memuat lebih banyak berita (pagination)
  Future<void> loadMoreNews() async {
    if (!_isLoading) {
      await fetchNews();
    }
  }
  
  // Fungsi untuk mengambil berita user-generated dari Firestore
  Future<void> fetchUserGeneratedNews({String? searchQuery}) async {
    _isUserNewsLoading = true;
    notifyListeners();
    
    try {
      print('NewsProvider: Memulai pengambilan berita user-generated');
      
      // Buat query dasar
      Query query = FirebaseFirestore.instance.collection('user_articles')
          .where('isApproved', isEqualTo: true); // Only approved articles
      
      // Tambahkan filter kategori jika ada
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        // Asumsikan kategori disimpan dalam field 'category' di Firestore
        // Jika struktur berbeda, sesuaikan query ini
        query = query.where('category', isEqualTo: _selectedCategory!.toLowerCase());
      }
      
      // Tambahkan filter pencarian jika ada
      // Note: Firestore tidak mendukung full-text search secara native
      // Untuk pencarian yang lebih baik, pertimbangkan menggunakan Algolia atau solusi lain
      // Ini hanya implementasi sederhana
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        print('NewsProvider: Tidak ada berita user-generated yang ditemukan');
        _userGeneratedNews = [];
      } else {
        print('NewsProvider: Berhasil mendapatkan ${snapshot.docs.length} berita user-generated');
        
        _userGeneratedNews = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['documentId'] = doc.id;
          return Article.fromJson(data);
        }).toList();
        
        // Sort by publishedAt on client side
        _userGeneratedNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        
        // Apply search filter if provided
         final queryToUse = searchQuery ?? _searchQuery;
         if (queryToUse != null && queryToUse.isNotEmpty) {
           _userGeneratedNews = _userGeneratedNews.where((article) {
             return article.title.toLowerCase().contains(queryToUse.toLowerCase()) ||
                    (article.content?.toLowerCase().contains(queryToUse.toLowerCase()) ?? false) ||
                    (article.author?.toLowerCase().contains(queryToUse.toLowerCase()) ?? false);
           }).toList();
         }
      }
      
      _isUserNewsLoading = false;
      notifyListeners();
    } catch (e) {
      print('NewsProvider: Error saat mengambil berita user-generated: $e');
      _userGeneratedNews = [];
      _isUserNewsLoading = false;
      notifyListeners();
    }
  }
  
  // Fungsi untuk mengambil artikel pending (untuk admin)
  Future<void> loadPendingArticles() async {
    _isPendingLoading = true;
    notifyListeners();
    
    try {
      print('🔍 NewsProvider: Memulai pengambilan artikel pending');
      
      // First, let's check all documents in user_articles collection
      final allDocsSnapshot = await FirebaseFirestore.instance
           .collection('user_articles')
           .get();
      
      print('📊 NewsProvider: Total dokumen di user_articles: ${allDocsSnapshot.docs.length}');
      
      // Log all documents to see their isApproved status
      for (var doc in allDocsSnapshot.docs) {
        final data = doc.data();
        print('📄 Dokumen ${doc.id}: title="${data['title']}", isApproved=${data['isApproved']}, type=${data['isApproved'].runtimeType}');
      }
      
      // Now get only pending articles
      final querySnapshot = await FirebaseFirestore.instance
           .collection('user_articles')
           .where('isApproved', isEqualTo: false)
           .get();
       
       print('📊 NewsProvider: Ditemukan ${querySnapshot.docs.length} dokumen pending');
       
       _pendingArticles = querySnapshot.docs.map((doc) {
         final data = doc.data();
         data['documentId'] = doc.id;
         print('📄 Artikel pending: ${data['title']} - isApproved: ${data['isApproved']}');
         return Article.fromJson(data);
       }).toList();
      
      print('✅ NewsProvider: Berhasil mendapatkan ${_pendingArticles.length} artikel pending');
      
    } catch (e, stackTrace) {
      print('❌ NewsProvider: Error saat mengambil artikel pending: $e');
      print('❌ Stack trace: $stackTrace');
      _pendingArticles = [];
    } finally {
      _isPendingLoading = false;
      notifyListeners();
    }
  }

  // Method untuk approve artikel
  Future<void> approveArticle(String documentId, String adminId) async {
    try {
      // Update status di user_articles collection
      await FirebaseFirestore.instance
          .collection('user_articles')
          .doc(documentId)
          .update({
        'isApproved': true,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Refresh pending articles
      await loadPendingArticles();
      
      // Refresh user generated news to show approved articles
      await fetchUserGeneratedNews();
      
      print('NewsProvider: Artikel berhasil disetujui');
    } catch (e) {
      print('NewsProvider: Error saat menyetujui artikel: $e');
      throw e;
    }
  }

  // Method untuk reject artikel
  Future<void> rejectArticle(String documentId) async {
    try {
      // Delete artikel dari user_articles collection
      await FirebaseFirestore.instance
          .collection('user_articles')
          .doc(documentId)
          .delete();

      // Refresh pending articles
      await loadPendingArticles();
      
      print('NewsProvider: Artikel berhasil ditolak dan dihapus');
    } catch (e) {
      print('NewsProvider: Error saat menolak artikel: $e');
      throw e;
    }
  }
  
  // Fungsi untuk me-refresh semua berita
  Future<void> refreshAllNews() async {
    await Future.wait([
      fetchNews(resetPage: true),
      fetchVideoNews(resetPage: true),
      fetchUserGeneratedNews(),
    ]);
  }
  
  // Fungsi untuk refresh berita
  Future<void> refreshNews() async {
    await fetchNews(resetPage: true);
    await fetchVideoNews(resetPage: true); // Also refresh video news
  }



  // Fungsi untuk mengambil berita video
  Future<void> fetchVideoNews({bool resetPage = false}) async {
    _isVideoLoading = true;
    notifyListeners();

    try {
      if (resetPage) _currentVideoPage = 1; // Reset page if needed

      print('NewsProvider: Memulai pengambilan berita video');
      print('NewsProvider: Kategori Video: $_selectedCategory, Query Video: $_searchQuery, Negara: $_country');

      // For YouTube, country might be handled by regionCode. Max results can be set.
      final videos = await _youtubeService.fetchVideoNews(
        query: _searchQuery,
        category: _selectedCategory,
        countryCode: _country ?? 'id', // Pass country code
        maxResults: 10 // Fetch 10 videos for now
      );

      if (videos.isEmpty) {
        print('NewsProvider: Tidak ada video berita yang ditemukan');
      } else {
        print('NewsProvider: Berhasil mendapatkan ${videos.length} video berita');
      }

      _videoArticles = resetPage ? videos : [..._videoArticles, ...videos];
      // _currentVideoPage++; // Increment if implementing pagination for videos
      _isVideoLoading = false;
      notifyListeners();
    } catch (e) {
      print('NewsProvider: Error saat mengambil berita video: $e');
      _isVideoLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk memuat lebih banyak berita video (jika diimplementasikan)
  Future<void> loadMoreVideoNews() async {
    if (!_isVideoLoading) {
      // await fetchVideoNews(); // Implement if YouTube API supports easy pagination for this use case
      print('NewsProvider: Load more video news - not fully implemented for YouTube pagination yet.');
    }
  }
}