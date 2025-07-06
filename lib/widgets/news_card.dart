import 'package:flutter/material.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../utils/constants.dart';

class NewsCard extends StatefulWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: AppConstants.animationDuration),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        // Navigate to article detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: widget.article),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (BuildContext context, Widget? child_param_not_used_directly) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: 4,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section with gradient overlay
                  Stack(
                    children: [
                      if (widget.article.urlToImage != null)
                        Image.network(
                          widget.article.urlToImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image_not_supported, size: 45, color: Colors.grey)),
                            );
                          },
                        )
                      else
                        Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image, size: 45, color: Colors.grey)),
                        ),
                      // Gradient overlay for better text visibility if needed
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (widget.article.description != null)
                                  Text(
                                    widget.article.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: Colors.black87,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Source and author information
                          Row(
                            children: [
                              // User-generated badge
                              if (widget.article.isUserGenerated == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'User Generated',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              if (widget.article.isUserGenerated == true)
                                const SizedBox(width: 3),
                              // Author information
                              Expanded(
                                child: Text(
                                  widget.article.isUserGenerated == true
                                      ? 'Oleh: ${widget.article.author ?? 'Anonim'}'
                                      : 'Sumber: ${widget.article.source?.name ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ), // This closes the Column
            ),
          ); // This closes the Transform.scale
        }, // This closes the AnimatedBuilder's builder
      ), // This closes the AnimatedBuilder
    ); // This closes the GestureDetector
  }
}