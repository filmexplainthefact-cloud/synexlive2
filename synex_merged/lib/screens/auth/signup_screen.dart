import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final err = await auth.signUpWithEmail(
      name: _nameCtrl.text, email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;
    if (err != null) AppHelpers.showSnackBar(context, err, isError: true);
    else Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(backgroundColor: AppTheme.bgDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context))),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Account Banao', style: TextStyle(color: AppTheme.textPri, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Gaming + Live platform pe join karo', style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
          const SizedBox(height: 28),
          CustomTextField(controller: _nameCtrl, label: 'Display Name', hint: 'Tera naam',
            prefixIcon: Icons.person_outline, validator: AppValidators.validateName),
          const SizedBox(height: 14),
          CustomTextField(controller: _emailCtrl, label: 'Email', hint: 'aapka@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined, validator: AppValidators.validateEmail),
          const SizedBox(height: 14),
          CustomTextField(controller: _passCtrl, label: 'Password', hint: 'Min 6 characters',
            obscureText: _obscure1, prefixIcon: Icons.lock_outline,
            validator: AppValidators.validatePassword,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure1 = !_obscure1),
              icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textSec, size: 18))),
          const SizedBox(height: 14),
          CustomTextField(controller: _confCtrl, label: 'Password Confirm Karo', hint: 'Dobara daalo',
            obscureText: _obscure2, prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            validator: (v) => AppValidators.validateConfirmPassword(v, _passCtrl.text),
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure2 = !_obscure2),
              icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textSec, size: 18))),
          const SizedBox(height: 32),
          Consumer<AuthService>(builder: (_, auth, __) =>
            CustomButton(label: 'Account Banao', isLoading: auth.isLoading, onPressed: _signUp)),
          const SizedBox(height: 20),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Account hai? ', style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Text('Sign In Karo',
                style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w700, fontSize: 13))),
          ])),
          const SizedBox(height: 32),
        ])),
      )),
    );
  }
}
