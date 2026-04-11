import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/live_service.dart';
import '../../services/webrtc_service.dart';
import '../../models/live_model.dart';
import '../../models/chat_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/app_constants.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/user_avatar.dart';
import '../main_shell.dart';

class LiveScreen extends StatefulWidget {
  final String liveId;
  final bool isHost;
  const LiveScreen({super.key, required this.liveId, this.isHost = false});
  @override State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _webrtc = WebRTCService();
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _micOn = true, _handRaised = false;
  String _myRole = AppConstants.roleAudience;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    // Request mic permission first
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied && mounted) {
      AppHelpers.showSnackBar(context,
        'Microphone permission required to speak on stage.', isError: true);
    }
    await _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await LiveService.incrementViewer(widget.liveId);
    if (widget.isHost) {
      setState(() => _myRole = AppConstants.roleHost);
      await _webrtc.initialize();
    }
    LiveService.getLiveSession(widget.liveId).listen((live) {
      if (live == null || !mounted) return;
      if (live.speakers.contains(uid) && _myRole == AppConstants.roleAudience) {
        setState(() => _myRole = AppConstants.roleSpeaker);
        _webrtc.initialize();
      }
      if (live.mutedSpeakers.contains(uid)) {
        _webrtc.forceMute();
        if (mounted) setState(() => _micOn = false);
      }
    });
  }

  @override
  void dispose() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    LiveService.decrementViewer(widget.liveId);
    LiveService.clearRequest(widget.liveId, uid);
    _webrtc.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _endLive() async {
    final ok = await AppHelpers.showConfirmDialog(context,
      title: 'End Live?',
      message: 'The session will end for everyone.',
      confirmText: 'End Live', isDestructive: true);
    if (!ok || !mounted) return;
    await LiveService.endLive(widget.liveId);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  Future<void> _shareLive() async {
    final link = 'https://synexlive.page.link/live?id=${widget.liveId}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      AppHelpers.showSnackBar(context, 'Live link copied! Share it with friends.');
    }
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final auth = context.read<AuthService>();
    final userName = auth.currentUser?.name ?? firebaseUser.displayName ?? 'User';
    final userPhoto = auth.currentUser?.photoUrl ?? firebaseUser.photoURL;
    _chatCtrl.clear();
    await LiveService.sendChat(
      liveId: widget.liveId,
      userId: firebaseUser.uid,
      userName: userName,
      userPhotoUrl: userPhoto,
      message: text,
      isHost: widget.isHost,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Live Options',
              style: TextStyle(color: AppTheme.textPri, fontSize: 16, fontWeight: FontWeight.w700))),
          const Divider(color: AppTheme.border, height: 1),

          // Share Live Link
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.cyan.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.link_rounded, color: AppTheme.cyan, size: 20)),
            title: const Text('Share Live Link', style: TextStyle(color: AppTheme.textPri, fontSize: 14)),
            subtitle: const Text('Copy link to invite viewers', style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
            onTap: () { Navigator.pop(context); _shareLive(); },
          ),

          // Screen Share (host only)
          if (widget.isHost)
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.screen_share_outlined, color: AppTheme.primary, size: 20)),
              title: const Text('Screen Share', style: TextStyle(color: AppTheme.textPri, fontSize: 14)),
              subtitle: const Text('Share your screen with audience', style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                AppHelpers.showSnackBar(context, 'Screen share coming soon!');
              },
            ),

          // End Live (host only)
          if (widget.isHost)
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.stop_circle_outlined, color: AppTheme.danger, size: 20)),
              title: const Text('End Live', style: TextStyle(color: AppTheme.danger, fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('End session for everyone', style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
              onTap: () { Navigator.pop(context); _endLive(); },
            ),

          // Leave (viewer only)
          if (!widget.isHost)
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.exit_to_app_rounded, color: AppTheme.danger, size: 20)),
              title: const Text('Leave Session', style: TextStyle(color: AppTheme.danger, fontSize: 14)),
              onTap: () { Navigator.pop(context); Navigator.pop(context); },
            ),

          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<LiveModel?>(
      stream: LiveService.getLiveSession(widget.liveId),
      builder: (_, snap) {
        final live = snap.data;
        if (live == null) {
          return const Scaffold(backgroundColor: AppTheme.bgDark,
            body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)));
        }
        if (!live.isLive && !widget.isHost) {
          return Scaffold(
            backgroundColor: AppTheme.bgDark,
            body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tv_off_rounded, color: AppTheme.textSec, size: 60),
              const SizedBox(height: 16),
              const Text('Live session has ended',
                style: TextStyle(color: AppTheme.textPri, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go Home'),
                onPressed: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const MainShell()), (_) => false)),
            ])),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(child: Column(children: [
            _buildTopBar(live, context),
            _buildSpeakers(live, uid),
            const Divider(height: 1, color: AppTheme.border),
            Expanded(child: _buildChat(uid)),
            _buildBottomBar(live, uid),
          ])),
        );
      },
    );
  }

  Widget _buildTopBar(LiveModel live, BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    color: AppTheme.bg2,
    child: Row(children: [
      // Menu button top left
      IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppTheme.textPri, size: 22),
        onPressed: () => _showMenu(context),
        tooltip: 'Menu',
      ),

      // Live badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.liveRed, borderRadius: BorderRadius.circular(6)),
        child: const Text('LIVE',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),

      // Title + host
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(live.title,
          style: const TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(live.hostName,
          style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
      ])),

      // Viewer count
      Row(children: [
        const Icon(Icons.remove_red_eye_outlined, color: AppTheme.textSec, size: 14),
        const SizedBox(width: 4),
        Text(AppHelpers.formatCount(live.viewerCount),
          style: const TextStyle(color: AppTheme.textSec, fontSize: 12)),
      ]),
      const SizedBox(width: 4),
    ]),
  );

  Widget _buildSpeakers(LiveModel live, String uid) {
    final all = [live.hostId, ...live.speakers];
    return Container(
      padding: const EdgeInsets.all(10),
      child: Wrap(spacing: 8, runSpacing: 8, children: all.map((sid) {
        final isHostTile = sid == live.hostId;
        final isMuted = live.mutedSpeakers.contains(sid);
        return SizedBox(width: 72, child: Column(children: [
          Stack(alignment: Alignment.bottomRight, children: [
            UserAvatar(
              name: isHostTile ? live.hostName : 'Speaker',
              photoUrl: isHostTile ? live.hostPhotoUrl : null,
              size: 48,
              showBorder: isHostTile,
              borderColor: AppTheme.gold),
            if (isMuted)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                child: const Icon(Icons.mic_off, color: Colors.white, size: 9)),
          ]),
          const SizedBox(height: 3),
          Text(isHostTile ? '${live.hostName.split(' ')[0]} 馃憫' : 'Speaker',
            style: const TextStyle(color: AppTheme.textPri, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (widget.isHost && !isHostTile)
            Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => isMuted
                  ? LiveService.unmuteSpeaker(widget.liveId, sid)
                  : LiveService.muteSpeaker(widget.liveId, sid),
                child: Icon(isMuted ? Icons.mic : Icons.mic_off,
                  color: isMuted ? AppTheme.success : AppTheme.danger, size: 14)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => LiveService.removeSpeaker(widget.liveId, sid),
                child: const Icon(Icons.close, color: AppTheme.danger, size: 14)),
            ]),
        ]));
      }).toList()),
    );
  }

  Widget _buildChat(String uid) => StreamBuilder<List<ChatModel>>(
    stream: LiveService.getChatStream(widget.liveId),
    builder: (_, snap) {
      final chats = snap.data ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (chats.isEmpty) {
        return const Center(
          child: Text('No messages yet. Say hello! 馃憢',
            style: TextStyle(color: AppTheme.textSec, fontSize: 13)));
      }
      return ListView.builder(
        controller: _scrollCtrl,
        itemCount: chats.length,
        itemBuilder: (_, i) => ChatBubble(chat: chats[i], isMe: chats[i].userId == uid),
      );
    });

  Widget _buildBottomBar(LiveModel live, String uid) {
    final isSpeaker = _myRole == AppConstants.roleSpeaker || widget.isHost;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      color: AppTheme.bg2,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Chat input
        Row(children: [
          Expanded(child: TextField(
            controller: _chatCtrl,
            style: const TextStyle(color: AppTheme.textPri, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Write a message...',
              hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
              filled: true, fillColor: AppTheme.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _sendChat())),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendChat,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ]),
        const SizedBox(height: 10),

        // Action buttons
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Mic toggle (speakers only)
          if (isSpeaker)
            _actionBtn(
              _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              _micOn ? 'Mute' : 'Unmute',
              _micOn ? AppTheme.success : AppTheme.danger,
              () { _webrtc.toggleAudio(); setState(() => _micOn = !_micOn); }),

          // Raise hand (audience only)
          if (_myRole == AppConstants.roleAudience)
            StreamBuilder<String?>(
              stream: LiveService.getUserRequestStatus(widget.liveId, uid),
              builder: (_, snap) {
                final status = snap.data;
                String label = 'Raise Hand';
                Color color = AppTheme.cyan;
                if (status == 'pending') { label = 'Pending...'; color = AppTheme.textSec; }
                if (status == 'accepted') { label = 'Accepted!'; color = AppTheme.success; }
                if (status == 'rejected') { label = 'Rejected'; color = AppTheme.danger; }
                return _actionBtn(Icons.front_hand_outlined, label, color,
                  status == null ? () async {
                    final firebaseUser = FirebaseAuth.instance.currentUser;
                    if (firebaseUser == null) return;
                    final auth = context.read<AuthService>();
                    final userName = auth.currentUser?.name ?? firebaseUser.displayName ?? 'User';
                    final userPhoto = auth.currentUser?.photoUrl ?? firebaseUser.photoURL;
                    setState(() => _handRaised = true);
                    await LiveService.raiseHand(
                      liveId: widget.liveId, userId: uid,
                      userName: userName, userPhotoUrl: userPhoto);
                  } : null);
              }),

          // Audience count
          _actionBtn(Icons.people_outline_rounded, 'Audience', AppTheme.textSec, () {}),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback? onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ]));
}
