import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String buttonText;
  final void Function()? onTap;

  const MyButton({
    super.key,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- HARDCODED COLORS ---
    const Color colorPrimary = Color(0xFF6B705C);    // Muted Olive
    const Color colorBackground = Color(0xFFF6EAD4); // Light Cream (used for text)

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : colorPrimary,
          borderRadius: BorderRadius.circular(12), // Slightly more professional radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              color: colorBackground,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}