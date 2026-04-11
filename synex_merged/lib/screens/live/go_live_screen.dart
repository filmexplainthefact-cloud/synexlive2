import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _uploadingBanner = false;
  File? _bannerFile;
  String? _bannerUrl;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final mic = await Permission.microphone.status;
    if (!mic.isGranted) {
      final result = await Permission.microphone.request();
      if (result.isDenied && mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Microphone Required',
          style: TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w700)),
        content: const Text(
          'Microphone access is required to speak during live sessions. Please allow it in settings.',
          style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: AppTheme.textSec))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); openAppSettings(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Open Settings')),
        ],
      ),
    );
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, imageQuality: 80, maxWidth: 1280);
    if (picked == null) return;

    setState(() { _bannerFile = File(picked.path); _uploadingBanner = true; });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final ref = FirebaseStorage.instance
        .ref('live_banners/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_bannerFile!);
      final url = await ref.getDownloadURL();
      setState(() { _bannerUrl = url; _uploadingBanner = false; });
    } catch (e) {
      setState(() { _bannerFile = null; _uploadingBanner = false; });
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Banner upload failed. Try again.', isError: true);
      }
    }
  }

  Future<void> _startLive() async {
    if (!_form.currentState!.validate()) return;

    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          AppHelpers.showSnackBar(context, 'Microphone permission required!', isError: true);
        }
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          AppHelpers.showSnackBar(context, 'Please login first!', isError: true);
          setState(() => _loading = false);
        }
        return;
      }

      final userName = auth.currentUser?.name ?? firebaseUser.displayName ?? 'User';
      final userPhoto = auth.currentUser?.photoUrl ?? firebaseUser.photoURL;

      final liveId = await LiveService.startLive(
        hostId: firebaseUser.uid,
        hostName: userName,
        hostPhotoUrl: _bannerUrl ?? userPhoto,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (liveId == null) {
        AppHelpers.showSnackBar(context,
          'Failed to start live. Check your internet.', isError: true);
      } else {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => LiveScreen(liveId: liveId, isHost: true)));
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bg2,
      title: const Text('Start Live'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        onPressed: () => Navigator.pop(context))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _form, child: Column(children: [

        // Banner picker
        GestureDetector(
          onTap: _uploadingBanner ? null : _pickBanner,
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _bannerUrl != null ? AppTheme.liveRed : AppTheme.border,
                width: _bannerUrl != null ? 2 : 1),
              image: _bannerFile != null
                ? DecorationImage(image: FileImage(_bannerFile!), fit: BoxFit.cover)
                : null,
              gradient: _bannerFile == null ? LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.4), AppTheme.liveRed.withOpacity(0.4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            ),
            child: _uploadingBanner
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _bannerFile != null
                ? Stack(children: [
                    Positioned(bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ]))),
                  ])
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 40),
                    SizedBox(height: 8),
                    Text('Tap to upload live banner',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Optional 鈥� Shows as thumbnail',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ]),
          )),
        if (_bannerUrl != null) ...[
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 14),
            SizedBox(width: 4),
            Text('Banner uploaded!', style: TextStyle(color: AppTheme.success, fontSize: 12)),
          ]),
        ],
        const SizedBox(height: 16),

        // Title
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Live Title *',
            style: TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'What are you streaming today?',
              prefixIcon: Icon(Icons.title_rounded, color: AppTheme.textSec, size: 18)),
            validator: AppValidators.validateTitle),
        ]),
        const SizedBox(height: 14),

        // Description
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Description (Optional)',
            style: TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl, maxLines: 3,
            style: const TextStyle(color: AppTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'Tell viewers about this session...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.description_outlined, color: AppTheme.textSec, size: 18)))),
        ]),
        const SizedBox(height: 16),

        // Rules
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, color: AppTheme.cyan, size: 16),
              SizedBox(width: 6),
              Text('Live Session Rules',
                style: TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 8),
            Text(
              '鈥� Max 6 speakers on stage\n鈥� Audience can raise hand to speak\n鈥� You can mute, remove or block users\n鈥� Tap End Live to close the session',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12, height: 1.7)),
          ])),
        const SizedBox(height: 28),

        // Go Live button
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            icon: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('馃敶', style: TextStyle(fontSize: 18)),
            label: Text(_loading ? 'Starting...' : 'Go Live',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: _loading || _uploadingBanner ? null : _startLive,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.liveRed,
              disabledBackgroundColor: AppTheme.liveRed.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ])),
    )),
  );
}
