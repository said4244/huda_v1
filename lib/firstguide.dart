import 'package:flutter/material.dart';
import 'package:tavus_avatar_flutter/tavus_avatar_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';
import 'avatar_service.dart';
import 'language_provider.dart';
import 'arabic_animation_player.dart';
import 'delayed_video_player.dart';
import 'ba_writing_exercise.dart';
import 'listen_choose.dart';

class FirstGuide extends StatefulWidget {
  const FirstGuide({super.key});

  @override
  State<FirstGuide> createState() => _FirstGuideState();
}

class _FirstGuideState extends State<FirstGuide> with TickerProviderStateMixin {
  late final AnimationController _swipeController;
  late final AnimationController _pipController;
  late final AnimationController _progressController;
  late final Animation<Offset> _swipeAnimation;
  
  bool _isCallActive = false;
  bool _showBlurOverlay = true;
  bool _isPictureInPicture = false;
  bool _showFirstStepPage = false;
  bool _showGuidedCourse = false;
  bool _showAnimationPage = false;
  bool _showWritingExercise = false;
  bool _isWritingExerciseComplete = false;
  bool _showListenChoose = false;
  int _listenChooseCallCount = 0;
  String _currentAudioFile = '';
  bool _canContinueListenChoose = false;
  bool _showListenChooseMultiple = false;
  int _listenChooseMultipleCount = 0;
  bool _canContinueListenChooseMultiple = false;
  String _currentAudioFileMultiple = '';
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String? _selectedLesson;
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize swipe animation
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));

    // Initialize picture-in-picture animation
    _pipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Initialize progress animation for guided course
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _pipController.dispose();
    _progressController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    setState(() {
      _isCallActive = true;
      _showBlurOverlay = false;
      _callDurationSeconds = 0;
    });
    
    _startCallTimer();
    _swipeController.forward();
    
    // Send greeting prompt after call is answered
    if (!AvatarService().hasGreetedUser) {
      final userName = AvatarService().userName ?? 'there';
      final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
      // Wait a moment for the call to fully establish
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
          final prompt = 'Talk in $language. The user\'s name is $userName, greet him like this: assalamu alaikum, then say his name. Nothing else do not ask him any questions, since he cannot yet respond. Say welcome to your first lesson, today we\'re going to learn the arabic letter Ba. Click on the minimize button to see your home page.';
          
          print('[FirstGuide] Sending greeting prompt');
          AvatarService().sendTextMessage(prompt);
          AvatarService().markUserGreeted();
        }
      });
    }
  }

  void _togglePictureInPicture() {
    setState(() {
      _isPictureInPicture = !_isPictureInPicture;
    });
    
    if (_isPictureInPicture) {
      _pipController.forward();
      
      // Send minimize prompt if it's the first time
      if (!AvatarService().hasMinimizedFirstTime) {
        final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        
        // Wait a moment for the minimize animation to complete
        Future.delayed(Duration(milliseconds: 700), () {
          if (mounted) {
            final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
            final firstStepsText = languageProvider.getLocalizedText('arabic_first_steps');
            final prompt = 'Talk in $language. Say now click on "$firstStepsText" since you\'re just starting out.';
            
            print('[FirstGuide] Sending minimize prompt');
            AvatarService().sendTextMessage(prompt);
            AvatarService().markMinimizeAsFirstTime();
          }
        });
      }
    } else {
      _pipController.reverse();
    }
  }

  void _endCall() {
    _callTimer?.cancel();
    _callTimer = null;
    AvatarService().avatar.toggle();
    Navigator.of(context).pop();
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

  String _formatCallDuration() {
    final minutes = _callDurationSeconds ~/ 60;
    final seconds = _callDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectLesson(String lessonKey) {
    if (lessonKey == 'first_steps') {
      setState(() {
        _selectedLesson = lessonKey;
        _showFirstStepPage = true;
      });
      
      // Send first step prompt
      if (!AvatarService().hasClickedFirstStep) {
        final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
        
        // Wait a moment for the page transition
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
            final prompt = 'Talk in $language, say now click on your very first step, the blue one. Say it excitingly.';
            
            print('[FirstGuide] Sending first step prompt');
            AvatarService().sendTextMessage(prompt);
            AvatarService().markFirstStepClicked();
          }
        });
      }
    }
  }

  void _goBackToLessonSelection() {
    setState(() {
      _showFirstStepPage = false;
      _selectedLesson = null;
    });
  }

  void _navigateToGuidedCourse() {
    setState(() {
      _showGuidedCourse = true;
    });
    _animateProgress();
  }
  
  void _goBackFromGuidedCourse() {
    setState(() {
      _showGuidedCourse = false;
      _progress = 0.0;
    });
  }
  
  void _navigateToAnimationPage() {
    setState(() {
      _showAnimationPage = true;
    });
  }
  
  void _goBackFromAnimationPage() {
    setState(() {
      _showAnimationPage = false;
    });
  }

  void _navigateToWritingExercise() {
    setState(() {
      _showWritingExercise = true;
    });
  }

  void _goBackFromWritingExercise() {
    setState(() {
      _showWritingExercise = false;
      _isWritingExerciseComplete = false;
    });
  }

  void _goBackFromListenChoose() {
    setState(() {
      _showListenChoose = false;
      _listenChooseCallCount = 0;
      _currentAudioFile = '';
    });
  }
  
  void _animateProgress() {
    _progressController.forward().then((_) {
      setState(() {
        _progress = 0.3;
      });
    });
  }
  
  void _onContinue() {
    if (_showWritingExercise && !_showListenChoose) {
      // From writing exercise, go to first listen_choose
      setState(() {
        _showListenChoose = true;
        _listenChooseCallCount = 1;
        _currentAudioFile = 'Ba.mp3';
        _canContinueListenChoose = false; // Reset for new exercise
      });
      
      // Send avatar prompt
      final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
      final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
      final letter = _currentAudioFile.replaceAll('.mp3', '');
      final prompt = 'Talk in $language, say "here we see a letter", is this letter the letter $letter? Click on true if it is, or on false if its not, click on the sound button to hear the pronunciation again';
      
      AvatarService().sendTextMessage(prompt);
    } else if (_showListenChoose) {
      // Handle listen_choose progression
      if (_listenChooseCallCount < 4) {
        setState(() {
          _listenChooseCallCount++;
          
          // Determine audio file based on call count
          if (_listenChooseCallCount == 2) {
            _currentAudioFile = 'Ba.mp3'; // Second time still Ba
          } else if (_listenChooseCallCount == 3) {
            _currentAudioFile = 'Ta.mp3';
          } else if (_listenChooseCallCount == 4) {
            _currentAudioFile = 'Tha.mp3';
          }
        });
        
        // Send avatar prompt for new exercise
        final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
        final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
        final letter = _currentAudioFile.replaceAll('.mp3', '');
        final prompt = 'Talk in $language, say "here we see a letter", is this letter the letter $letter? Click on true if it is, or on false if its not, click on the sound button to hear the pronunciation again';
        
        AvatarService().sendTextMessage(prompt);
      } else {
        // After all listen_choose exercises, go to multiple choice
        if (!_showListenChooseMultiple) {
          setState(() {
            _showListenChoose = false;
            _showListenChooseMultiple = true;
            _listenChooseMultipleCount = 1;
            _currentAudioFile = 'Ta.mp3';
            _currentAudioFileMultiple = _currentAudioFile;
            _canContinueListenChooseMultiple = false;
          });
        }
        // Send avatar prompt
        final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
        final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
        final letter = _currentAudioFileMultiple.replaceAll('.mp3', '');
        final prompt = 'Talk in $language say "The letter of this exercise is $letter, choose the right letter"';
        
        AvatarService().sendTextMessage(prompt);
      }
    } else if (_showListenChooseMultiple) {
      // Handle multiple choice progression - SAME LOGIC AS REGULAR LISTEN CHOOSE
      if (_listenChooseMultipleCount < 2) {
        setState(() {
          _listenChooseMultipleCount++;
          
          // Determine audio file based on count
          if (_listenChooseMultipleCount == 1) {
            _currentAudioFileMultiple = 'Ta.mp3';
          } else if (_listenChooseMultipleCount == 2) {
            _currentAudioFileMultiple = 'Tha.mp3';
          }
          
          _canContinueListenChooseMultiple = false; // Reset for new exercise
        });
        
        // Send avatar prompt
        final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
        final language = selectedLanguage == 'nl' ? 'Dutch' : 'English';
        final letter = _currentAudioFileMultiple.replaceAll('.mp3', '');
        final prompt = 'Talk in $language say "The letter of this exercise is $letter, choose the right letter"';
        
        AvatarService().sendTextMessage(prompt);
      } else {
        // After all exercises, show completion message
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getLocalizedText('continue_next_lesson')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (_showGuidedCourse && !_showAnimationPage && !_showWritingExercise) {
      // From guided course, go to animation page
      _navigateToAnimationPage();
    } else if (_showAnimationPage && !_showWritingExercise) {
      // From animation page, go to writing exercise
      _navigateToWritingExercise();
    } else {
      // From other pages, show snackbar
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getLocalizedText('continue_next_lesson')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background content page
          _showListenChooseMultiple
              ? _buildListenChooseMultiplePage(languageProvider)
              : (_showListenChoose
                  ? _buildListenChoosePage(languageProvider)
                  : (_showWritingExercise
                      ? _buildWritingExercisePage(languageProvider)
                      : (_showAnimationPage
                          ? _buildAnimationPage(languageProvider)
                          : (_showGuidedCourse 
                              ? _buildGuidedCoursePage(languageProvider)
                              : (_showFirstStepPage 
                                  ? _buildFirstStepPage(languageProvider)
                                  : _buildLessonSelectionPage(languageProvider)))))),
          // Single video call interface
          _buildAnimatedVideoInterface(),
        ],
      ),
    );
  }

  Widget _buildAnimationPage(LanguageProvider languageProvider) {
    return SafeArea(
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
                  onTap: _goBackFromAnimationPage,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
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
                        fontFamily: 'Roboto',
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
                        color: Color(0xFF4d382d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Arabic Animation Player
          Expanded(
            child: Center(
              child: ArabicAnimationPlayer(
                videoFileName: 'BaAnimation.mp4',
                selectedLanguage: languageProvider.currentLanguage,
                width: 320,
                height: 450,
                autoPlay: true,
                autoPlayDelaySeconds: 1,
              ),
            ),
          ),
          
          // Continue button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4d382d),
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
    );
  }

  Widget _buildWritingExercisePage(LanguageProvider languageProvider) {
    return SafeArea(
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
                  onTap: _goBackFromWritingExercise,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
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
                        fontFamily: 'Roboto',
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
                        color: Color(0xFF4d382d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Ba Writing Exercise
          Expanded(
            child: Center(
              child: BaWritingExercise(
                width: 320,
                height: 400,
                onComplete: (complete) {
                  setState(() {
                    _isWritingExerciseComplete = complete;
                  });
                },
              ),
            ),
          ),
          
          // Continue button - only enabled when exercise is complete
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isWritingExerciseComplete ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4d382d),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                disabledForegroundColor: Colors.white70,
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
    );
  }

  Widget _buildListenChoosePage(LanguageProvider languageProvider) {
    return SafeArea(
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
          
          // Spacer to position content below PiP window
          SizedBox(height: _isPictureInPicture ? 140 : 20),

          // Back arrow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBackFromListenChoose,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
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
                        fontFamily: 'Roboto',
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
                        color: Color(0xFF4d382d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Listen Choose Exercise
          // Listen Choose Exercise
          Expanded(
            child: Center(
              child: ListenChoose(
                key: ValueKey('listen_choose_$_listenChooseCallCount'), // Add this line
                audioFileName: _currentAudioFile,
                callCount: _listenChooseCallCount,
                onAnswerChanged: (bool isCorrect) {
                  setState(() {
                    _canContinueListenChoose = isCorrect;
                    if (isCorrect) {
                      // Update progress based on which exercise we're on
                      _progress = 0.3 + (_listenChooseCallCount * 0.1);
                    }
                  });
                },
              ),
            ),
          ),
          
          // Continue button - only enabled when answer is correct
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _canContinueListenChoose ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4d382d),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                disabledForegroundColor: Colors.white70,
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
    );
  }

  Widget _buildListenChooseMultiplePage(LanguageProvider languageProvider) {
    return SafeArea(
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
          
          // Spacer to position content below PiP window
          SizedBox(height: _isPictureInPicture ? 140 : 20),
          
          // Back arrow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showListenChooseMultiple = false;
                      _showListenChoose = true;
                      _listenChooseMultipleCount = 0;
                    });
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
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
                        fontFamily: 'Roboto',
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
                        color: Color(0xFF4d382d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Listen Choose Multiple Exercise
          Expanded(
            child: Center(
              child: ListenChooseMultiple(
                key: ValueKey('listen_choose_multiple_$_listenChooseMultipleCount-$_currentAudioFileMultiple'),
                audioFileName: _currentAudioFile,
                onAnswerChanged: (bool isCorrect) {
                  setState(() {
                    _canContinueListenChooseMultiple = isCorrect;
                    if (isCorrect) {
                      // Update progress
                      _progress = 0.7 + (_listenChooseMultipleCount * 0.15);
                    }
                  });
                },
              ),
            ),
          ),
          
          // Continue button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _canContinueListenChooseMultiple ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4d382d),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                disabledForegroundColor: Colors.white70,
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
    );
  }

  // Build the guided course page content
  Widget _buildGuidedCoursePage(LanguageProvider languageProvider) {
    final selectedLanguage = AvatarService().selectedLanguage ?? 'en';
    
    return SafeArea(
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
                  onTap: _goBackFromGuidedCourse,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
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
                        fontFamily: 'Roboto',
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
                        color: Color(0xFF4d382d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Arabic Letter Video Player with avatar prompt
          Expanded(
            child: Center(
              child: DelayedArabicLetterVideoPlayer(
                videoFileName: 'Ba.mp4',
                width: 320,
                height: 450,
                selectedLanguage: selectedLanguage,
              ),
            ),
          ),
          
          // Continue button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4d382d),
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
    );
  }

  Widget _buildLessonSelectionPage(LanguageProvider languageProvider) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user profile and stats - at very top left
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
            
            // Back arrow - positioned below PiP window and above first choice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4d382d),
                    size: 24,
                  ),
                ],
              ),
            ),
            
            // Lesson options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // First option - Selectable
                    _buildLessonOption(
                      key: 'first_steps',
                      title: languageProvider.getLocalizedText('arabic_first_steps'),
                      subtitle: 'Arabic - First steps',
                      imagePath: 'assets/images/camelwalking.png',
                      isEnabled: true,
                      isSelected: _selectedLesson == 'first_steps',
                      onTap: () => _selectLesson('first_steps'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Second option - Disabled
                    _buildLessonOption(
                      key: 'next_phase',
                      title: languageProvider.getLocalizedText('arabic_next_phase'),
                      subtitle: 'Arabic - Next phase',
                      imagePath: 'assets/images/camelrunning.png',
                      isEnabled: false,
                      isSelected: false,
                      onTap: null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Third option - Disabled
                    _buildLessonOption(
                      key: 'fluency_path',
                      title: languageProvider.getLocalizedText('arabic_fluency_path'),
                      subtitle: 'Arabic - Fluency path',
                      imagePath: 'assets/images/camelflying.png',
                      isEnabled: false,
                      isSelected: false,
                      onTap: null,
                    ),
                    
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonOption({
    required String key,
    required String title,
    required String subtitle,
    required String imagePath,
    required bool isEnabled,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Color(0xFF4d382d) : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Color(0xFF4d382d) : Colors.grey,
                          fontFamily: 'Tufuli Arabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    opacity: isEnabled ? null : const AlwaysStoppedAnimation(0.3),
                  ),
                ),
              ],
            ),
          ),
          
          // Gray overlay for disabled options
          if (!isEnabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFirstStepPage(LanguageProvider languageProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          
          children: [
            // Header with user profile and stats - same as lesson selection
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
            
            // Functional back arrow
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBackToLessonSelection,
                    child: Icon(
                      Icons.arrow_back,
                      color: Color(0xFF4d382d),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Challenge steps path
            Expanded(
              child: Stack(
                children: [
                  // Camel letters image on the right side (bigger)
                  Positioned(
                    right: 10,
                    top: screenHeight * 0.15,
                    child: Image.asset(
                      'assets/images/camelletters.png',
                      width: 180,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Challenge steps
                  _buildChallengeSteps(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSteps() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Stack(
      children: [
        // Step 1 - Blue active step (top center)
        Positioned(
          left: screenWidth * 0.5 - 75,
          top: screenHeight * 0.005,
          child: _buildStepContainer(
            isActive: true,
            isClickable: true,
            onTap: _navigateToGuidedCourse,
            child: Image.asset(
              'assets/images/star.png',
              width: 40,
              height: 40,
              color: Colors.white,
            ),
          ),
        ),
        
        // Step 2 - Gray step (left and down with more spacing)
        Positioned(
          left: screenWidth * 0.2 - 50,
          top: screenHeight * 0.15,
          child: _buildStepContainer(
            isActive: false,
            isClickable: false,
            child: Image.asset(
              'assets/images/star.png',
              width: 40,
              height: 40,
              color: Colors.white54,
            ),
          ),
        ),
        
        // Step 3 - Gray step (further left and down with more spacing)
        Positioned(
          left: screenWidth * 0.08 - 50,
          top: screenHeight * 0.30,
          child: _buildStepContainer(
            isActive: false,
            isClickable: false,
            child: Image.asset(
              'assets/images/star.png',
              width: 40,
              height: 40,
              color: Colors.white54,
            ),
          ),
        ),
        
        // Step 4 - Gift (bottom left, no container, no lines)
        Positioned(
          left: screenWidth * 0.2 -50,
          top: screenHeight * 0.48,
          child: Image.asset(
            'assets/images/gift.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        
        // Step 5 - Gray step (bottom, more spacing)
        Positioned(
          left: screenWidth * 0.5 - 62.5,
          top: screenHeight * 0.58,
          child: _buildStepContainer(
            isActive: false,
            isClickable: false,
            child: Image.asset(
              'assets/images/star.png',
              width: 40,
              height: 40,
              color: Colors.white54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer({
    required bool isActive,
    required bool isClickable,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 150,
      height: 150,
      child: Stack(
        children: [
          // Top-right diagonal line
          Positioned(
            left: 75 + 15,
            top: 75 - 15,
            child: Transform.rotate(
              angle: 0.385398, // 45 degrees in radians
              child: Container(
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: (isActive) ? Color(0xFF38b6ff) : Color(0xFF808080),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          // Bottom-right diagonal line
          Positioned(
            left: 75 + 15,
            top: 75 + 15,
            child: Transform.rotate(
              angle: -0.785398, // -45 degrees in radians
              child: Container(
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          // Top-left diagonal line
          Positioned(
            left: 75 - 15,
            top: 75 - 15,
            child: Transform.rotate(
              angle: -0.785398, // -45 degrees in radians
              child: Container(
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          // Bottom-left diagonal line
          Positioned(
            left: 75 - 15,
            top: 75 + 15,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees in radians
              child: Container(
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          // The step itself (centered)
          Positioned(
            left: 75 - 45, // Center the 90px step
            top: 75 - 45,
            child: GestureDetector(
              onTap: isClickable ? onTap : null,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isActive ? Color(0xFF38b6ff) : Color(0xFF808080),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedVideoInterface() {
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
              // Single Avatar video that scales appropriately
              Positioned.fill(
                bottom: _isPictureInPicture ? 40 : 0, // Leave space for timer in PiP
                child: TavusAvatarView(
                  avatar: AvatarService().avatar,
                  aspectRatio: _isPictureInPicture 
                      ? 1.0 // Square for PiP
                      : MediaQuery.of(context).size.width / MediaQuery.of(context).size.height, // Full screen ratio
                  borderRadius: BorderRadius.zero,
                  showStatus: false,
                  placeholder: _buildPlaceholder(),
                ),
              ),
              
              // Blur overlay when call hasn't been answered (only in full screen)
              if (_showBlurOverlay && !_isPictureInPicture)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              
              // Call timer - different positions for full screen vs PiP
              if (_isCallActive)
                _isPictureInPicture 
                    ? _buildPiPTimer()
                    : _buildFullScreenTimer(),
              
              // Bottom controls (only show in full screen mode)
              if (!_isPictureInPicture)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child: _isCallActive ? _buildActiveCallControls() : _buildIncomingCallControls(),
                ),
              
              // PiP controls (only show in PiP mode)
              if (_isPictureInPicture)
                _buildPiPControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPiPTimer() {
    return Positioned(
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
    );
  }

  Widget _buildFullScreenTimer() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _formatCallDuration(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiPControls() {
    return Positioned(
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

  Widget _buildIncomingCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx > 5) {
            _answerCall();
          }
        },
        onTap: _answerCall,
        child: SlideTransition(
          position: _swipeAnimation,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.green,
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
                    Icons.phone,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Swipe to answer',
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
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Picture-in-Picture button (new X button)
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
}