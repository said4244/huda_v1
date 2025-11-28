import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'microphone_button.dart';
import 'avatar_service.dart';
import 'dart:async';

class ArabicAnimationPlayer extends StatefulWidget {
  final String videoFileName;
  final String selectedLanguage;
  final double? width;
  final double? height;
  final bool autoPlay;
  final int autoPlayDelaySeconds;

  const ArabicAnimationPlayer({
    super.key,
    required this.videoFileName,
    required this.selectedLanguage,
    this.width = 300,
    this.height,
    this.autoPlay = true,
    this.autoPlayDelaySeconds = 1,
  });

  @override
  State<ArabicAnimationPlayer> createState() => _ArabicAnimationPlayerState();
}

class _ArabicAnimationPlayerState extends State<ArabicAnimationPlayer> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _hasVideoError = false;
  String _errorMessage = '';
  Timer? _autoPlayTimer;
  final GlobalKey<MicrophoneButtonState> _micButtonKey = GlobalKey<MicrophoneButtonState>();
  bool _hasPlayedVideo = false;
  bool _isMicrophoneEnabled = false;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    
    if (widget.autoPlay) {
      _autoPlayTimer = Timer(Duration(seconds: widget.autoPlayDelaySeconds), () {
        if (_videoInitialized && mounted && !_hasPlayedVideo) {
          _playVideoAndSendPrompt();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _silenceTimer?.cancel();
    _videoController?.dispose();
    // Make sure microphone is disabled when leaving page
    if (_isMicrophoneEnabled) {
      AvatarService().enableMicrophone(false);
    }
    super.dispose();
  }

  void _initializeVideo() async {
    try {
      String videoPath = 'assets/videos/letters/${widget.videoFileName}';
      print('[ArabicAnimationPlayer] Loading animation video from: $videoPath');
      
      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _videoInitialized = true;
          _hasVideoError = false;
        });
        print('[ArabicAnimationPlayer] Animation video loaded successfully');
      }
    } catch (e) {
      print('[ArabicAnimationPlayer] Error initializing animation video: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _errorMessage = 'Could not load video: ${e.toString()}';
        });
      }
    }
  }

  void _playVideoAndSendPrompt() async {
    if (_videoController != null && _videoInitialized && !_hasPlayedVideo) {
      _hasPlayedVideo = true;
      
      print('[ArabicAnimationPlayer] Playing video and sending prompt');
      
      // Play the video
      await _videoController!.play();
      
      // Wait a moment to ensure avatar is ready
      await Future.delayed(Duration(milliseconds: 500));
      
      // Send the prompt to avatar based on video file
      _sendPromptToAvatar();
      
      // When video ends, stop it
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _videoController!.pause();
          _videoController!.seekTo(Duration.zero);
          _videoController!.removeListener(() {});
        }
      });
    }
  }

  void _sendPromptToAvatar() {
    String prompt = '';
    
    try {
      if (widget.videoFileName.toLowerCase().contains('baanimation')) {
        String language = widget.selectedLanguage == 'nl' ? 'Dutch' : 'English';
        prompt = 'Talk in $language you\'re watching a video of Huda playing with ball happily while on a boat. Huda throws the ball and loses it. The ball is exactly below the boat now, and now the picture looks like the Arabic Letter Ba. The whole video is 12 seconds, describe in 12 seconds what you\'re seeing and then use the video as a learning method for the Arabic Letter Ba, like this: Ba Ba Ba Boot, Ba Ba Ba Bal. Then prompt the user at the end to pronounce Ba in the microphone';
      }
      
      if (prompt.isNotEmpty) {
        print('[ArabicAnimationPlayer] Sending prompt to avatar: $prompt');
        AvatarService().sendTextMessage(prompt);
      }
    } catch (e) {
      print('[ArabicAnimationPlayer] Error sending prompt: $e');
    }
  }

  void _onMicrophoneStart() {
    print('[ArabicAnimationPlayer] Microphone button pressed - starting');
    setState(() {
      _isMicrophoneEnabled = true;
    });
    
    try {
      AvatarService().enableMicrophone(true);
      
      // Cancel any existing silence timer
      _silenceTimer?.cancel();
      
      // Don't auto-stop for now - let user control it
      // _startSilenceDetection();
    } catch (e) {
      print('[ArabicAnimationPlayer] Error starting microphone: $e');
    }
  }

  void _onMicrophoneStop() {
    print('[ArabicAnimationPlayer] Microphone button released - stopping');
    setState(() {
      _isMicrophoneEnabled = false;
    });
    
    try {
      AvatarService().enableMicrophone(false);
      
      // Cancel silence timer
      _silenceTimer?.cancel();
    } catch (e) {
      print('[ArabicAnimationPlayer] Error stopping microphone: $e');
    }
  }
  
  void _startSilenceDetection() {
    // Simple silence detection - in production you'd use actual audio levels
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      if (_isMicrophoneEnabled && mounted) {
        print('[ArabicAnimationPlayer] Auto-stopping microphone after silence');
        _micButtonKey.currentState?.stopMicrophone();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = widget.height ?? 420;
    
    if (_hasVideoError) {
      return _buildErrorFallback();
    }

    if (!_videoInitialized) {
      return _buildLoadingState();
    }

    return Container(
      width: widget.width,
      height: containerHeight,
      child: Column(
        children: [
          // Video player
          Expanded(
            child: Container(
              width: double.infinity,
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
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Microphone button
          MicrophoneButton(
            key: _micButtonKey,
            onStart: _onMicrophoneStart,
            onStop: _onMicrophoneStop,
            size: 80,
          ),
        ],
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF4d382d),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              'Loading animation...',
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