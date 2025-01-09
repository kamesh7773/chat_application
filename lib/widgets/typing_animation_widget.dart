import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final Color dotColor;
  final Color bubbleColor;
  final EdgeInsetsGeometry padding;

  const TypingIndicator({
    super.key,
    this.dotSize = 6.5,
    this.spacing = 6.5,
    this.dotColor = Colors.black,
    this.bubbleColor = const Color.fromARGB(255, 225, 247, 237),
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
  });

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _firstDotAnimation;
  late final Animation<double> _secondDotAnimation;
  late final Animation<double> _thirdDotAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _firstDotAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _secondDotAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.2, 0.8, curve: Curves.easeInOut)),
    );
    _thirdDotAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(_firstDotAnimation),
          _buildDot(_secondDotAnimation),
          _buildDot(_thirdDotAnimation),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double translateY = 10 * (0.5 - animation.value); // Start from bottom
        return Transform.translate(
          offset: Offset(0, translateY),
          child: child,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: widget.spacing / 4),
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: widget.dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
