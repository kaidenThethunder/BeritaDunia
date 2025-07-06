import 'package:flutter/material.dart';
import '../models/video_article.dart';
import '../utils/constants.dart'; // For AppConstants
import '../screens/video_player_screen.dart'; // Import VideoPlayerScreen

class VideoNewsCard extends StatelessWidget {
  final VideoArticle videoArticle;

  const VideoNewsCard({super.key, required this.videoArticle});

  void _playVideo(BuildContext context) {
    final youtubeVideoUrl = 'https://www.youtube.com/watch?v=${videoArticle.id}';
    // Navigate to the VideoPlayerScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: youtubeVideoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: AppConstants.defaultPadding),
      child: InkWell(
        onTap: () => _playVideo(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (videoArticle.thumbnailUrl.isNotEmpty)
                  Image.network(
                    videoArticle.thumbnailUrl,
                    height: 160, // Reduced height for video thumbnail
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160, // Reduced height for video thumbnail
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.videocam_off, size: 50, color: Colors.grey)),
                      );
                    },
                  )
                else
                  Container(
                    height: 160, // Reduced height for video thumbnail
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.ondemand_video, size: 50, color: Colors.grey)),
                  ),
                // Play Icon Overlay
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 60),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0), // Reduced padding
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    videoArticle.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    videoArticle.channelTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Optionally, display publishedAt or description if desired
                  // const SizedBox(height: 4),
                  // Text(
                  //   'Published: ${DateFormat.yMMMd().format(videoArticle.publishedAt)}',
                  //   style: theme.textTheme.caption?.copyWith(fontSize: 10),
                  // ),
                ],
              ),
            ),
          ], // This closes the outer Column's children
        ), // This closes the outer Column
      ), // This closes the InkWell
    ); // This closes the Card
  }
}