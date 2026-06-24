import 'package:flutter/material.dart';

class EcoBackground extends StatelessWidget {
  final Widget child;

  const EcoBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFEAF7F2))),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/eco_pattern.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
