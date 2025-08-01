import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double width;
  final double height;
  final int barCount;
  final double barWidth;
  final double spacing;

  const AudioVisualizerWidget({
    Key? key,
    required this.isPlaying,
    this.color = Colors.white,
    this.width = 100,
    this.height = 40,
    this.barCount = 5,
    this.barWidth = 3,
    this.spacing = 2,
  }) : super(key: key);

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    _animationController.repeat();
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isPlaying) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    _animationController.stop();
    for (var controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _barAnimations[index],
            builder: (context, child) {
              final barHeight = widget.isPlaying
                  ? widget.height * _barAnimations[index].value
                  : widget.height * 0.2;
              
              return Container(
                width: widget.barWidth,
                height: barHeight,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class CircularAudioVisualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;
  final int barCount;
  final double strokeWidth;

  const CircularAudioVisualizerWidget({
    Key? key,
    required this.isPlaying,
    this.color = Colors.white,
    this.size = 100,
    this.barCount = 20,
    this.strokeWidth = 3,
  }) : super(key: key);

  @override
  State<CircularAudioVisualizerWidget> createState() => _CircularAudioVisualizerWidgetState();
}

class _CircularAudioVisualizerWidgetState extends State<CircularAudioVisualizerWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );

    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 50)),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(CircularAudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    _rotationController.repeat();
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isPlaying) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    _rotationController.stop();
    for (var controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: CircularVisualizerPainter(
                barAnimations: _barAnimations,
                color: widget.color,
                strokeWidth: widget.strokeWidth,
                isPlaying: widget.isPlaying,
              ),
            ),
          );
        },
      ),
    );
  }
}

class CircularVisualizerPainter extends CustomPainter {
  final List<Animation<double>> barAnimations;
  final Color color;
  final double strokeWidth;
  final bool isPlaying;

  CircularVisualizerPainter({
    required this.barAnimations,
    required this.color,
    required this.strokeWidth,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barAnimations.length; i++) {
      final angle = (2 * math.pi / barAnimations.length) * i;
      final barHeight = isPlaying
          ? (radius * 0.3) * barAnimations[i].value
          : radius * 0.1;
      
      final startPoint = Offset(
        center.dx + (radius - barHeight) * math.cos(angle),
        center.dy + (radius - barHeight) * math.sin(angle),
      );
      
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PulseVisualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;
  final int pulseCount;

  const PulseVisualizerWidget({
    Key? key,
    required this.isPlaying,
    this.color = Colors.white,
    this.size = 60,
    this.pulseCount = 3,
  }) : super(key: key);

  @override
  State<PulseVisualizerWidget> createState() => _PulseVisualizerWidgetState();
}

class _PulseVisualizerWidgetState extends State<PulseVisualizerWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _pulseControllers;
  late List<Animation<double>> _pulseAnimations;

  @override
  void initState() {
    super.initState();
    _pulseControllers = List.generate(
      widget.pulseCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000),
        vsync: this,
      ),
    );

    _pulseAnimations = _pulseControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(PulseVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    for (int i = 0; i < _pulseControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted && widget.isPlaying) {
          _pulseControllers[i].repeat();
        }
      });
    }
  }

  void _stopAnimation() {
    for (var controller in _pulseControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (var controller in _pulseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: _pulseAnimations.asMap().entries.map((entry) {
          final index = entry.key;
          final animation = entry.value;
          
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                width: widget.size * animation.value,
                height: widget.size * animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 1.0 - animation.value),
                    width: 2,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
