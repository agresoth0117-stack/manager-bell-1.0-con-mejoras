import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Ajusta si tu ruta es distinta

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _blur;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // Controlador principal
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Fade-in
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Zoom suave
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Blur dinámico
    _blur = Tween<double>(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Movimiento vertical leve
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Iniciar animación
    _controller.forward();

    // Ir a HomeScreen al finalizar
    Future.delayed(const Duration(milliseconds: 2300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Fondo con blur animado
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F1F2F),
                      Color(0xFF193A6A),
                      Color(0xFF0F1F2F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blur.value,
                    sigmaY: _blur.value,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Logo animado
              Center(
                child: FadeTransition(
                  opacity: _opacity,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Image.asset(
                        "assets/icons/manager_bell_icon.png",
                        width: size.width * 0.45,
                      ),
                    ),
                  ),
                ),
              ),

              // Texto inferior
              Positioned(
                bottom: size.height * 0.08,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Text(
                    "by: Yeison A.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
