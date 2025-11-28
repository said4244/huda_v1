import 'package:flutter/material.dart';
import 'dart:async';

class MicrophoneButton extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;
  final double size;
  
  const MicrophoneButton({
    Key? key,
    required this.onStart,
    required this.onStop,
    this.size = 80,
  }) : super(key: key);

  @override
  MicrophoneButtonState createState() => MicrophoneButtonState();
}

class MicrophoneButtonState extends State<MicrophoneButton> {
  bool _isActive = false;
  
  void _toggleMicrophone() {
    setState(() {
      _isActive = !_isActive;
    });
    
    if (_isActive) {
      widget.onStart();
    } else {
      widget.onStop();
    }
  }
  
  // Public method to stop microphone from outside
  void stopMicrophone() {
    if (_isActive) {
      setState(() {
        _isActive = false;
      });
      widget.onStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMicrophone,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isActive ? Colors.green : Colors.black,
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
          Icons.mic,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}