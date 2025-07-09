import 'package:flutter/material.dart';
import 'arabic_letter_video_player.dart';
import 'avatar_service.dart';

class DelayedArabicLetterVideoPlayer extends StatefulWidget {
  final String videoFileName;
  final double? width;
  final double? height;
  final String selectedLanguage;

  const DelayedArabicLetterVideoPlayer({
    super.key,
    required this.videoFileName,
    this.width = 300,
    this.height,
    required this.selectedLanguage,
  });

  @override
  State<DelayedArabicLetterVideoPlayer> createState() => _DelayedArabicLetterVideoPlayerState();
}

class _DelayedArabicLetterVideoPlayerState extends State<DelayedArabicLetterVideoPlayer> {
  bool _canPlay = false;
  bool _isWaiting = true;

  @override
  void initState() {
    super.initState();
    _sendPromptAndWait();
  }

  Future<void> _sendPromptAndWait() async {
    // Send Ba prompt before video plays
    final language = widget.selectedLanguage == 'nl' ? 'Dutch' : 'English';
    final prompt = 'Talk in $language. Say: Now watch carefully as I show you how to write the Arabic letter Ba. This letter makes the "B" sound, just like in the word "ball".';
    
    print('[DelayedVideoPlayer] Sending Ba video prompt');
    AvatarService().sendTextMessage(prompt);
    
    // Wait for avatar to finish speaking (estimate 5 seconds)
    await Future.delayed(Duration(seconds: 5));
    
    if (mounted) {
      setState(() {
        _canPlay = true;
        _isWaiting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWaiting) {
      // Show loading state while waiting for avatar to speak
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
                'Teacher is preparing the lesson...',
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

    // Show the video player when ready
    return ArabicLetterVideoPlayer(
      videoFileName: widget.videoFileName,
      width: widget.width,
      height: widget.height,
      autoPlay: true,
      autoPlayDelaySeconds: 1,
    );
  }
}