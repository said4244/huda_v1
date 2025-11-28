import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class ListenChoose extends StatefulWidget {
  final String audioFileName;
  final int callCount; // To track which time this is being called
  final Function(bool) onAnswerChanged; // Callback to notify parent of answer state
  
  const ListenChoose({
    Key? key,
    required this.audioFileName,
    required this.callCount,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  ListenChooseState createState() => ListenChooseState();
}

// Create a global key type for accessing state
class ListenChooseState extends State<ListenChoose> with SingleTickerProviderStateMixin {
  late AnimationController _audioButtonController;
  late Animation<double> _audioButtonAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool? _selectedAnswer;
  bool _isCorrectAnswer = false;
  late String _displayedLetter;
  late String _actualLetter;
  late String _arabicLetter;
  
  final Map<String, String> _letterMap = {
    'Ba': 'ب',
    'Ta': 'ت',
    'Tha': 'ث',
  };

  @override
  void initState() {
    super.initState();
    
    _audioButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _audioButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _audioButtonController,
      curve: Curves.easeInOut,
    ));
    
    _initializeLetter();
  }

  void _initializeLetter() {
    // Extract letter name from audio file name (e.g., "Ba.mp3" -> "Ba")
    _actualLetter = widget.audioFileName.replaceAll('.mp3', '');
    
    print('[ListenChoose] Call count: ${widget.callCount}, Audio file: ${widget.audioFileName}');
    
    // Determine which letter to display based on call count
    if (widget.callCount == 1) {
      // First time: MUST match
      _displayedLetter = _actualLetter;
      _isCorrectAnswer = true;
      print('[ListenChoose] First call - Letter MUST match. Displayed: $_displayedLetter, Actual: $_actualLetter');
    } else if (widget.callCount == 2) {
      // Second time: MUST NOT match (still using Ba.mp3)
      List<String> otherLetters = _letterMap.keys.where((l) => l != _actualLetter).toList();
      _displayedLetter = otherLetters[Random().nextInt(otherLetters.length)];
      _isCorrectAnswer = false;
      print('[ListenChoose] Second call - Letter MUST NOT match. Displayed: $_displayedLetter, Actual: $_actualLetter');
    } else {
      // Third and fourth time: 50/50 chance
      if (Random().nextBool()) {
        _displayedLetter = _actualLetter;
        _isCorrectAnswer = true;
      } else {
        List<String> otherLetters = _letterMap.keys.where((l) => l != _actualLetter).toList();
        _displayedLetter = otherLetters[Random().nextInt(otherLetters.length)];
        _isCorrectAnswer = false;
      }
      print('[ListenChoose] Call ${widget.callCount} - 50/50 chance. Displayed: $_displayedLetter, Actual: $_actualLetter, Match: $_isCorrectAnswer');
    }
    
    _arabicLetter = _letterMap[_displayedLetter]!;
  }

  void _playAudio() async {
    // Animate button press
    _audioButtonController.forward();
    
    try {
      // Play the audio file
      await _audioPlayer.play(AssetSource('audio/${widget.audioFileName}'));
    } catch (e) {
      print('Error playing audio: $e');
    }
    
    await HapticFeedback.lightImpact();
    _audioButtonController.reverse();
  }

  void _onAnswerSelected(bool answer) {
    setState(() {
      _selectedAnswer = answer;
    });
    
    // Notify parent widget about answer state
    widget.onAnswerChanged(_isAnswerCorrect());
  }

  bool _isAnswerCorrect() {
    if (_selectedAnswer == null) return false;
    return (_selectedAnswer == true && _isCorrectAnswer) || 
           (_selectedAnswer == false && !_isCorrectAnswer);
  }

  @override
  void dispose() {
    _audioButtonController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Audio button and text row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio button
              GestureDetector(
                onTap: _playAudio,
                child: AnimatedBuilder(
                  animation: _audioButtonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _audioButtonAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF4D382D),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // "Listen and choose" text
              Text(
                'Listen and choose',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4d382d),
                  fontFamily: 'Tufuli Arabic',
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Large Arabic letter display
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _arabicLetter,
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4d382d),
                fontFamily: 'Roboto', // Changed to Roboto as requested
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // True and False buttons (stacked vertically)
        Container(
          width: MediaQuery.of(context).size.width * 0.6, // 75% of continue button (0.8 * 0.75)
          child: Column(
            children: [
              // True button
              _buildAnswerButton(
                label: 'True',
                isSelected: _selectedAnswer == true,
                isCorrect: _selectedAnswer == true && _isAnswerCorrect(),
                isIncorrect: _selectedAnswer == true && !_isAnswerCorrect(),
                onTap: () => _onAnswerSelected(true),
              ),
              
              const SizedBox(height: 16),
              
              // False button
              _buildAnswerButton(
                label: 'False',
                isSelected: _selectedAnswer == false,
                isCorrect: _selectedAnswer == false && _isAnswerCorrect(),
                isIncorrect: _selectedAnswer == false && !_isAnswerCorrect(),
                onTap: () => _onAnswerSelected(false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool isSelected,
    required bool isCorrect,
    required bool isIncorrect,
    required VoidCallback onTap,
  }) {
    Color borderColor = Colors.grey[300]!;
    Color backgroundColor = Colors.white;
    
    if (isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (isIncorrect) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (isSelected) {
      borderColor = Color(0xFF4d382d);
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Full width within padding
        height: 55,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isSelected ? borderColor : Colors.grey[600],
              fontFamily: 'Tufuli Arabic',
            ),
          ),
        ),
      ),
    );
  }

  bool get canContinue => _isAnswerCorrect();
}

// New Multiple Choice class
class ListenChooseMultiple extends StatefulWidget {
  final String audioFileName;
  final Function(bool) onAnswerChanged;
  
  const ListenChooseMultiple({
    Key? key,
    required this.audioFileName,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  ListenChooseMultipleState createState() => ListenChooseMultipleState();
}

class ListenChooseMultipleState extends State<ListenChooseMultiple> with SingleTickerProviderStateMixin {
  late AnimationController _audioButtonController;
  late Animation<double> _audioButtonAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int? _selectedIndex;
  late String _actualLetter;
  late int _correctIndex;
  List<String> _displayedLetters = [];
  
  final Map<String, String> _letterMap = {
    'Ba': 'ب',
    'Ta': 'ت',
    'Tha': 'ث',
    'Nun': 'ن',
    'Ha': 'ح',
    'Kha': 'خ',
  };

  @override
  void initState() {
    super.initState();
    
    _audioButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _audioButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _audioButtonController,
      curve: Curves.easeInOut,
    ));
    
    _initializeLetters();
  }

  void _initializeLetters() {
    // Extract letter name from audio file name
    _actualLetter = widget.audioFileName.replaceAll('.mp3', '');
    
    // Create list of 4 letters including the correct one
    List<String> availableLetters = _letterMap.keys.toList();
    availableLetters.remove(_actualLetter);
    availableLetters.shuffle();
    
    // Take 3 random letters
    List<String> selectedLetters = availableLetters.take(3).toList();
    selectedLetters.add(_actualLetter);
    
    // Shuffle to randomize position
    selectedLetters.shuffle();
    
    _displayedLetters = selectedLetters;
    _correctIndex = _displayedLetters.indexOf(_actualLetter);
    
    print('[ListenChooseMultiple] Correct letter: $_actualLetter at index $_correctIndex');
  }

  void _playAudio() async {
    _audioButtonController.forward();
    
    try {
      await _audioPlayer.play(AssetSource('audio/${widget.audioFileName}'));
    } catch (e) {
      print('Error playing audio: $e');
    }
    
    await HapticFeedback.lightImpact();
    _audioButtonController.reverse();
  }

  void _onLetterSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Notify parent widget about answer state
    widget.onAnswerChanged(index == _correctIndex);
  }

  @override
  void dispose() {
    _audioButtonController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Audio button and text row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio button
              GestureDetector(
                onTap: _playAudio,
                child: AnimatedBuilder(
                  animation: _audioButtonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _audioButtonAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF4D382D),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // "Listen and choose" text
              Text(
                'Listen and choose',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4d382d),
                  fontFamily: 'Tufuli Arabic',
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // 2x2 Grid of letters
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildLetterOption(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLetterOption(int index) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = isSelected && index == _correctIndex;
    bool isIncorrect = isSelected && index != _correctIndex;
    
    Color borderColor = Colors.grey[300]!;
    Color backgroundColor = Colors.white;
    
    if (isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (isIncorrect) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (isSelected) {
      borderColor = Color(0xFF4d382d);
    }
    
    return GestureDetector(
      onTap: () => _onLetterSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _letterMap[_displayedLetters[index]]!,
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4d382d),
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}