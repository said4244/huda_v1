import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class BaWritingExercise extends StatefulWidget {
  final double width;
  final double height;
  final Function(bool)? onComplete;

  const BaWritingExercise({
    Key? key,
    this.width = 320,
    this.height = 400,
    this.onComplete,
  }) : super(key: key);

  @override
  State<BaWritingExercise> createState() => _BaWritingExerciseState();
}

class _BaWritingExerciseState extends State<BaWritingExercise>
    with TickerProviderStateMixin {
  late Path letterPath;
  double pathProgress = 0.0;
  bool isTracing = false;
  bool isDragging = false;
  bool isPathComplete = false;
  bool isDotClicked = false;
  bool isDemoMode = false;
  Offset? currentDotPosition;
  late Offset nuqtaPosition;
  
  late AnimationController glowController;
  late AnimationController dotGlowController;
  late AnimationController demoController;
  late Animation<double> dotGlowAnimation;
  late Animation<double> demoAnimation;
  
  // For path metrics calculations
  late ui.PathMetric pathMetric;
  double totalPathLength = 0.0;

  @override
  void initState() {
    super.initState();
    _initPath();
    
    glowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    dotGlowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    dotGlowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: dotGlowController,
      curve: Curves.easeInOut,
    ));
    
    demoController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    
    demoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: demoController,
      curve: Curves.easeInOut,
    ))..addListener(() {
      if (isDemoMode) {
        _updateDemoProgress(demoAnimation.value);
      }
    });
    
    demoController.addStatusListener((status) {
      if (status == AnimationStatus.completed && isDemoMode) {
        // Wait 1 second after demo completes, then reset
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _reset();
          }
        });
      }
    });
  }

  void _initPath() {
    // Original dimensions from the SVG
    const double originalWidth = 800.0;
    const double originalHeight = 920.0;
    
    final Path rawPath = Path()
      ..moveTo(531.941, 451)
      ..cubicTo(546.838, 475.324, 572.944, 529.585, 562.665, 570)
      ..cubicTo(505.686, 570, 362.679, 570, 303.465, 570)
      ..cubicTo(244.252, 570, 215.762, 536.882, 249.279, 451);

    final Matrix4 matrix4 = Matrix4.identity()
      ..scale(widget.width / originalWidth, widget.height / originalHeight);

    letterPath = rawPath.transform(matrix4.storage);
    
    // Set nuqta/dot position using the same scaling
    // Adjusted to be slightly higher to match the reference image
    nuqtaPosition = Offset(
      404 * (widget.width / originalWidth),
      628 * (widget.height / originalHeight),  // Moved up from 637 to 628
    );
    
    // Get path metrics
    final metrics = letterPath.computeMetrics();
    pathMetric = metrics.first;
    totalPathLength = pathMetric.length;
    
    // Set initial dot position
    _updateDotPosition(0.0);
  }

  void _startDemo() {
    if (isDemoMode) return; // Prevent starting demo if already running
    
    _reset();
    setState(() {
      isDemoMode = true;
      isTracing = true;
    });
    demoController.forward(from: 0.0);
  }

  void _updateDemoProgress(double animationValue) {
    if (animationValue <= 0.8) {
      // First 80% of animation (2.4 seconds): trace the main path
      double pathAnimProgress = animationValue / 0.8;
      _updateDotPosition(pathAnimProgress);
    } else {
      // Last 20% of animation (0.6 seconds): click the dot
      if (!isPathComplete) {
        setState(() {
          isPathComplete = true;
          pathProgress = 1.0;
          currentDotPosition = null;
        });
      }
      
      // Fill the dot at the very end
      if (animationValue >= 0.95 && !isDotClicked) {
        setState(() {
          isDotClicked = true;
        });
        // Don't call onComplete during demo mode
      }
    }
  }

  void _updateDotPosition(double progress) {
    final distance = totalPathLength * progress;
    final tangent = pathMetric.getTangentForOffset(distance);
    if (tangent != null) {
      setState(() {
        currentDotPosition = tangent.position;
        pathProgress = progress;
        
        // Check if path is complete (when we reach 90% or more)
        if (progress >= 0.9 && !isPathComplete && !isDemoMode) {
          isPathComplete = true;
          pathProgress = 1.0; // Ensure full path is drawn
          currentDotPosition = null; // Hide the red ball
        }
      });
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (isPathComplete || isDemoMode) return;
    
    final localPosition = details.localPosition;
    
    // Check if touch is near the current dot
    if (currentDotPosition != null) {
      final distance = (localPosition - currentDotPosition!).distance;
      if (distance <= 30) { // Touch tolerance
        setState(() {
          isDragging = true;
          isTracing = true;
        });
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!isDragging || isPathComplete || isDemoMode) return;
    
    final localPosition = details.localPosition;
    
    // Find the closest point on the path and its progress
    double? closestProgress = _findClosestProgressOnPath(localPosition);
    
    if (closestProgress != null) {
      // Only allow forward progress (no going backwards)
      // Allow larger jumps near the end to ensure completion
      final maxJump = pathProgress > 0.8 ? 0.3 : 0.2;
      if (closestProgress > pathProgress && closestProgress - pathProgress < maxJump) {
        _updateDotPosition(closestProgress);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
      
      // If we're very close to the end, just complete it
      if (pathProgress >= 0.85 && !isPathComplete) {
        _updateDotPosition(1.0);
      }
    });
  }

  double? _findClosestProgressOnPath(Offset touchPoint) {
    double minDistance = double.infinity;
    double? closestProgress;
    
    // Sample points along the path to find the closest one
    // Expand search range near the end
    final double searchStart = math.max(0, pathProgress - 0.05).toDouble();
    final double searchEnd = math.min(1.0, pathProgress + (pathProgress > 0.8 ? 0.25 : 0.15)).toDouble();
    
    for (double progress = searchStart; 
         progress <= searchEnd; 
         progress += 0.005) {
      
      final distance = totalPathLength * progress;
      final tangent = pathMetric.getTangentForOffset(distance);
      
      if (tangent != null) {
        final pointOnPath = tangent.position;
        final dist = (touchPoint - pointOnPath).distance;
        
        if (dist < minDistance && dist < 50) { // Increased tolerance
          minDistance = dist;
          closestProgress = progress;
        }
      }
    }
    
    // If we're near the end and can't find a close point, just complete the path
    if (closestProgress == null && pathProgress > 0.85) {
      return 1.0;
    }
    
    return closestProgress;
  }

  void _reset() {
    demoController.stop();
    setState(() {
      pathProgress = 0.0;
      isTracing = false;
      isDragging = false;
      isPathComplete = false;
      isDotClicked = false;
      isDemoMode = false;
      _updateDotPosition(0.0);
    });
    // Notify parent that exercise is no longer complete
    widget.onComplete?.call(false);
  }

  @override
  void dispose() {
    glowController.dispose();
    dotGlowController.dispose();
    demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: isDemoMode ? null : _handlePanStart,
      onPanUpdate: isDemoMode ? null : _handlePanUpdate,
      onPanEnd: isDemoMode ? null : _handlePanEnd,
      child: Stack(
        children: [
          // Background
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: Image.asset(
              'assets/images/letters/BaLine.png',
              fit: BoxFit.contain,
            ),
          ),

          // Tracing path
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              painter: TracingPainter(
                path: letterPath,
                progress: isPathComplete ? 1.0 : pathProgress,
                strokeWidth: 20.0,
                color: Color(0xFF4d382d),
              ),
            ),
          ),

          // Nuqta/Dot with yellow glow when path is complete
          if (isPathComplete)
            Positioned(
              left: nuqtaPosition.dx - 15,
              top: nuqtaPosition.dy - 15,
              child: GestureDetector(
                onTap: isDemoMode ? null : () {
                  if (!isDotClicked) {
                    setState(() {
                      isDotClicked = true;
                    });
                    widget.onComplete?.call(true);
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: dotGlowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDotClicked 
                              ? Color(0xFF4d382d) 
                              : Colors.transparent,
                          border: Border.all(
                            color: isDotClicked ? Colors.transparent : Colors.yellow,
                            width: isDotClicked ? 0 : 2,
                          ),
                          boxShadow: [
                            if (!isDotClicked) ...[
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.25 + 0.1 * dotGlowAnimation.value),
                                blurRadius: 6 + 3 * dotGlowAnimation.value,
                                spreadRadius: 1,
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Moving red ball (only show if not complete)
          if (currentDotPosition != null && !isPathComplete)
            Positioned(
              left: currentDotPosition!.dx - 15,
              top: currentDotPosition!.dy - 15,
              child: AnimatedBuilder(
                animation: glowController,
                builder: (context, child) {
                  return Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDragging || isDemoMode ? Color(0xFF4d382d) : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDragging || isDemoMode ? Color(0xFF4d382d) : Colors.red)
                              .withOpacity(0.6 + 0.2 * glowController.value),
                          blurRadius: 10 + 5 * glowController.value,
                          spreadRadius: 2 + 2 * glowController.value,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Progress indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Progress: ${isPathComplete ? 100 : (pathProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4d382d),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Spacer(),
                  if (isDotClicked)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // Instructions
          if (!isTracing && !isPathComplete && !isDemoMode)
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Hold and drag the red dot along the path',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4d382d),
                  ),
                ),
              ),
            ),
          
          // Demo mode indicator
          if (isDemoMode)
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Demo Mode - Watch and learn!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Buttons row - reset and demo
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Demo/Eye button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDemoMode ? Colors.blue : (isDotClicked ? Colors.grey : Color(0xFF9e8b7e)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (isDemoMode || isDotClicked) ? null : _startDemo,
                      borderRadius: BorderRadius.circular(22),
                      child: Center(
                        child: Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Reset button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(0xFF9e8b7e),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _reset,
                      borderRadius: BorderRadius.circular(22),
                      child: Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TracingPainter extends CustomPainter {
  final Path path;
  final double progress;
  final double strokeWidth;
  final Color color;

  TracingPainter({
    required this.path,
    required this.progress,
    this.strokeWidth = 20.0,
    this.color = const Color(0xFF4d382d),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final metric in metrics) {
      final drawPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(drawPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}