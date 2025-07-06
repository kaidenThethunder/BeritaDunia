class AppConstants {
  // API Constants
  static const String apiKey = '85efa6775a1a40f9943c070bdf937398';
  static const String baseUrl = 'https://newsapi.org/v2';
  static const String youtubeApiKey = 'AIzaSyAkTcr_WF4t1m4JQ04sAfE7dI3TAymYYpA'; // Added YouTube API Key
  
  // Category Constants
  static const List<String> categories = [
    'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'
  ];
  
  // Country Constants
  static const Map<String, String> countries = {
    'id': 'Indonesia',
    'us': 'United States',
    'gb': 'United Kingdom',
    'sg': 'Singapore',
    'my': 'Malaysia',
    'au': 'Australia',
  };
  
  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double horizontalPadding = 16.0; // Added horizontal padding
  static const double smallPadding = 8.0;
  static const double searchBarBorderRadius = 25.0;
  static const double chipBorderRadius = 20.0;
  static const double buttonBorderRadius = 8.0; // Default value, adjust as needed
  
  // Animation Constants
  static const int animationDuration = 150; // milliseconds
}