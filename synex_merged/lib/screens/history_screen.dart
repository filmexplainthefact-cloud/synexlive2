import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bg2,
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.cyan,
          unselectedLabelColor: AppTheme.textSec,
          indicatorColor: AppTheme.cyan,
          tabs: const [
            Tab(text: 'Payment'),
            Tab(text: 'Tournaments'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _PaymentHistory(uid: uid),
        _TournamentHistory(uid: uid),
        _PurchaseHistory(uid: uid),
      ]),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final String uid;
  const _PaymentHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TournamentService.getPaymentHistory(uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return _emptyState('Koi payment history nahi', Icons.payment);
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (_, i) => _historyTile(
            items[i]['type'] ?? 'Payment',
            'Rs.${items[i]['amount'] ?? 0}',
            items[i]['timestamp'],
            items[i]['status'] == 'success' ? AppTheme.success : AppTheme.danger),
        );
      },
    );
  }
}

class _TournamentHistory extends StatelessWidget {
  final String uid;
  const _TournamentHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: TournamentService.getUserJoinedTournaments(uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return _emptyState('Koi tournament join nahi kiya', Icons.emoji_events_outlined);
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (_, i) => _historyTile('Tournament', items[i], null, AppTheme.gold),
        );
      },
    );
  }
}

class _PurchaseHistory extends StatelessWidget {
  final String uid;
  const _PurchaseHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TournamentService.getPurchases(uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return _emptyState('Koi purchase nahi hua', Icons.shopping_bag_outlined);
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (_, i) => _historyTile(
            items[i]['name'] ?? 'Item',
            'Rs.${items[i]['price'] ?? 0}',
            items[i]['timestamp'],
            AppTheme.purple),
        );
      },
    );
  }
}

Widget _emptyState(String msg, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
  Icon(icon, color: AppTheme.textSec, size: 52),
  const SizedBox(height: 12),
  Text(msg, style: const TextStyle(color: AppTheme.textSec, fontSize: 14)),
]));

Widget _historyTile(String title, String value, dynamic ts, Color color) =>
  Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.card, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border)),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w600))),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        if (ts != null) Text(_timeAgo(ts), style: const TextStyle(color: AppTheme.textSec, fontSize: 10)),
      ]),
    ]),
  );

String _timeAgo(dynamic ts) {
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts as int);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  } catch (_) { return ''; }
}
