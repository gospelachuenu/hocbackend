import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../config/app_config.dart';
import '../services/youtube_service.dart';

class WatchLiveScreen extends StatefulWidget {
  const WatchLiveScreen({super.key});

  @override
  State<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  YoutubePlayerController? _controller;
  final _youtubeService = YoutubeService();
  bool _isFullScreen = false;
  bool _isLive = false;
  String? _streamTitle;
  String? _streamDescription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final streamInfo = await _youtubeService.getCurrentLiveStreamInfo();
      if (mounted) {
        setState(() {
          _isLive = streamInfo != null;
          if (streamInfo != null) {
            _streamTitle = streamInfo['title'];
            _streamDescription = streamInfo['description'];
            final streamId = streamInfo['videoId'];
            
            final newController = YoutubePlayerController(
              initialVideoId: streamId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                isLive: true,
                hideControls: true,
                enableCaption: false,
                hideThumbnail: true,
                useHybridComposition: true,
                forceHD: true,
              ),
            );

            final oldController = _controller;
            if (oldController != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                oldController.dispose();
              });
            }

            _controller = newController;
          }
        });
      }
    } catch (e) {
      print('Error getting stream info: $e');
      if (mounted) {
        setState(() {
          _isLive = false;
        });
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Fullscreen toggle
            IconButton(
              icon: Icon(
                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: _toggleFullScreen,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLive
            ? Stack(
                children: [
                  Center(
                    child: _controller != null
                        ? YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                            progressColors: const ProgressBarColors(
                              playedColor: Colors.red,
                              handleColor: Colors.redAccent,
                              backgroundColor: Colors.grey,
                              bufferedColor: Colors.grey,
                            ),
                            onEnded: (data) {
                              setState(() {
                                _isLive = false;
                              });
                            },
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                            ),
                          ),
                  ),
                  // Back button at the top
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Bottom controls
                  _buildControls(),
                ],
              )
            : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                    const Icon(
                      Icons.tv_off,
                      size: 64,
            color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Not Live at the Moment',
                      style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check back later for live streams',
                      style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
              setState(() {
                          _controller = null;
              });
                        await _initializePlayer();
            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
              shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
                ),
              ),
      ),
    );
  }
}

class OfferingScreen extends StatelessWidget {
  const OfferingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make an Offering'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text('Offering Screen - Coming Soon'),
      ),
    );
  }
} 