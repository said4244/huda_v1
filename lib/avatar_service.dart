import 'package:tavus_avatar_flutter/tavus_avatar_flutter.dart';
import 'dart:async';
import 'dart:convert';

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal();

  TavusAvatar? _avatar;
  bool _isInitialized = false;
  
  // Store video state
  bool _isPictureInPicture = false;
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  bool _isMicrophoneEnabled = false;
  
  // User data
  String? _userName;
  String? _selectedLanguage;
  
  // Track first-time actions
  bool _hasMinimizedFirstTime = false;
  bool _hasClickedFirstStep = false;
  bool _hasGreetedUser = false;

  TavusAvatar get avatar {
    if (_avatar == null) {
      print('[AvatarService] Creating new TavusAvatar instance');
      _avatar = TavusAvatar(
        config: TavusAvatarConfig(
          tokenUrl: 'https://server-b4xn.onrender.com/token',
          roomName: '',
          enableLogging: true,
        ),
      );
      print('[AvatarService] TavusAvatar instance created');
    }
    return _avatar!;
  }

  Future<void> startConnection() async {
    if (!_isInitialized) {
      _isInitialized = true;
      print('[AvatarService] Starting avatar connection');
      
      try {
        // Start connection in background
        await avatar.toggle();
        
        print('[AvatarService] Avatar toggle completed, waiting for connection...');
        
        // Wait a bit for connection to establish
        await Future.delayed(Duration(seconds: 2));
        
        // Disable microphone by default
        await _setMicrophoneEnabled(false);
        
        print('[AvatarService] Avatar connection initialized with microphone disabled');
      } catch (e) {
        print('[AvatarService] Error starting connection: $e');
      }
    }
  }
  
  // Store user data
  void setUserData({required String userName, required String selectedLanguage}) {
    _userName = userName;
    _selectedLanguage = selectedLanguage;
    print('[AvatarService] User data stored - Name: $userName, Language: $selectedLanguage');
  }
  
  // Get user data
  String? get userName => _userName;
  String? get selectedLanguage => _selectedLanguage;
  
  // Store video state
  void setVideoState({
    required bool isPictureInPicture,
    required bool isCallActive,
    required int callDurationSeconds,
  }) {
    _isPictureInPicture = isPictureInPicture;
    _isCallActive = isCallActive;
    _callDurationSeconds = callDurationSeconds;
  }
  
  // First-time action tracking
  void markMinimizeAsFirstTime() {
    _hasMinimizedFirstTime = true;
  }
  
  bool get hasMinimizedFirstTime => _hasMinimizedFirstTime;
  
  void markFirstStepClicked() {
    _hasClickedFirstStep = true;
  }
  
  bool get hasClickedFirstStep => _hasClickedFirstStep;
  
  void markUserGreeted() {
    _hasGreetedUser = true;
  }
  
  bool get hasGreetedUser => _hasGreetedUser;
  
  // Getters
  bool get isPictureInPicture => _isPictureInPicture;
  bool get isCallActive => _isCallActive;
  int get callDurationSeconds => _callDurationSeconds;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  
  // Enable/disable microphone using the TavusAvatar's built-in method
  void enableMicrophone(bool enable) async {
    print('[AvatarService] enableMicrophone called with: $enable');
    
    try {
      _isMicrophoneEnabled = enable;
      await _setMicrophoneEnabled(enable);
      print('[AvatarService] Microphone ${enable ? "enabled" : "disabled"} successfully');
    } catch (e) {
      print('[AvatarService] Error controlling microphone: $e');
    }
  }
  
  // Internal method to set microphone state
  Future<void> _setMicrophoneEnabled(bool enabled) async {
    try {
      if (_avatar != null) {
        print('[AvatarService] Calling setMicrophoneEnabled on avatar: $enabled');
        await _avatar!.setMicrophoneEnabled(enabled);
      } else {
        print('[AvatarService] Warning: Avatar instance is null');
      }
    } catch (e) {
      print('[AvatarService] Error in _setMicrophoneEnabled: $e');
    }
  }
  
  // Send text message to avatar using the TavusAvatar's publishData method
  void sendTextMessage(String message) async {
    print('[AvatarService] sendTextMessage called with: $message');
    
    try {
      if (_avatar != null && _avatar!.isConnected) {
        // Create a properly formatted message for the agent
        final dataMessage = {
          'type': 'user_message',
          'content': message,
          'timestamp': DateTime.now().toIso8601String()
        };
        
        final jsonMessage = json.encode(dataMessage);
        print('[AvatarService] Sending JSON message: $jsonMessage');
        
        // Use the avatar's publishData method
        await _avatar!.publishData(jsonMessage);
        
        print('[AvatarService] Message sent successfully via publishData');
      } else {
        print('[AvatarService] Warning: Avatar not connected or instance is null');
        print('[AvatarService] Avatar instance: $_avatar');
        print('[AvatarService] Is connected: ${_avatar?.isConnected}');
      }
    } catch (e) {
      print('[AvatarService] Error sending message: $e');
      print('[AvatarService] Stack trace: ${StackTrace.current}');
    }
  }

  void dispose() {
    print('[AvatarService] Disposing avatar service');
    _avatar?.dispose();
    _avatar = null;
    _isInitialized = false;
    _hasMinimizedFirstTime = false;
    _hasClickedFirstStep = false;
    _hasGreetedUser = false;
    _userName = null;
    _selectedLanguage = null;
  }
}