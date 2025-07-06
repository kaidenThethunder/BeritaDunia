import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_article.dart'; // To be created
import '../utils/constants.dart'; // For API key (needs to be added securely)

class YoutubeService {
  final String _apiKey = AppConstants.youtubeApiKey; // IMPORTANT: Store API key securely, not hardcoded
  final String _baseUrl = 'www.googleapis.com'; // Corrected base URL (authority)

  Future<List<VideoArticle>> fetchVideoNews(
      {String? category, String? query, String countryCode = 'US', int maxResults = 10}) async {
    // YouTube API uses 'q' for query which can include category terms.
    // RegionCode can be used for country-specific results.
    String searchQuery = query ?? '';
    if (category != null && category.isNotEmpty) {
      searchQuery = '$category news $searchQuery'; // Append 'news' to category for relevance
    }
    searchQuery = searchQuery.trim();
    if (searchQuery.isEmpty) {
      searchQuery = 'latest news'; // Default search if no query or category
    }

    final Map<String, String> parameters = {
      'part': 'snippet',
      'q': searchQuery,
      'type': 'video',
      'maxResults': maxResults.toString(),
      'key': _apiKey,
      'regionCode': countryCode, // Use regionCode for YouTube API
    };

    final Uri uri = Uri.https(_baseUrl, '/youtube/v3/search', parameters); // Corrected Uri construction
    print('Calling YouTube API: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null) {
          final List<dynamic> videoItems = data['items'];
          return videoItems.map((item) => VideoArticle.fromJson(item)).toList();
        }
        return [];
      } else {
        print('YoutubeService Error: ${response.statusCode}');
        print('YoutubeService Error Body: ${response.body}');
        throw Exception('Failed to load video news: ${response.statusCode}');
      }
    } catch (e) {
      print('YoutubeService Exception: $e');
      throw Exception('Failed to load video news: $e');
    }
  }
}