import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../models/tournament_model.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/tournament_card.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});
  @override State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _filter = 'all';
  Set<String> _joinedIds = {};

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().currentUserId;
    if (uid != null) {
      TournamentService.getUserJoinedTournaments(uid).listen((ids) {
        if (mounted) setState(() => _joinedIds = ids.toSet());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter tabs
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterTab('all', 'Sab'),
            _filterTab('solo', 'Solo'),
            _filterTab('duo', 'Duo'),
            _filterTab('squad', 'Squad'),
            _filterTab('free', 'Free'),
            _filterTab('ticket', 'Ticket'),
          ]),
        ),
      ),

      // Tournaments list
      Expanded(child: StreamBuilder<List<TournamentModel>>(
        stream: TournamentService.getTournaments(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
          }
          if (snap.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, color: AppTheme.textSec, size: 48),
              const SizedBox(height: 12),
              const Text('Connection error', style: TextStyle(color: AppTheme.textSec)),
            ]));
          }
          var list = snap.data ?? [];
          // Apply filter
          if (_filter == 'free') list = list.where((t) => t.entryFee == 0 && t.entryType != 'ticket').toList();
          else if (_filter == 'ticket') list = list.where((t) => t.isTicket).toList();
          else if (_filter != 'all') list = list.where((t) => t.mode == _filter).toList();

          if (list.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events_outlined, color: AppTheme.textSec, size: 56),
              const SizedBox(height: 12),
              const Text('Koi tournament nahi mila', style: TextStyle(color: AppTheme.textSec, fontSize: 15)),
            ]));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final t = list[i];
              final joined = _joinedIds.contains(t.id);
              return TournamentCard(
                tournament: t, isJoined: joined,
                onTap: () => _showDetail(context, t, joined),
                onJoin: () => _joinTournament(context, t),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _filterTab(String value, String label) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.cyan : AppTheme.border)),
        child: Text(label, style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textSec,
          fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showDetail(BuildContext context, TournamentModel t, bool joined) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: const TextStyle(color: AppTheme.textPri, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (t.description != null)
            Text(t.description!, style: const TextStyle(color: AppTheme.textSec, fontSize: 13)),
          const SizedBox(height: 16),
          _detailRow('Map', t.map),
          _detailRow('Mode', t.mode.toUpperCase()),
          _detailRow('Prize Pool', 'Rs.${AppHelpers.formatMoney(t.prizePool)}'),
          _detailRow('Entry Fee', t.isTicket ? 'Ticket' : t.entryFee == 0 ? 'FREE' : 'Rs.${t.entryFee}'),
          _detailRow('Players', '${t.registered}/${t.maxPlayers}'),
          const SizedBox(height: 20),
          if (!joined && !t.isFull)
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _joinTournament(context, t); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 48)),
              child: const Text('Join Karo', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSec, fontSize: 13)),
      Text(value, style: const TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Future<void> _joinTournament(BuildContext context, TournamentModel t) async {
    final auth = context.read<AuthService>();
    final uid  = auth.currentUserId;
    if (uid == null) return;

    final gamingData = await TournamentService.getUserGamingData(uid).first;
    final balance = gamingData['balance'] ?? 0;
    final tickets = gamingData['tickets'] ?? 0;

    final confirm = await AppHelpers.showConfirmDialog(context,
      title: 'Tournament Join Karo',
      message: t.isTicket
        ? 'Ek ticket use hogi. Join karo?'
        : t.entryFee == 0
          ? '${t.name} join karo? Free hai!'
          : 'Rs.${t.entryFee} lagega. Join karo?',
      confirmText: 'Join Karo');

    if (!confirm || !context.mounted) return;

   final err = await TournamentService.joinTournament(
  tournamentId: t.id, userId: uid,
  tournament: {
    'registered': t.registered,
    'maxPlayers': t.maxPlayers,
    'entryType': t.entryType ?? 'cash',
    'entryFee': t.entryFee,
    'name': t.name,
  },
  userBalance: balance, userTickets: tickets);

    if (!context.mounted) return;
    if (err != null) {
      AppHelpers.showSnackBar(context, err, isError: true);
    } else {
      AppHelpers.showSnackBar(context, '${t.name} join ho gaya!');
      setState(() => _joinedIds.add(t.id));
    }
  }
}
