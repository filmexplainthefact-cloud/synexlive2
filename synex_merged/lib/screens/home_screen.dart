import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/live_service.dart';
import '../services/tournament_service.dart';
import '../models/live_model.dart';
import '../models/tournament_model.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/tournament_card.dart';
import '../widgets/user_avatar.dart';
import 'live/live_screen.dart';
import 'tournaments_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid  = auth.currentUserId ?? '';
    final user = auth.currentUser;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Welcome banner
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back ðŸ‘‹', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(user?.name ?? 'Player',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                _statChip(Icons.sports_esports, 'Matches', '0'),
                const SizedBox(width: 10),
                _statChip(Icons.emoji_events, 'Wins', '0'),
                const SizedBox(width: 10),
                _statChip(Icons.confirmation_num, 'Tickets', '0'),
              ]),
            ]),
            const Spacer(),
            UserAvatar(name: user?.name ?? 'P', photoUrl: user?.photoUrl, size: 56,
              showBorder: true, borderColor: AppTheme.cyan),
          ]),
        ),

        // Live Sessions section
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('LIVE SESSIONS', style: TextStyle(
              color: AppTheme.cyan, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppTheme.liveRed, shape: BoxShape.circle)),
          ]),
        ),
        StreamBuilder<List<LiveModel>>(
          stream: LiveService.getLiveSessions(),
          builder: (_, snap) {
            final lives = snap.data ?? [];
            if (lives.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border)),
                child: const Center(child: Text('Abhi koi live nahi hai\nPehle "Go Live" karo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSec, fontSize: 13))),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: lives.length,
                itemBuilder: (_, i) => _liveChip(context, lives[i], uid),
              ),
            );
          }),

        // Tournaments section
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('FEATURED TOURNAMENTS', style: TextStyle(
              color: AppTheme.cyan, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            GestureDetector(
              onTap: () {},
              child: const Text('Sab dekho', style: TextStyle(color: AppTheme.textSec, fontSize: 12))),
          ]),
        ),
        StreamBuilder<List<TournamentModel>>(
          stream: TournamentService.getTournaments(),
          builder: (_, snap) {
            final tournaments = (snap.data ?? []).take(3).toList();
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2)));
            }
            if (tournaments.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border)),
                child: const Center(child: Text('Koi tournament nahi hai',
                  style: TextStyle(color: AppTheme.textSec))));
            }
            return Column(children: tournaments.map((t) =>
              TournamentCard(
                tournament: t, isJoined: false,
                onTap: () {},
                onJoin: () {},
              )).toList());
          }),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _statChip(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: Colors.white70, size: 13),
    const SizedBox(width: 3),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  ]);

  Widget _liveChip(BuildContext context, LiveModel live, String uid) =>
    GestureDetector(
      onTap: () async {
        final blocked = await LiveService.isBlocked(live.id, uid);
        if (!context.mounted) return;
        if (blocked) {
          AppHelpers.showSnackBar(context, 'Aap block ho!', isError: true);
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => LiveScreen(liveId: live.id)));
      },
      child: Container(
        width: 160, margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.liveRed.withOpacity(0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(width: 7, height: 7,
              decoration: const BoxDecoration(color: AppTheme.liveRed, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('LIVE', style: TextStyle(color: AppTheme.liveRed, fontSize: 10, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text(live.title, style: const TextStyle(color: AppTheme.textPri, fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(live.hostName, style: const TextStyle(color: AppTheme.textSec, fontSize: 10)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.remove_red_eye_outlined, color: AppTheme.textSec, size: 11),
            const SizedBox(width: 3),
            Text(AppHelpers.formatCount(live.viewerCount),
              style: const TextStyle(color: AppTheme.textSec, fontSize: 10)),
          ]),
        ]),
      ),
    );
}
