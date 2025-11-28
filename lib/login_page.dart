import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'welcome_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLanguageDropdownOpen = false;
  final List<Map<String, String>> _languages = [
    {'code': 'nl', 'flag': 'nl.png'},
    {'code': 'en', 'flag': 'en.png'},
    {'code': 'ar', 'flag': 'ar.png'},
    {'code': 'de', 'flag': 'de.png'},
    {'code': 'fr', 'flag': 'fr.png'},
    {'code': 'es', 'flag': 'sp.png'},
    {'code': 'tr', 'flag': 'tr.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.1,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Camel mascot
                    Container(
                      height: size.height * 0.3,
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Image.asset(
                        'assets/images/camel.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: size.height * 0.0003),
                    
                    // Huda text
                    Text(
                      'Huda',
                      style: TextStyle(
                        fontSize: size.width * 0.20,
                        color: const Color(0xFF4D382D),
                        fontFamily: 'Tufuli Arabic',
                      ),
                    ),
                    SizedBox(height: size.height * 0.0002),
                    
                    // Subtitle
                    Container(
                      width: size.width * 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          languageProvider.getLocalizedText('formal_education'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: size.width * 0.07,
                            color: const Color(0xFF4D382D),
                            fontFamily: 'Tufuli Arabic',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      languageProvider.getLocalizedText('for_everyone'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width * 0.06,
                        color: const Color(0xFF4D382D),
                        fontFamily: 'Tufuli Arabic',
                      ),
                    ),
                    SizedBox(height: size.height * 0.06),
                    
                    // Begin button
                    SizedBox(
                      width: size.width * 1,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomePage(),
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
                          languageProvider.getLocalizedText('begin'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontFamily: 'Tufuli Arabic',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Login button
                    SizedBox(
                      width: size.width * 1,
                      height: 65,
                      child: OutlinedButton(
                        onPressed: null, // Inactive for now
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF4D382D),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          languageProvider.getLocalizedText('login'),
                          style: const TextStyle(
                            color: Color(0xFF4D382D),
                            fontSize: 28,
                            fontFamily: 'Tufuli Arabic',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Language selector
            Positioned(
              top: 16,
              left: 16,
              child: _buildLanguageSelector(languageProvider),
            ),
          ],
        ),
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