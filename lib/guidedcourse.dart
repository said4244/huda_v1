import 'package:flutter/material.dart';
import 'package:tavus_avatar_flutter/tavus_avatar_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';
import 'avatar_service.dart';
import 'language_provider.dart';
import 'arabic_letter_video_player.dart';

class GuidedCourse extends StatefulWidget {
  const GuidedCourse({super.key});

  @override
  State<GuidedCourse> createState() => _GuidedCourseState();
}

class _GuidedCourseState extends State<GuidedCourse> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pipController;
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  double _progress = 0.0;
  bool _isPictureInPicture = false;
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    
    // GET STATE FROM AVATAR SERVICE
    final avatarService = AvatarService();
    _isPictureInPicture = avatarService.isPictureInPicture;
    _isCallActive = avatarService.isCallActive;
    _callDurationSeconds = avatarService.callDurationSeconds;
    
    // Initialize progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Initialize PiP animation
    _pipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Continue call timer if active
    if (_isCallActive) {
      _startCallTimer();
    }
    
    // Animate progress bar
    _animateProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pipController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _animateProgress() {
    _progressController.forward().then((_) {
      setState(() {
        _progress = 0.3; // Set to 30% progress for this lesson
      });
    });
  }

  String _formatCallDuration() {
    final minutes = _callDurationSeconds ~/ 60;
    final seconds = _callDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    _callTimer?.cancel();
    _callTimer = null;
    AvatarService().avatar.toggle();
    Navigator.of(context).pop();
  }
  
  void _togglePictureInPicture() {
    setState(() {
      _isPictureInPicture = !_isPictureInPicture;
    });
    
    if (_isPictureInPicture) {
      _pipController.forward();
    } else {
      _pipController.reverse();
    }
  }

  void _onContinue() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(languageProvider.getLocalizedText('continue_next_lesson')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with user profile and stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Row(
                    children: [
                      // User profile image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/user.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Fire icon with count
                      Image.asset(
                        'assets/images/fire.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf1473a),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Diamond icon with count
                      Image.asset(
                        'assets/images/diamond.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF38b6ff),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Spacer to position back arrow below PiP window
                SizedBox(height: _isPictureInPicture ? 140 : 20),
                
                // Back arrow
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xFF4d382d),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Progress bar (updated color)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.getLocalizedText('progress'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4d382d),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4d382d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF4d382d), // Updated color
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Arabic Letter Video Player - Now using the reusable widget!
                Expanded(
                  child: Center(
                    child: ArabicLetterVideoPlayer(
                      videoFileName: 'Ba.mp4',
                      width: 320, // Slightly wider to prevent overflow
                      height: 450, // Increased height to prevent overflow
                      autoPlay: true,
                      autoPlayDelaySeconds: 1,
                    ),
                  ),
                ),
                
                // Continue button (updated color)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4d382d), // Updated color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      languageProvider.getLocalizedText('continue'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Picture-in-Picture video call (ADD THIS IF IN PIP MODE)
          if (_isCallActive)
            _buildPictureInPictureVideoInterface(),
        ],
      ),
    );
  }

  Widget _buildPictureInPictureVideoInterface() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      top: _isPictureInPicture ? MediaQuery.of(context).padding.top + 16 : 0,
      right: _isPictureInPicture ? 16 : 0,
      left: _isPictureInPicture ? null : 0,
      bottom: _isPictureInPicture ? null : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: _isPictureInPicture ? 120 : MediaQuery.of(context).size.width,
        height: _isPictureInPicture ? 160 : MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          borderRadius: _isPictureInPicture 
              ? BorderRadius.circular(12) 
              : BorderRadius.zero,
          boxShadow: _isPictureInPicture ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Avatar video
              Positioned.fill(
                bottom: _isPictureInPicture ? 40 : 0, // Leave space for timer
                child: TavusAvatarView(
                  avatar: AvatarService().avatar,
                  aspectRatio: _isPictureInPicture ? 1.0 : MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
                  borderRadius: BorderRadius.zero,
                  showStatus: false,
                  placeholder: _buildPlaceholder(),
                ),
              ),
              
              // Call timer
              if (_isPictureInPicture)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          _formatCallDuration(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              
              // PiP controls
              if (_isPictureInPicture)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Expand button
                      GestureDetector(
                        onTap: _togglePictureInPicture,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Full screen controls
              if (!_isPictureInPicture)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child: _buildActiveCallControls(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Picture-in-Picture button (X button)
          GestureDetector(
            onTap: _togglePictureInPicture,
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          
          // End call button (red)
          GestureDetector(
            onTap: _endCall,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'End call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Icon(
          Icons.person,
          size: _isPictureInPicture ? 40 : 120,
          color: Colors.white54,
        ),
      ),
    );
  }
}