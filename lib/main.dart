import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'providers/schedule_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(255, 63, 81, 181); // indigo
    final accent = const Color.fromARGB(255, 98, 0, 234); // deep purple
    final danger = const Color.fromARGB(255, 230, 74, 25); // orange red

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Timbres Escuela',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
            primary: primary,
            secondary: accent,
            error: danger,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          floatingActionButtonTheme:
              FloatingActionButtonThemeData(backgroundColor: accent),
        ),
        home: const SplashWrapper(),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade y slide
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Rebote de la campana
    _bounceAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Después de 3 segundos, navegamos a HomeScreen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
    backgroundColor: Colors.white,
    body: Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _bounceAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICONO
                Image.asset(
                  'assets/icons/manager_bell_icon.png',
                  width: 120,
                ),

                const SizedBox(height: 20),

                // TÍTULO
                const Text(
                  'Manager Bell',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1F2F),
                  ),
                ),

                const SizedBox(height: 6),

                // SUBTÍTULO
                const Text(
                  'by: Yeison A.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // 🔵 TRES PUNTOS ANIMADOS
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    int dotCount = (value * 3).floor();

                    String dots = '.' * dotCount;

                    return Text(
                      dots,
                      style: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF0F1F2F),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                  onEnd: () {
                    // Repite la animación en bucle
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
