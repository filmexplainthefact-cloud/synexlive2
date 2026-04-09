import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/tournament_model.dart';

class TournamentService {
  static FirebaseDatabase get _db =>
    FirebaseDatabase.instanceFor(app: Firebase.app('gaming'));

  // Stream all active tournaments
  static Stream<List<TournamentModel>> getTournaments() {
    return _db.ref('tournaments').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      final list = map.entries
        .where((e) => (e.value as Map)['active'] != false)
        .map((e) => TournamentModel.fromMap(e.key, e.value as Map))
        .toList();
      list.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return 0;
      });
      return list;
    });
  }

  // Get user's joined tournaments
  static Stream<List<String>> getUserJoinedTournaments(String uid) {
    return _db.ref('users/$uid/joinedTournaments').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      return List<String>.from((data as Map).keys);
    });
  }

  // Join tournament
  static Future<String?> joinTournament({
    required String tournamentId,
    required String userId,
    required TournamentModel tournament,
    required num userBalance,
    required int userTickets,
  }) async {
    try {
      if (tournament.isFull) return 'Tournament full hai!';

      if (tournament.isTicket) {
        if (userTickets < 1) return 'Ticket nahi hai! Store se kharido.';
        // Deduct ticket
        await _db.ref('users/$userId/tickets').set(ServerValue.increment(-1));
      } else if (tournament.entryFee > 0) {
        if (userBalance < tournament.entryFee) return 'Balance kam hai!';
        await _db.ref('users/$userId/balance').set(ServerValue.increment(-tournament.entryFee));
      }

      // Register user
      await _db.ref('tournaments/$tournamentId/registered').set(ServerValue.increment(1));
      await _db.ref('tournaments/$tournamentId/players/$userId').set({
        'joinedAt': ServerValue.timestamp,
        'userId': userId,
      });
      await _db.ref('users/$userId/joinedTournaments/$tournamentId').set({
        'joinedAt': ServerValue.timestamp,
        'name': tournament.name,
      });

      return null; // success
    } catch (e) {
      return 'Join nahi ho saka: $e';
    }
  }

  // Get user gaming data (balance, tickets, etc.)
  static Stream<Map<String, dynamic>> getUserGamingData(String uid) {
    return _db.ref('users/$uid').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {'balance': 0, 'tickets': 0, 'level': 1, 'xp': 0};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  // Get spin history
  static Stream<List<Map<String, dynamic>>> getSpinHistory(String uid) {
    return _db.ref('spinHistory/$uid').orderByChild('timestamp').limitToLast(20).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    });
  }

  // Do spin
  static Future<Map<String, dynamic>> doSpin(String uid, num balance) async {
    if (balance < 10) return {'error': 'Balance kam hai! Min 10 chahiye.'};

    // Prizes
    final prizes = [
      {'label': '2 Cash', 'value': 2, 'type': 'cash'},
      {'label': '5 Cash', 'value': 5, 'type': 'cash'},
      {'label': '10 Cash', 'value': 10, 'type': 'cash'},
      {'label': '25 Cash', 'value': 25, 'type': 'cash'},
      {'label': '50 Cash', 'value': 50, 'type': 'cash'},
      {'label': 'Ticket', 'value': 1, 'type': 'ticket'},
      {'label': 'Better Luck!', 'value': 0, 'type': 'none'},
      {'label': '2 Cash', 'value': 2, 'type': 'cash'},
    ];

    // Weighted random
    final weights = [20, 20, 15, 15, 8, 5, 12, 5];
    int total = weights.reduce((a, b) => a + b);
    int rand = (DateTime.now().millisecondsSinceEpoch % total);
    int idx = 0;
    for (int i = 0; i < weights.length; i++) {
      rand -= weights[i];
      if (rand < 0) { idx = i; break; }
    }

    final prize = prizes[idx];

    // Deduct spin cost, add prize
    await _db.ref('users/$uid/balance').set(ServerValue.increment(-10));
    if (prize['type'] == 'cash') {
      await _db.ref('users/$uid/balance').set(ServerValue.increment(prize['value'] as int));
    } else if (prize['type'] == 'ticket') {
      await _db.ref('users/$uid/tickets').set(ServerValue.increment(1));
    }

    // Save history
    await _db.ref('spinHistory/$uid').push().set({
      'label': prize['label'],
      'type': prize['type'],
      'value': prize['value'],
      'timestamp': ServerValue.timestamp,
    });

    return {'prize': prize, 'index': idx};
  }

  // Get store items
  static Stream<List<Map<String, dynamic>>> getStoreItems(String category) {
    return _db.ref('store/$category').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        item['id'] = e.key;
        return item;
      }).toList();
    });
  }

  // Buy item
  static Future<String?> buyItem({
    required String uid, required Map<String, dynamic> item,
    required num balance, required int tickets,
  }) async {
    try {
      final price = item['price'] ?? 0;
      if (balance < price) return 'Balance kam hai!';

      await _db.ref('users/$uid/balance').set(ServerValue.increment(-price));
      await _db.ref('purchases/$uid').push().set({
        'itemId': item['id'],
        'name': item['name'],
        'price': price,
        'type': item['type'],
        'data': item['data'],
        'timestamp': ServerValue.timestamp,
      });
      return null;
    } catch (e) {
      return 'Purchase fail: $e';
    }
  }

  // Get purchases
  static Stream<List<Map<String, dynamic>>> getPurchases(String uid) {
    return _db.ref('purchases/$uid').orderByChild('timestamp').limitToLast(50).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    });
  }

  // Get payment history
  static Stream<List<Map<String, dynamic>>> getPaymentHistory(String uid) {
    return _db.ref('paymentHistory/$uid').orderByChild('timestamp').limitToLast(50).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    });
  }
}
