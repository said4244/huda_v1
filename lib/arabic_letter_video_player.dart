import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class ArabicLetterVideoPlayer extends StatefulWidget {
  final String videoFileName;
  final double? width;
  final double? height;
  final bool autoPlay;
  final int autoPlayDelaySeconds;

  const ArabicLetterVideoPlayer({
    super.key,
    required this.videoFileName,
    this.width = 300,
    this.height,
    this.autoPlay = true,
    this.autoPlayDelaySeconds = 1,
  });

  @override
  State<ArabicLetterVideoPlayer> createState() => _ArabicLetterVideoPlayerState();
}

class _ArabicLetterVideoPlayerState extends State<ArabicLetterVideoPlayer> {
  VideoPlayerController? _videoController;
  Timer? _videoProgressTimer;
  double _videoProgress = 0.0;
  bool _isVideoPlaying = false;
  bool _videoInitialized = false;
  bool _hasVideoError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    
    if (widget.autoPlay) {
      Timer(Duration(seconds: widget.autoPlayDelaySeconds), () {
        if (_videoInitialized && mounted) {
          _playVideo();
        }
      });
    }
  }

  @override
  void dispose() {
    _videoProgressTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() async {
    try {
      List<String> videoPaths = [
        'assets/videos/letters/${widget.videoFileName}',
        'assets/videos/${widget.videoFileName}',
        'videos/letters/${widget.videoFileName}',
        'videos/${widget.videoFileName}',
      ];
      
      bool videoLoaded = false;
      
      for (String path in videoPaths) {
        try {
          print('Trying to load video from: $path');
          _videoController = VideoPlayerController.asset(path);
          
          await _videoController!.initialize();
          
          if (mounted) {
            setState(() {
              _videoInitialized = true;
              _hasVideoError = false;
              videoLoaded = true;
            });
            print('Video loaded successfully from: $path');
            break;
          }
        } catch (e) {
          print('Failed to load video from $path: $e');
          _videoController?.dispose();
          _videoController = null;
        }
      }
      
      if (!videoLoaded && mounted) {
        setState(() {
          _hasVideoError = true;
          _errorMessage = 'Could not load video file: ${widget.videoFileName}';
        });
      }
      
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _errorMessage = 'Video initialization failed: ${e.toString()}';
        });
      }
    }
  }

  void _playVideo() {
    if (_videoController != null && _videoInitialized && !_isVideoPlaying) {
      _videoController!.play();
      setState(() {
        _isVideoPlaying = true;
      });
      
      _videoProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && _videoController != null && _videoController!.value.isInitialized) {
          final position = _videoController!.value.position.inMilliseconds;
          final duration = _videoController!.value.duration.inMilliseconds;
          
          setState(() {
            _videoProgress = duration > 0 ? position / duration : 0.0;
          });
          
          if (position >= duration) {
            timer.cancel();
            setState(() {
              _isVideoPlaying = false;
              _videoProgress = 1.0;
            });
          }
        }
      });
    }
  }

  String _getArabicLetterFromFileName() {
    // Extract Arabic letter based on filename
    final fileName = widget.videoFileName.toLowerCase().replaceAll('.mp4', '');
    
    final Map<String, String> letterMap = {
      'ba': 'ب',
      'ta': 'ت',
      'tha': 'ث',
      'jeem': 'ج',
      'haa': 'ح',
      'khaa': 'خ',
      'dal': 'د',
      'thal': 'ذ',
      'ra': 'ر',
      'zay': 'ز',
      'seen': 'س',
      'sheen': 'ش',
      'sad': 'ص',
      'dad': 'ض',
      'taa': 'ط',
      'zaa': 'ظ',
      'ain': 'ع',
      'ghain': 'غ',
      'fa': 'ف',
      'qaf': 'ق',
      'kaf': 'ك',
      'lam': 'ل',
      'meem': 'م',
      'noon': 'ن',
      'ha': 'ه',
      'waw': 'و',
      'ya': 'ي',
    };
    
    return letterMap[fileName] ?? 'ب'; // Default to Ba if not found
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic height based on content
    double containerHeight = widget.height ?? 420; // Increased default height
    
    if (_hasVideoError) {
      return _buildErrorFallback();
    }

    if (!_videoInitialized) {
      return _buildLoadingState();
    }

    return Container(
      width: widget.width,
      height: containerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Video area - flexible to take available space
              Expanded(
                flex: 4, // Takes most of the space
                child: Container(
                  width: double.infinity,
                  child: _videoController != null 
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.video_library,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                ),
              ),
              
              // Controls area - fixed height with proper spacing
              Container(
                height: 100, // Increased height to prevent overflow
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play button
                    GestureDetector(
                      onTap: _playVideo,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isVideoPlaying ? Colors.grey[400] : Color(0xFFFFB800),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16), // Increased spacing
                    
                    // Progress bar
                    SizedBox(
                      height: 16, // Fixed height for progress bar area
                      child: Stack(
                        children: [
                          // Background line
                          Positioned(
                            top: 6,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFB800),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          
                          // Progress ball
                          Positioned(
                            left: ((widget.width! - 40) * _videoProgress) - 8, // Dynamic positioning
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFB800),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Container(
      width: widget.width,
      height: widget.height ?? 420,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getArabicLetterFromFileName(),
                style: TextStyle(
                  fontSize: 120,
                  color: Color(0xFF4d382d),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Arabic Letter ${widget.videoFileName.replaceAll('.mp4', '').toUpperCase()}',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4d382d),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Video format not supported',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.width,
      height: widget.height ?? 420,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF4d382d),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Color(0xFF4d382d),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}