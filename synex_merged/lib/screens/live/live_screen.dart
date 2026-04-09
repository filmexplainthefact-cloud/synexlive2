import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _micOn = true, _videoOn = false, _handRaised = false;
  String _myRole = AppConstants.roleAudience;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    final uid  = auth.currentUserId ?? '';
    await LiveService.incrementViewer(widget.liveId);
    if (widget.isHost) {
      setState(() => _myRole = AppConstants.roleHost);
      await _webrtc.initialize();
    }
    LiveService.getLiveSession(widget.liveId).listen((live) {
      if (live == null) return;
      if (live.speakers.contains(uid) && _myRole == AppConstants.roleAudience) {
        setState(() => _myRole = AppConstants.roleSpeaker);
        _webrtc.initialize();
      }
      if (live.mutedSpeakers.contains(uid)) {
        _webrtc.forceMute(); setState(() => _micOn = false);
      }
    });
  }

  @override
  void dispose() {
    final auth = context.read<AuthService>();
    final uid  = auth.currentUserId ?? '';
    LiveService.decrementViewer(widget.liveId);
    LiveService.clearRequest(widget.liveId, uid);
    _webrtc.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _endLive() async {
    final ok = await AppHelpers.showConfirmDialog(context,
      title: 'Live End Karo?', message: 'Sabke liye session khatam ho jayega.',
      confirmText: 'End Karo', isDestructive: true);
    if (!ok || !mounted) return;
    await LiveService.endLive(widget.liveId);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser; if (user == null) return;
    _chatCtrl.clear();
    await LiveService.sendChat(
      liveId: widget.liveId, userId: user.uid,
      userName: user.name, userPhotoUrl: user.photoUrl,
      message: text, isHost: widget.isHost);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid  = auth.currentUserId ?? '';

    return StreamBuilder<LiveModel?>(
      stream: LiveService.getLiveSession(widget.liveId),
      builder: (_, snap) {
        final live = snap.data;
        if (live == null) return const Scaffold(backgroundColor: AppTheme.bgDark,
          body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)));
        if (!live.isLive && !widget.isHost) {
          return Scaffold(backgroundColor: AppTheme.bgDark,
            body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tv_off_rounded, color: AppTheme.textSec, size: 60),
              const SizedBox(height: 16),
              const Text('Live khatam ho gaya', style: TextStyle(color: AppTheme.textPri, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const MainShell()), (_) => false),
                child: const Text('Home pe Jao')),
            ])));
        }

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(child: Column(children: [
            _buildTopBar(live),
            _buildSpeakers(live, uid),
            const Divider(height: 1, color: AppTheme.border),
            Expanded(child: _buildChat(uid)),
            _buildBottomBar(live, uid),
          ])),
        );
      },
    );
  }

  Widget _buildTopBar(LiveModel live) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    color: AppTheme.bg2,
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.liveRed, borderRadius: BorderRadius.circular(6)),
        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(live.title, style: const TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(live.hostName, style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
      ])),
      Row(children: [
        const Icon(Icons.remove_red_eye_outlined, color: AppTheme.textSec, size: 14),
        const SizedBox(width: 4),
        Text(AppHelpers.formatCount(live.viewerCount), style: const TextStyle(color: AppTheme.textSec, fontSize: 12)),
      ]),
      const SizedBox(width: 8),
      TextButton(
        onPressed: widget.isHost ? _endLive : () => Navigator.pop(context),
        child: Text(widget.isHost ? 'End' : 'Leave',
          style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _buildSpeakers(LiveModel live, String uid) {
    final all = [live.hostId, ...live.speakers];
    return Container(padding: const EdgeInsets.all(10),
      child: Wrap(spacing: 8, runSpacing: 8, children: all.map((sid) {
        final isHostTile = sid == live.hostId;
        final isMuted = live.mutedSpeakers.contains(sid);
        return SizedBox(width: 72, child: Column(children: [
          Stack(alignment: Alignment.bottomRight, children: [
            UserAvatar(name: isHostTile ? live.hostName : 'Speaker',
              photoUrl: isHostTile ? live.hostPhotoUrl : null, size: 48,
              showBorder: isHostTile, borderColor: AppTheme.gold),
            if (isMuted) Container(padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
              child: const Icon(Icons.mic_off, color: Colors.white, size: 9)),
          ]),
          const SizedBox(height: 3),
          Text(isHostTile ? '${live.hostName.split(' ')[0]} ðŸ‘‘' : 'Speaker',
            style: const TextStyle(color: AppTheme.textPri, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (widget.isHost && !isHostTile) Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () => isMuted
              ? LiveService.unmuteSpeaker(widget.liveId, sid)
              : LiveService.muteSpeaker(widget.liveId, sid),
              child: Icon(isMuted ? Icons.mic : Icons.mic_off, color: isMuted ? AppTheme.success : AppTheme.danger, size: 14)),
            const SizedBox(width: 4),
            GestureDetector(onTap: () => LiveService.removeSpeaker(widget.liveId, sid),
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
        Row(children: [
          Expanded(child: TextField(controller: _chatCtrl,
            style: const TextStyle(color: AppTheme.textPri, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Message likhao...',
              hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
              filled: true, fillColor: AppTheme.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _sendChat())),
          const SizedBox(width: 8),
          GestureDetector(onTap: _sendChat,
            child: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          if (isSpeaker) _actionBtn(
            _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            _micOn ? 'Mute' : 'Unmute',
            _micOn ? AppTheme.success : AppTheme.danger,
            () { _webrtc.toggleAudio(); setState(() => _micOn = !_micOn); }),
          if (_myRole == AppConstants.roleAudience)
            StreamBuilder<String?>(
              stream: LiveService.getUserRequestStatus(widget.liveId, uid),
              builder: (_, snap) {
                final status = snap.data;
                String label = 'Raise Hand'; Color color = AppTheme.cyan;
                if (status == 'pending') { label = 'Pending...'; color = AppTheme.textSec; }
                if (status == 'accepted') { label = 'Accepted!'; color = AppTheme.success; }
                if (status == 'rejected') { label = 'Rejected'; color = AppTheme.danger; }
                return _actionBtn(Icons.front_hand_outlined, label, color,
                  status == null ? () async {
                    final user = context.read<AuthService>().currentUser;
                    if (user == null) return;
                    setState(() => _handRaised = true);
                    await LiveService.raiseHand(liveId: widget.liveId, userId: uid,
                      userName: user.name, userPhotoUrl: user.photoUrl);
                  } : null);
              }),
          _actionBtn(Icons.people_outline_rounded, 'Audience', AppTheme.textSec, () {}),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback? onTap) =>
    GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: color, fontSize: 10)),
    ]));
}
