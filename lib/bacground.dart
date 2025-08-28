import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredBackgroundApp extends StatelessWidget {
  const BlurredBackgroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Use image from assets
          Image.asset(
            "assets/images/background.jpg", // 👈 replace with your asset path
            fit: BoxFit.cover,
          ),

          // Apply blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.grey, // add transparency
            ),
          ),

          // Centered text
         const Center(
            child:  Text(
              "Fishing Guide App 🎣",
              style:  TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
