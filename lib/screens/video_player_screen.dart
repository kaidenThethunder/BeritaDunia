import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    // Extract video ID from URL. 
    // e.g., https://www.youtube.com/watch?v=VIDEO_ID or https://youtu.be/VIDEO_ID
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (_videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // Autoplay video
          mute: false,
        ),
      );
    } else {
      // Handle invalid URL, perhaps show an error or a placeholder
      print('Error: Could not extract video ID from URL: ${widget.videoUrl}');
      // You might want to set an error state here to display in the UI
    }
  }

  @override
  void dispose() {
    if (_videoId != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      // Display an error message or a placeholder if the video ID couldn't be extracted
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Player Error'),
        ),
        body: const Center(
          child: Text('Invalid YouTube URL provided.'),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: const Text('Video Berita')),
          body: Center(child: player),
        );
      },
    );
  }
}