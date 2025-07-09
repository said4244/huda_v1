import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'intro_page.dart';
import 'avatar_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  bool _isLanguageDropdownOpen = false;
  int _currentStep = 0; // 0: greeting, 1: questions, 2: language selection, 3: arabic level, 4: name input, 5: completion
  String? _selectedLanguage; // Track selected language
  String? _selectedArabicLevel; // Track selected Arabic level
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  final List<Map<String, String>> _languages = [
    {'code': 'nl', 'flag': 'nl.png', 'name': 'Nederlands'},
    {'code': 'en', 'flag': 'en.png', 'name': 'English'},
    {'code': 'fr', 'flag': 'fr.png', 'name': 'Français'},
    {'code': 'de', 'flag': 'de.png', 'name': 'Deutsch'},
    {'code': 'ar', 'flag': 'ar.png', 'name': 'عربي'},
    {'code': 'tr', 'flag': 'tr.png', 'name': 'Türkçe'},
    {'code': 'es', 'flag': 'sp.png', 'name': 'Español'},
  ];

  final List<Map<String, dynamic>> _arabicLevels = [
    {'key': 'new_to_arabic', 'level': 1},
    {'key': 'read_simple_sentences', 'level': 2},
    {'key': 'read_texts_conversations', 'level': 3},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize bounce animation
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    // Start the continuous bounce animation
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double _getProgressValue() {
    switch (_currentStep) {
      case 2: return 0.25; // 25%
      case 3: return 0.50; // 50%
      case 4: return 0.75; // 75%
      default: return 0.25;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar - show from step 2 to 4 only (not on completion page)
            if (_currentStep >= 2 && _currentStep <= 4)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Stack(
                  children: [
                    // Background progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF808080),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled progress bar
                    Container(
                      height: 8,
                      width: (size.width - 40) * _getProgressValue(),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D382D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: _currentStep == 5 
                  ? _buildCompletionPage(size, languageProvider)
                  : _currentStep == 4 
                      ? _buildNameInputPage(size, languageProvider)
                      : _currentStep == 3 
                          ? _buildArabicLevelPage(size, languageProvider)
                          : _currentStep == 2 
                              ? _buildLanguageSelectionPage(size, languageProvider)
                              : _buildWelcomePage(size, languageProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(Size size, LanguageProvider languageProvider) {
    return Stack(
      children: [
        // Main content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            children: [
              // Top spacer
              SizedBox(height: size.height * 0.25),
              
              // Animated speech bubble positioned above camel
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_bounceAnimation.value),
                      child: Container(
                        margin: const EdgeInsets.only(right: 20, bottom: 20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Speech bubble
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xfffcd698),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _currentStep == 1 
                                    ? languageProvider.getLocalizedText('lets_start_questions')
                                    : languageProvider.getLocalizedText('greeting') + '\n' + 
                                      languageProvider.getLocalizedText('i_am_huda'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  color: const Color(0xFF4D382D),
                                  fontFamily: 'Tufuli Arabic',
                                  height: 1.3,
                                ),
                              ),
                            ),
                            // Speech bubble tail pointing down-left
                            Positioned(
                              bottom: -8,
                              left: 25,
                              child: CustomPaint(
                                painter: SpeechBubbleTailPainter(),
                                size: const Size(16, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Camel mascot - 50% bigger
              Container(
                height: size.height * 0.375, // Increased from 0.25 to 0.375 (50% bigger)
                constraints: const BoxConstraints(maxHeight: 450), // Increased from 300 to 450
                child: Image.asset(
                  _currentStep >= 1 
                      ? 'assets/images/camelserious.png'
                      : 'assets/images/camelwaving.png',
                  fit: BoxFit.contain,
                ),
              ),
              
              // Spacer to push button to bottom
              const Spacer(),
              
              // Continue button at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: size.width * 0.8,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep++;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D382D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      languageProvider.getLocalizedText('continue'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: 'Tufuli Arabic',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Language selector - only show in first two steps
        if (_currentStep < 2)
          Positioned(
            top: 16,
            left: 16,
            child: _buildLanguageSelector(languageProvider),
          ),
      ],
    );
  }

  Widget _buildLanguageSelectionPage(Size size, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header with camel and question
          Row(
            children: [
              Container(
                width: 90, // Increased from 60 to 90 (50% bigger)
                height: 90, // Increased from 60 to 90 (50% bigger)
                child: Image.asset(
                  'assets/images/camelserious.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageProvider.getLocalizedText('which_language_best'),
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: const Color(0xFF4D382D),
                    fontFamily: 'Tufuli Arabic',
                    fontWeight: FontWeight.w500, // Keep at 500 as requested
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Language options
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelectable = language['code'] == 'nl' || language['code'] == 'en';
                final isSelected = _selectedLanguage == language['code'];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: isSelectable ? () {
                      setState(() {
                        _selectedLanguage = language['code'];
                        // Update the language provider when user selects
                        Provider.of<LanguageProvider>(context, listen: false)
                            .setLanguage(language['code']!);
                      });
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4D382D) : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Flag
                          Container(
                            width: 32,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/images/flags/${language['flag']}',
                                fit: BoxFit.cover,
                                opacity: isSelectable ? null : const AlwaysStoppedAnimation(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Language name
                          Expanded(
                            child: Text(
                              language['name']!,
                              style: TextStyle(
                                fontSize: 18,
                                color: isSelectable ? const Color(0xFF4D382D) : Colors.grey,
                                fontFamily: 'Tufuli Arabic',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // Selection triangle
                          Container(
                            width: 24,
                            height: 24,
                            child: CustomPaint(
                              painter: TrianglePainter(
                                isSelected: isSelected,
                                isSelectable: isSelectable,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Continue button
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: size.width * 0.8,
              height: 65,
              child: ElevatedButton(
                onPressed: _selectedLanguage != null ? () {
                  setState(() {
                    _currentStep = 3; // Go to Arabic level page
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedLanguage != null 
                      ? const Color(0xFF4D382D) 
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  languageProvider.getLocalizedText('continue'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Tufuli Arabic',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicLevelPage(Size size, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header with camel and question
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                child: Image.asset(
                  'assets/images/camelserious.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageProvider.getLocalizedText('how_much_arabic'),
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: const Color(0xFF4D382D),
                    fontFamily: 'Tufuli Arabic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Arabic level options
          Expanded(
            child: Column(
              children: _arabicLevels.map((level) {
                final isSelected = _selectedArabicLevel == level['key'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArabicLevel = level['key'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4D382D) : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Level bars
                          Container(
                            width: 40,
                            height: 24,
                            child: CustomPaint(
                              painter: LevelBarsPainter(level: level['level']),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Level text
                          Expanded(
                            child: Text(
                              languageProvider.getLocalizedText(level['key']),
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF4D382D),
                                fontFamily: 'Tufuli Arabic',
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Continue button
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: size.width * 0.8,
              height: 65,
              child: ElevatedButton(
                onPressed: _selectedArabicLevel != null ? () {
                  setState(() {
                    _currentStep = 4; // Go to name input page
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedArabicLevel != null 
                      ? const Color(0xFF4D382D) 
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  languageProvider.getLocalizedText('continue'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Tufuli Arabic',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputPage(Size size, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // "Almost done" text
          Text(
            languageProvider.getLocalizedText('almost_done'),
            style: TextStyle(
              fontSize: size.width * 0.06,
              color: const Color(0xFF4D382D),
              fontFamily: 'Tufuli Arabic',
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Happy camel mascot
          Container(
            height: size.height * 0.25,
            constraints: const BoxConstraints(maxHeight: 300),
            child: Image.asset(
              'assets/images/cameldone.png',
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // "What is your name?" text
          Text(
            languageProvider.getLocalizedText('what_is_your_name'),
            style: TextStyle(
              fontSize: size.width * 0.05,
              color: const Color(0xFF4D382D),
              fontFamily: 'Tufuli Arabic',
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Name input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _nameController,
              onChanged: (value) {
                setState(() {}); // Rebuild to update button state
              },
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF4D382D),
                fontFamily: 'Tufuli Arabic',
              ),
              decoration: InputDecoration(
                hintText: languageProvider.getLocalizedText('enter_your_name'),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Tufuli Arabic',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          
          // Spacer to push button to bottom
          const Spacer(),
          
          // Continue button
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: size.width * 0.8,
              height: 65,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isNotEmpty ? () {
                  // Store user data in AvatarService
                  final userName = _nameController.text.trim();
                  final selectedLanguage = _selectedLanguage ?? 'en';
                  
                  // Store user data
                  AvatarService().setUserData(
                    userName: userName,
                    selectedLanguage: selectedLanguage,
                  );
                  
                  // Start avatar connection in background
                  AvatarService().startConnection();
                  
                  setState(() {
                    _currentStep = 5; // Go to completion page
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nameController.text.trim().isNotEmpty 
                      ? const Color(0xFF4D382D) 
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  languageProvider.getLocalizedText('continue'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Tufuli Arabic',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPage(Size size, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children: [
          // Top spacer
          SizedBox(height: size.height * 0.25),
          
          // Animated speech bubble positioned above camel
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: Container(
                    margin: const EdgeInsets.only(right: 20, bottom: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Speech bubble
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xfffcd698),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            languageProvider.getLocalizedText('meet_your_teacher'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: const Color(0xFF4D382D),
                              fontFamily: 'Tufuli Arabic',
                              height: 1.3,
                            ),
                          ),
                        ),
                        // Speech bubble tail pointing down-left
                        Positioned(
                          bottom: -8,
                          left: 25,
                          child: CustomPaint(
                            painter: SpeechBubbleTailPainter(),
                            size: const Size(16, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Happy camel mascot
          Container(
            height: size.height * 0.375,
            constraints: const BoxConstraints(maxHeight: 450),
            child: Image.asset(
              'assets/images/camelwaving.png', // Back to waving camel for completion
              fit: BoxFit.contain,
            ),
          ),
          
          // Spacer to push button to bottom
          const Spacer(),
          
          // Continue button at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: size.width * 0.8,
              height: 65,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to intro page first to give avatar more time
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntroPage(navigateToGuide: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D382D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  languageProvider.getLocalizedText('continue'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Tufuli Arabic',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider languageProvider) {
    final currentLang = _languages.firstWhere(
      (lang) => lang['code'] == languageProvider.currentLanguage,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current flag button
        GestureDetector(
          onTap: () {
            setState(() {
              _isLanguageDropdownOpen = !_isLanguageDropdownOpen;
            });
          },
          child: Container(
            width: 30,
            height: 22.25,
            margin: const EdgeInsets.only(left: 14, top: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/flags/${currentLang['flag']}',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        // Dropdown
        if (_isLanguageDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 2, left: 14),
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _languages
                  .where((lang) => lang['code'] != languageProvider.currentLanguage)
                  .map((lang) => GestureDetector(
                        onTap: () {
                          if (lang['code'] == 'en' || lang['code'] == 'nl') {
                            languageProvider.setLanguage(lang['code']!);
                            setState(() {
                              _isLanguageDropdownOpen = false;
                            });
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 22.25,
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.asset(
                              'assets/images/flags/${lang['flag']}',
                              fit: BoxFit.cover,
                              opacity: (lang['code'] == 'en' || lang['code'] == 'nl')
                                  ? null
                                  : const AlwaysStoppedAnimation(0.5),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// Custom painter for speech bubble tail
class SpeechBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xfffcd698)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for selection triangle
class TrianglePainter extends CustomPainter {
  final bool isSelected;
  final bool isSelectable;

  TrianglePainter({required this.isSelected, required this.isSelectable});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    if (isSelected) {
      paint.color = const Color(0xFF4D382D);
    } else if (isSelectable) {
      paint.color = Colors.grey[300]!;
    } else {
      paint.color = Colors.grey[200]!;
    }

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);

    // Draw border for unselected but selectable items
    if (!isSelected && isSelectable) {
      final borderPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for Arabic level bars
class LevelBarsPainter extends CustomPainter {
  final int level;

  LevelBarsPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 5; // 4 bars + 3 gaps
    final barHeight = size.height;
    final gap = barWidth * 0.2;

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = i < level ? const Color(0xFF4D382D) : const Color(0xFF808080)
        ..style = PaintingStyle.fill;

      final barRect = Rect.fromLTWH(
        i * (barWidth + gap),
        barHeight - (barHeight * 0.3 * (i + 1)), // Increasing height
        barWidth,
        barHeight * 0.3 * (i + 1),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}