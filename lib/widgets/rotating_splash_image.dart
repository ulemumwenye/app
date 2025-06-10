import 'package:flutter/material.dart';

class RotatingSplashImage extends StatefulWidget {
  final double size;

  const RotatingSplashImage({
    Key? key,
    this.size = 50.0,
  }) : super(key: key);

  @override
  State<RotatingSplashImage> createState() => _RotatingSplashImageState();
}

class _RotatingSplashImageState extends State<RotatingSplashImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Makes the animation repeat indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller, // The controller's value directly drives the turns
      child: Image.asset(
        'assets/placeholder.png', // Ensure this path is correct
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
