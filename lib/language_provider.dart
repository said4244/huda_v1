import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'nl'; // Default to Dutch
  
  String get currentLanguage => _currentLanguage;
  
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
  
  String getLocalizedText(String key) {
    final Map<String, Map<String, String>> translations = {
      'nl': {
        'formal_education': 'Formele Arabische Educatie.',
        'for_everyone': 'Voor Iedereen.',
        'begin': 'Begin',
        'login': 'Log in',
        'continue': 'Doorgaan',
        'greeting': 'Assalamu Alaikum!',
        'i_am_huda': 'Ik ben Huda.',
        'lets_start_questions': 'Laten we beginnen\nmet een paar vragen...',
        'which_language_best': 'Welke taal kent u het beste?',
        'how_much_arabic': 'Hoeveel Arabisch ken je?',
        'new_to_arabic': 'Ik ben nieuw in het Arabisch',
        'read_simple_sentences': 'Ik kan eenvoudige zinnen lezen',
        'read_texts_conversations': 'Ik kan teksten lezen en begrijpen\nen eenvoudige gesprekken voeren',
        'almost_done': 'Bijna klaar!',
        'what_is_your_name': 'Wat is je naam?',
        'enter_your_name': 'Vul hier je naam in',
        'meet_your_teacher': 'Oke! Nu kun je je\ndocent ontmoeten!',
        'arabic_first_steps': 'Arabisch - Eerste stappen',
        'arabic_next_phase': 'Arabisch - Volgende fase',
        'arabic_fluency_path': 'Arabisch - Vloeiend pad',
        'first_step': 'Eerste stap',
        'progress': 'Voortgang',
        'continue_next_lesson': 'Ga door naar de volgende les',
        'video_loading': 'Video wordt geladen...',
        'play_video': 'Video afspelen',
      },
      'en': {
        'formal_education': 'Formal Arabic Education.',
        'for_everyone': 'For Everyone.',
        'begin': 'Begin',
        'login': 'Log in',
        'continue': 'Continue',
        'greeting': 'Assalamu Alaikum!',
        'i_am_huda': 'I am Huda.',
        'lets_start_questions': 'Let\'s start with\na couple of questions...',
        'which_language_best': 'Which language do you know best?',
        'how_much_arabic': 'How much Arabic do you know?',
        'new_to_arabic': 'I am new to Arabic',
        'read_simple_sentences': 'I can read simple sentences',
        'read_texts_conversations': 'I can read and understand texts\nand have simple conversations',
        'almost_done': 'Almost done!',
        'what_is_your_name': 'What is your name?',
        'enter_your_name': 'Enter your name here',
        'meet_your_teacher': 'Okay! Now you can\nmeet your teacher!',
        'arabic_first_steps': 'Arabic - First steps',
        'arabic_next_phase': 'Arabic - Next phase',
        'arabic_fluency_path': 'Arabic - Fluency path',
        'first_step': 'First step',
        'progress': 'Progress',
        'continue_next_lesson': 'Continue to next lesson',
        'video_loading': 'Loading video...',
        'play_video': 'Play video',
      },
    };
    
    return translations[_currentLanguage]?[key] ?? translations['nl']![key]!;
  }
}