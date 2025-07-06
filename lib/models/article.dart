import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleSource {
  final String id;
  final String name;

  ArticleSource({required this.id, required this.name});

  factory ArticleSource.fromJson(Map<String, dynamic> json) {
    return ArticleSource(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Article {
  final String title;
  final String? description;
  final String? content;
  final String? urlToImage;
  final ArticleSource? source;
  final String? url;
  final DateTime publishedAt;
  final String? author;
  final String? videoUrl;
  final bool isUserGenerated;
  final String? userId;
  final String? userEmail;
  final String? documentId;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  Article({
    required this.title,
    this.description,
    this.content,
    this.urlToImage,
    this.source,
    this.url,
    required this.publishedAt,
    this.author,
    this.videoUrl,
    this.isUserGenerated = false,
    this.userId,
    this.userEmail,
    this.documentId,
    this.isApproved = true,
    this.approvedBy,
    this.approvedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      content: json['content'],
      urlToImage: json['urlToImage'],
      source: json['source'] != null ? ArticleSource.fromJson(json['source']) : null,
      url: json['url'],
      publishedAt: json['publishedAt'] != null 
          ? (json['publishedAt'] is String 
              ? DateTime.parse(json['publishedAt']) 
              : json['publishedAt'] is Timestamp
                  ? (json['publishedAt'] as Timestamp).toDate()
                  : (json['publishedAt'] as DateTime))
          : DateTime.now(),
      author: json['author'],
      videoUrl: json['videoUrl'],
      isUserGenerated: json['isUserGenerated'] ?? false,
      userId: json['userId'],
      userEmail: json['userEmail'],
      documentId: json['documentId'],
      isApproved: json['isApproved'] ?? true,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null 
          ? (json['approvedAt'] is String 
              ? DateTime.parse(json['approvedAt']) 
              : json['approvedAt'] is Timestamp
                  ? (json['approvedAt'] as Timestamp).toDate()
                  : (json['approvedAt'] as DateTime))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'urlToImage': urlToImage,
      'source': source?.toJson(),
      'url': url,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'videoUrl': videoUrl,
      'isUserGenerated': isUserGenerated,
      'userId': userId,
      'userEmail': userEmail,
      'documentId': documentId,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}