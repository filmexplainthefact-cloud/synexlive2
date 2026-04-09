import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Store header
      Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('Synex Store', style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('  Coupons, Tickets aur items kharido!',
            style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),

      // Tabs
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.card2, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: AppTheme.success, borderRadius: BorderRadius.circular(10)),
          labelColor: Colors.black,
          unselectedLabelColor: AppTheme.textSec,
          tabs: const [
            Tab(text: 'Coupons'),
            Tab(text: 'Tickets'),
            Tab(text: 'Mera Saman'),
          ],
        ),
      ),
      const SizedBox(height: 8),

      // Tab content
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _CouponTab(),
        _TicketTab(),
        _MyItemsTab(),
      ])),
    ]);
  }
}

class _CouponTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TournamentService.getStoreItems('coupons'),
      builder: (_, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }
        if (items.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_offer_outlined, color: AppTheme.textSec, size: 48),
            const SizedBox(height: 12),
            const Text('Abhi koi coupon nahi', style: TextStyle(color: AppTheme.textSec)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: items.length,
          itemBuilder: (_, i) => _StoreItemCard(item: items[i]),
        );
      },
    );
  }
}

class _TicketTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TournamentService.getStoreItems('tickets'),
      builder: (_, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }

        // Always show at least default ticket
        final displayItems = items.isNotEmpty ? items : [
          {'id': 'default_ticket', 'name': 'Tournament Ticket', 'price': 50,
           'description': 'Daily Ticket Tournament join karne ke liye', 'type': 'ticket'}
        ];

        return Column(children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.purple.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.confirmation_num, color: AppTheme.purple, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Tournament Ticket kharido - sirf ticket wale daily tournament mein join kar sakte hain!',
                style: TextStyle(color: AppTheme.textSec, fontSize: 11))),
            ]),
          ),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: displayItems.length,
            itemBuilder: (_, i) => _StoreItemCard(item: displayItems[i]),
          )),
        ]);
      },
    );
  }
}

class _MyItemsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId;
    if (uid == null) return const SizedBox();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TournamentService.getPurchases(uid),
      builder: (_, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2));
        }
        if (items.isEmpty) {
          return const Center(child: Text('Koi purchase nahi hua abhi',
            style: TextStyle(color: AppTheme.textSec)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border)),
              child: Row(children: [
                const Icon(Icons.inventory_2_outlined, color: AppTheme.textSec, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'] ?? '', style: const TextStyle(
                    color: AppTheme.textPri, fontWeight: FontWeight.w600)),
                  if (item['data'] != null)
                    Text(item['data'].toString(), style: const TextStyle(
                      color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
                Text('Rs.${item['price'] ?? 0}',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
              ]),
            );
          },
        );
      },
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _StoreItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppTheme.card2, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.confirmation_num_outlined, color: AppTheme.purple, size: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] ?? '', style: const TextStyle(
            color: AppTheme.textPri, fontSize: 14, fontWeight: FontWeight.w700)),
          if (item['description'] != null)
            Text(item['description'], style: const TextStyle(color: AppTheme.textSec, fontSize: 12)),
          if (item['discount'] != null)
            Text('Discount: ${item['discount']}', style: const TextStyle(color: AppTheme.success, fontSize: 11)),
        ])),
        const SizedBox(width: 10),
        Column(children: [
          Text('Rs.${item['price'] ?? 0}',
            style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _buy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.success, borderRadius: BorderRadius.circular(8)),
              child: const Text('Kharido', style: TextStyle(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
        ]),
      ]),
    );
  }

  Future<void> _buy(BuildContext context) async {
    final auth  = context.read<AuthService>();
    final uid   = auth.currentUserId;
    if (uid == null) return;

    final gamingData = await TournamentService.getUserGamingData(uid).first;
    final balance = gamingData['balance'] ?? 0;
    final tickets = gamingData['tickets'] ?? 0;

    final ok = await AppHelpers.showConfirmDialog(context,
      title: 'Purchase Confirm', message: '${item['name']} kharido Rs.${item['price']} mein?',
      confirmText: 'Kharido');
    if (!ok || !context.mounted) return;

    final err = await TournamentService.buyItem(
      uid: uid, item: item, balance: balance, tickets: tickets);

    if (!context.mounted) return;
    if (err != null) AppHelpers.showSnackBar(context, err, isError: true);
    else AppHelpers.showSnackBar(context, 'Purchase ho gaya!');
  }
}
