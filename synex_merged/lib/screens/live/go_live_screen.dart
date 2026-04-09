import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _permissionsGranted = camera.isGranted && mic.isGranted;
      });
    }
    // Auto-request if not granted
    if (!camera.isGranted || !mic.isGranted) {
      await _requestPermissions();
    }
    if (!notif.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _requestPermissions() async {
    final results = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    final cameraOk = results[Permission.camera]?.isGranted ?? false;
    final micOk = results[Permission.microphone]?.isGranted ?? false;

    if (mounted) {
      setState(() => _permissionsGranted = cameraOk && micOk);

      if (!cameraOk || !micOk) {
        AppHelpers.showSnackBar(
          context,
          'Camera aur Mic permission chahiye Live ke liye!',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _startLive() async {
    // Permission check before starting
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

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
    appBar: AppBar(
      backgroundColor: AppTheme.bg2,
      title: const Text('Live Start Karo'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _form, child: Column(children: [

        // Permission Banner
        if (!_permissionsGranted)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Camera & Mic permission required for Live',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
              TextButton(
                onPressed: _requestPermissions,
                child: const Text('Allow', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            ]),
          ),

        // Preview Box
        Container(height: 160, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.primary.withOpacity(0.3),
              AppTheme.liveRed.withOpacity(0.3),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.videocam_rounded,
              color: _permissionsGranted ? AppTheme.liveRed : AppTheme.textSec,
              size: 48),
            const SizedBox(height: 8),
            Text(
              _permissionsGranted ? 'Ready to go Live! 🔴' : 'Permission do pehle',
              style: TextStyle(
                color: _permissionsGranted ? AppTheme.liveRed : AppTheme.textSec,
                fontSize: 13,
              ),
            ),
          ]),
        ),

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

        // Rules Box
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live Session Rules',
              style: TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('- Max 6 speakers stage pe\n- Audience raise hand kar sakta hai\n- Mute, remove, ya block kar sakte ho\n- End Live dabane pe session khatam',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12, height: 1.6)),
          ]),
        ),

        const SizedBox(height: 28),
        CustomButton(
          label: _permissionsGranted ? 'Live Shuru Karo 🔴' : 'Permissions Allow Karo',
          isLoading: _loading,
          onPressed: _permissionsGranted ? _startLive : _requestPermissions,
          color: _permissionsGranted ? AppTheme.liveRed : Colors.orange,
        ),
      ])),
    )),
  );
}
