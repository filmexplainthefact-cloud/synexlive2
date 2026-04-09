import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final err = await auth.signInWithEmail(email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;
    if (err != null) AppHelpers.showSnackBar(context, err, isError: true);
    else _goHome();
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthService>();
    final err = await auth.signInWithGoogle();
    if (!mounted) return;
    if (err != null) AppHelpers.showSnackBar(context, err, isError: true);
    else _goHome();
  }

  void _goHome() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(key: _form, child: Column(children: [
          const SizedBox(height: 60),
          // Logo
          Center(child: Column(children: [
            Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF00E5FF)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.cyan.withOpacity(0.3), blurRadius: 20)],
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 38)),
            const SizedBox(height: 12),
            const Text('SYNEX', style: TextStyle(
              color: AppTheme.cyan, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const Text('Gaming + Live Platform', style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
          ])),
          const SizedBox(height: 40),
          CustomTextField(controller: _emailCtrl, label: 'Email Address',
            hint: 'aapka@email.com', keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined, validator: AppValidators.validateEmail),
          const SizedBox(height: 14),
          CustomTextField(controller: _passCtrl, label: 'Password',
            hint: 'Password daalo', obscureText: _obscure,
            prefixIcon: Icons.lock_outline,
            validator: AppValidators.validatePassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSec, size: 18))),
          const SizedBox(height: 28),
          Consumer<AuthService>(builder: (_, auth, __) =>
            CustomButton(label: 'Sign In', isLoading: auth.isLoading, onPressed: _signIn)),
          const SizedBox(height: 16),
          Row(children: const [
            Expanded(child: Divider(color: AppTheme.border)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ya', style: TextStyle(color: AppTheme.textSec, fontSize: 12))),
            Expanded(child: Divider(color: AppTheme.border)),
          ]),
          const SizedBox(height: 16),
          Consumer<AuthService>(builder: (_, auth, __) =>
            CustomButton(
              label: 'Google se Login Karo', isLoading: false,
              onPressed: auth.isLoading ? null : _googleSignIn,
              variant: ButtonVariant.outlined, color: AppTheme.cyan,
              icon: Container(width: 18, height: 18,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Center(child: Text('G',
                  style: TextStyle(color: Color(0xFF4285F4), fontSize: 11, fontWeight: FontWeight.w800)))))),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Account nahi hai? ', style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text('Sign Up Karo',
                style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
          const SizedBox(height: 32),
        ])),
      )),
    );
  }
}
