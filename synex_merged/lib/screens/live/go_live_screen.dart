import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/live_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
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

    try {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      if (user == null) {
        AppHelpers.showSnackBar(context, 'Login karo pehle!', isError: true);
        setState(() => _loading = false);
        return;
      }

      final liveId = await LiveService.startLive(
        hostId: user.uid, hostName: user.name,
        hostPhotoUrl: user.photoUrl,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      if (!mounted) return;

      if (liveId == null) {
        AppHelpers.showSnackBar(context, 'Live start nahi hua. Internet check karo.', isError: true);
        setState(() => _loading = false);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => LiveScreen(liveId: liveId, isHost: true)));
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
        setState(() => _loading = false);
      }
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
        onPressed: () => Navigator.pop(context))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _form, child: Column(children: [
        // Preview banner
        Container(
          height: 160, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withOpacity(0.4), AppTheme.liveRed.withOpacity(0.4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.liveRed.withOpacity(0.4))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.videocam_rounded, color: AppTheme.liveRed, size: 52),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.liveRed, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Ready to go Live!', style: TextStyle(color: AppTheme.liveRed, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ])),
        const SizedBox(height: 24),

        // Title field
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Live Title *', style: TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPri),
            decoration: InputDecoration(
              hintText: 'Aaj kya stream kar rahe ho?',
              prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.textSec, size: 18)),
            validator: AppValidators.validateTitle),
        ]),
        const SizedBox(height: 14),

        // Description field
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Description (Optional)', style: TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppTheme.textPri),
            decoration: InputDecoration(
              hintText: 'Viewers ko batao is session ke baare mein',
              prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.description_outlined, color: AppTheme.textSec, size: 18)))),
        ]),
        const SizedBox(height: 16),

        // Rules box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live Session Rules', style: TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('- Max 6 speakers stage pe\n- Audience raise hand kar sakta hai\n- Mute, remove, ya block kar sakte ho\n- End Live dabane pe session khatam',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12, height: 1.6)),
          ])),
        const SizedBox(height: 28),

        // Go Live button
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _startLive,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.liveRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('ðŸ”´  Live Shuru Karo',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    )),
  );
}
