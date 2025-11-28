import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';
import 'firstguide.dart';

class IntroPage extends StatefulWidget {
  final bool navigateToGuide;
  
  const IntroPage({super.key, this.navigateToGuide = false});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasPlayedOnce = false;
  bool _isWaitingForSecondPlay = false;

  @override
  void initState() {
    super.initState();
    
    // FUCK THE VIDEO - JUST WAIT 3 SECONDS AND GO
    Future.delayed(Duration(seconds: 3), () {
      if (widget.navigateToGuide) {
        // Show preparing message for 2 more seconds
        setState(() {
          _isWaitingForSecondPlay = true;
        });
        Future.delayed(Duration(seconds: 2), _navigateToNext);
      } else {
        _navigateToNext();
      }
    });
    
    // Still try to initialize video but don't depend on it
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/intro_final.mp4');
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
      }
    } catch (e) {
      // Don't care if video fails
    }
  }

  void _navigateToNext() {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            widget.navigateToGuide ? const FirstGuide() : const LoginPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(254,208,138,255),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Video player area - show if it works, otherwise just a placeholder
                Flexible(
                  child: _isInitialized && _controller != null
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : Container(
                          width: 300,
                          height: 200,
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 60,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                // Huda text
                const Text(
                  'Huda',
                  style: TextStyle(
                    fontSize: 100,
                    color: Color(0xFF4D382D),
                    fontFamily: 'Tufuli Arabic',
                  ),
                ),
                const SizedBox(height: 50), // Bottom padding
              ],
            ),
          ),
          
          // Subtle loading indicator when preparing for avatar (only show during second play)
          if (widget.navigateToGuide && _isWaitingForSecondPlay)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF4D382D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Preparing your teacher...',
                        style: TextStyle(
                          color: Color(0xFF4D382D),
                          fontSize: 14,
                          fontFamily: 'Tufuli Arabic',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}