import 'package:flutter/material.dart';
import 'main.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _shadowColorAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2)
    );
    
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    // Color animation for text
    _colorAnimation = ColorTween(
      begin: Colors.blueAccent,
      end: Colors.deepOrangeAccent,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Separate color animation for shadow with built-in opacity
    _shadowColorAnimation = ColorTween(
      begin: Colors.blueAccent.withAlpha(180), // Equivalent to ~70% opacity
      end: Colors.deepOrangeAccent.withAlpha(180),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular blue animated border
                   const SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                    // Circular logo
                    ClipOval(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Animated "Samaki Log" text
                AnimatedBuilder(
                  animation: Listenable.merge([_colorAnimation, _shadowColorAnimation]),
                  builder: (context, child) {
                    return Text(
                      "Samaki Log",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _colorAnimation.value,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: _shadowColorAnimation.value!,
                            offset: const Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}