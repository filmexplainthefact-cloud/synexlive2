import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/live_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'live_screen.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});
  @override State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _startLive() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    final liveId = await LiveService.startLive(
      hostId: user.uid, hostName: user.name,
      hostPhotoUrl: user.photoUrl,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (liveId == null) {
      AppHelpers.showSnackBar(context, 'Live start nahi hua. Dobara try karo.', isError: true);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => LiveScreen(liveId: liveId, isHost: true)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(backgroundColor: AppTheme.bg2, title: const Text('Live Start Karo'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _form, child: Column(children: [
        Container(height: 160, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.3), AppTheme.liveRed.withOpacity(0.3)]),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.videocam_rounded, color: AppTheme.textSec, size: 48),
            SizedBox(height: 8),
            Text('Preview yahan aayega', style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
          ])),
        const SizedBox(height: 24),
        CustomTextField(controller: _titleCtrl, label: 'Live Title *',
          hint: 'Aaj kya stream kar rahe ho?',
          prefixIcon: Icons.title_rounded, validator: AppValidators.validateTitle),
        const SizedBox(height: 14),
        CustomTextField(controller: _descCtrl, label: 'Description (Optional)',
          hint: 'Viewers ko batao is session ke baare mein',
          prefixIcon: Icons.description_outlined, maxLines: 3,
          textInputAction: TextInputAction.done),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live Session Rules', style: TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('- Max 6 speakers stage pe\n- Audience raise hand kar sakta hai\n- Mute, remove, ya block kar sakte ho\n- End Live dabane pe session khatam',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12, height: 1.6)),
          ])),
        const SizedBox(height: 28),
        CustomButton(label: 'Live Shuru Karo', isLoading: _loading,
          onPressed: _startLive, color: AppTheme.liveRed),
      ])),
    )),
  );
}
