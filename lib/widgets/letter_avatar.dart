import 'package:flutter/material.dart';

class LetterAvatar extends StatelessWidget {
  const LetterAvatar({
    super.key,
    required this.username,
    required this.background,
    required this.foreground,
    this.size = 40,
  });

  final String username;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = username.isEmpty ? '?' : username[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: foreground,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
