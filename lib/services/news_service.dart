import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../utils/constants.dart';

class NewsService {
  // Menggunakan konstanta dari AppConstants
  final String _apiKey = AppConstants.apiKey;
  final String _baseUrl = AppConstants.baseUrl;
  
  // Kategori berita diambil dari AppConstants
  static List<String> get categories => AppConstants.categories;

  Future<List<Article>> getTopHeadlines({
    String? query,
    String? category,
    String? country,
    int page = 1,
    int pageSize = 20
  }) async {
    try {
      // Log parameter yang digunakan untuk debugging
      print('Fetching news with parameters (simplified for debugging):');
      // print('- Query: $query'); // Temporarily removed for broader search
      // print('- Category: $category'); // Temporarily removed for broader search
      print('- Country: ${country ?? 'id'}');
      print('- Page: $page');
      print('- PageSize: $pageSize');
      
      final params = {
        'apiKey': _apiKey,
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
        if (country != null && country.isNotEmpty) 'country': country,
        'page': page.toString(),
        'pageSize': pageSize.toString()
      };

      // Jika tidak ada query dan kategori, default ke 'general' untuk kategori
      // dan negara default dari provider (atau 'id' jika null)
      // Ini untuk memastikan parameter wajib 'category' atau 'q' atau 'country' terpenuhi jika API mengharuskannya
      // Namun, NewsAPI biasanya lebih fleksibel. Cek dokumentasi API jika ada error.
      if ((query == null || query.isEmpty) && (category == null || category.isEmpty)) {
        // Jika tidak ada query atau kategori spesifik, dan API memerlukan salah satunya,
        // Anda mungkin ingin default ke 'general' atau menghapus parameter 'category' sama sekali
        // tergantung pada bagaimana API menangani permintaan tanpa q atau kategori.
        // Untuk NewsAPI, top-headlines memerlukan 'country' atau 'category' atau 'q'.
        // Jika 'country' sudah ada, itu cukup.
        // Jika 'country' tidak ada, dan 'q' serta 'category' juga tidak ada, maka API akan error.
        // Logika di NewsProvider sudah mengatur _country default ke 'id'.
        // Jadi, kita bisa asumsikan 'country' akan selalu ada.
        // Jika kategori tidak ada, kita bisa biarkan kosong atau set default.
        // Untuk saat ini, kita biarkan seperti ini, mengandalkan 'country' yang selalu ada.
      }

      
      // Log URL yang akan dipanggil
      final uri = Uri.parse('$_baseUrl/top-headlines').replace(queryParameters: params);
      print('Calling API: ${uri.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN')}');
      
      final response = await http.get(uri);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the full response body for debugging
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Periksa status respons
        if (data['status'] == 'error') {
          print('API Error: ${data['code']} - ${data['message']}');
          // Consider not throwing an exception here to see if UI can handle empty list gracefully
          // throw Exception('API Error: ${data['code']} - ${data['message']}');
          return []; // Return empty list on API error
        }
        
        if (data['status'] != 'ok') {
          print('Unexpected API status: ${data['status']}. Full response: $data');
          // throw Exception('Unexpected API status: ${data['status']}');
          return []; // Return empty list on unexpected status
        }
        
        // Log jumlah artikel yang diterima
        final articleCount = (data['articles'] as List?)?.length ?? 0;
        print('Received $articleCount articles from API.');
        
        if (articleCount == 0) {
          print('Warning: No articles returned from API, though status was ok.');
        }
        
        final articles = (data['articles'] as List? ?? [])
            .map((article) => Article.fromJson(article))
            .toList();
        return articles;
      } else {
        print('HTTP Error: ${response.statusCode}');
        // print('Response body: ${response.body}'); // Already printed above
        // throw Exception('Failed to load news: ${response.statusCode} - ${response.body}');
        return []; // Return empty list on HTTP error
      }
    } catch (e) {
      print('Exception in getTopHeadlines: $e');
      // rethrow; // Lempar kembali exception untuk ditangani di provider
      return []; // Return empty list on other exceptions
    }
  }
}