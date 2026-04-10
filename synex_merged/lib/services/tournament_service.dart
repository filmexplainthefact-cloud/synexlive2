import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/tournament_model.dart';

class TournamentService {
  static FirebaseDatabase get _db {
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app('gaming'),
        databaseURL: 'https://k-upl-6a0db-default-rtdb.firebaseio.com',
      );
    } catch (e) {
      debugPrint('Gaming Firebase not initialized: $e');
      return FirebaseDatabase.instance;
    }
  }

  // Stream all active tournaments — returns TournamentModel list
  static Stream<List<TournamentModel>> getTournaments() {
    try {
      return _db.ref('tournaments').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <TournamentModel>[];
        final map = Map<String, dynamic>.from(data as Map);
        final list = map.entries
          .where((e) => e.value is Map && (e.value as Map)['active'] != false)
          .map((e) => TournamentModel.fromMap(e.key, e.value as Map))
          .toList();
        list.sort((a, b) {
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;
          return 0;
        });
        return list;
      });
    } catch (e) {
      debugPrint('getTournaments error: $e');
      return Stream.value([]);
    }
  }

  static Stream<List<String>> getUserJoinedTournaments(String uid) {
    try {
      return _db.ref('users/$uid/joinedTournaments').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <String>[];
        if (data is Map) return data.keys.map((e) => e.toString()).toList();
        return <String>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  static Future<String?> joinTournament({
    required String tournamentId,
    required String userId,
    required Map<String, dynamic> tournament,
    required num userBalance,
    required int userTickets,
  }) async {
    try {
      final registered = tournament['registered'] ?? 0;
      final maxPlayers = tournament['maxPlayers'] ?? 32;
      if (registered >= maxPlayers) return 'Tournament full hai!';
      final entryType = tournament['entryType'] ?? 'cash';
      final entryFee  = tournament['entryFee'] ?? 0;
      if (entryType == 'ticket') {
        if (userTickets < 1) return 'Ticket nahi hai! Store se kharido.';
        await _db.ref('users/$userId/tickets').set(ServerValue.increment(-1));
      } else if (entryFee > 0) {
        if (userBalance < entryFee) return 'Balance kam hai! Wallet mein add karo.';
        await _db.ref('users/$userId/balance').set(ServerValue.increment(-entryFee));
      }
      await _db.ref('tournaments/$tournamentId/registered').set(ServerValue.increment(1));
      await _db.ref('tournaments/$tournamentId/players/$userId').set({
        'joinedAt': ServerValue.timestamp, 'userId': userId,
      });
      await _db.ref('users/$userId/joinedTournaments/$tournamentId').set({
        'joinedAt': ServerValue.timestamp,
        'name': tournament['name'] ?? '',
      });
      return null;
    } catch (e) {
      return 'Join nahi ho saka: $e';
    }
  }

  static Stream<Map<String, dynamic>> getUserGamingData(String uid) {
    try {
      return _db.ref('users/$uid').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <String, dynamic>{'balance': 0, 'tickets': 0, 'level': 1, 'xp': 0};
        return Map<String, dynamic>.from(data as Map);
      });
    } catch (e) {
      return Stream.value({'balance': 0, 'tickets': 0, 'level': 1, 'xp': 0});
    }
  }

  static Future<Map<String, dynamic>> doSpin(String uid, num balance) async {
    if (balance < 10) return {'error': 'Balance kam hai! Min Rs.10 chahiye.'};
    try {
      final prizes = [
        {'label': 'Rs.2',  'value': 2,  'type': 'cash'},
        {'label': 'Rs.5',  'value': 5,  'type': 'cash'},
        {'label': 'Rs.10', 'value': 10, 'type': 'cash'},
        {'label': 'Rs.25', 'value': 25, 'type': 'cash'},
        {'label': 'Rs.50', 'value': 50, 'type': 'cash'},
        {'label': 'Ticket','value': 1,  'type': 'ticket'},
        {'label': 'Better Luck!', 'value': 0, 'type': 'none'},
        {'label': 'Rs.2',  'value': 2,  'type': 'cash'},
      ];
      final weights = [20, 20, 15, 15, 8, 5, 12, 5];
      int total = weights.reduce((a, b) => a + b);
      int rand  = (DateTime.now().millisecondsSinceEpoch % total);
      int idx   = 0;
      for (int i = 0; i < weights.length; i++) {
        rand -= weights[i];
        if (rand < 0) { idx = i; break; }
      }
      final prize = prizes[idx];
      await _db.ref('users/$uid/balance').set(ServerValue.increment(-10));
      if (prize['type'] == 'cash' && (prize['value'] as int) > 0) {
        await _db.ref('users/$uid/balance').set(ServerValue.increment(prize['value'] as int));
      } else if (prize['type'] == 'ticket') {
        await _db.ref('users/$uid/tickets').set(ServerValue.increment(1));
      }
      await _db.ref('spinHistory/$uid').push().set({
        'label': prize['label'], 'type': prize['type'],
        'value': prize['value'], 'timestamp': ServerValue.timestamp,
      });
      return {'prize': prize, 'index': idx};
    } catch (e) {
      return {'error': 'Spin fail: $e'};
    }
  }

  static Stream<List<Map<String, dynamic>>> getSpinHistory(String uid) {
    try {
      return _db.ref('spinHistory/$uid').limitToLast(20).onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <Map<String, dynamic>>[];
        final map = Map<String, dynamic>.from(data as Map);
        final list = map.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
        list.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        return list;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  static Stream<List<Map<String, dynamic>>> getStoreItems(String category) {
    try {
      return _db.ref('store/$category').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <Map<String, dynamic>>[];
        final map = Map<String, dynamic>.from(data as Map);
        return map.entries.map((e) {
          final item = Map<String, dynamic>.from(e.value as Map);
          item['id'] = e.key;
          return item;
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  static Future<String?> buyItem({
    required String uid,
    required Map<String, dynamic> item,
    required num balance,
    required int tickets,
  }) async {
    try {
      final price = item['price'] ?? 0;
      if (balance < price) return 'Balance kam hai! Rs.$price chahiye, aapke paas Rs.$balance hai.';
      await _db.ref('users/$uid/balance').set(ServerValue.increment(-(price as num)));
      await _db.ref('purchases/$uid').push().set({
        'itemId': item['id'] ?? '', 'name': item['name'] ?? '',
        'price': price, 'type': item['type'] ?? 'item',
        'data': item['data'] ?? '', 'timestamp': ServerValue.timestamp,
      });
      return null;
    } catch (e) {
      return 'Purchase fail: $e';
    }
  }

  static Stream<List<Map<String, dynamic>>> getPurchases(String uid) {
    try {
      return _db.ref('purchases/$uid').limitToLast(50).onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <Map<String, dynamic>>[];
        final map = Map<String, dynamic>.from(data as Map);
        final list = map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        list.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        return list;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  static Stream<List<Map<String, dynamic>>> getPaymentHistory(String uid) {
    try {
      return _db.ref('paymentHistory/$uid').limitToLast(50).onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <Map<String, dynamic>>[];
        final map = Map<String, dynamic>.from(data as Map);
        final list = map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        list.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        return list;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  static Future<void> addBalance(String uid, num amount) =>
    _db.ref('users/$uid/balance').set(ServerValue.increment(amount));
}
