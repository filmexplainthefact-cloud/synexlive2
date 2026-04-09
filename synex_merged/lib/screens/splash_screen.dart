import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'main_shell.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale, _fade, _glow;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ac, curve: Curves.elasticOut));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ac, curve: const Interval(0, 0.4, curve: Curves.easeIn)));
    _glow  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ac, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _ac.forward();
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => auth.isLoggedIn ? const MainShell() : const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    body: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [Color(0xFF071A36), Color(0xFF020D1E), Colors.black])),
      child: Center(child: AnimatedBuilder(
        animation: _ac,
        builder: (_, child) => FadeTransition(opacity: _fade,
          child: ScaleTransition(scale: _scale, child: child)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Animated logo
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF00E5FF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: AppTheme.cyan.withOpacity(0.4), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.sports_esports, color: Colors.white, size: 56)),
          const SizedBox(height: 28),
          const Text('SYNEX',
            style: TextStyle(
              color: AppTheme.cyan, fontSize: 44, fontWeight: FontWeight.w900,
              letterSpacing: 8)),
          const SizedBox(height: 8),
          const Text('GAMING + LIVE', style: TextStyle(
            color: AppTheme.textSec, fontSize: 13, letterSpacing: 5)),
          const SizedBox(height: 60),
          SizedBox(width: 180, child: LinearProgressIndicator(
            backgroundColor: AppTheme.border,
            color: AppTheme.cyan,
            minHeight: 2,
          )),
          const SizedBox(height: 12),
          const Text('Loading...', style: TextStyle(color: AppTheme.textSec, fontSize: 11, letterSpacing: 2)),
        ]),
      )),
    ),
  );
}
