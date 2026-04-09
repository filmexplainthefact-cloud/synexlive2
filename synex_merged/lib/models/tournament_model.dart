class TournamentModel {
  final String id, name, map, mode;
  final String? thumbnail, description, entryType;
  final num entryFee, prizePool;
  final int maxPlayers, registered;
  final DateTime? startTime;
  final bool featured, active;

  const TournamentModel({
    required this.id, required this.name,
    this.map = 'Bermuda', this.mode = 'solo',
    this.thumbnail, this.description, this.entryType,
    this.entryFee = 0, this.prizePool = 0,
    this.maxPlayers = 32, this.registered = 0,
    this.startTime, this.featured = false, this.active = true,
  });

  factory TournamentModel.fromMap(String id, Map<dynamic, dynamic> d) {
    DateTime? st;
    if (d['startTime'] != null) {
      try { st = DateTime.fromMillisecondsSinceEpoch(d['startTime'] as int); } catch (_) {}
    }
    return TournamentModel(
      id: id, name: d['name'] ?? '',
      map: d['map'] ?? 'Bermuda',
      mode: d['mode'] ?? 'solo',
      thumbnail: d['thumbnail'],
      description: d['description'],
      entryType: d['entryType'],
      entryFee: d['entryFee'] ?? 0,
      prizePool: d['prizePool'] ?? 0,
      maxPlayers: d['maxPlayers'] ?? 32,
      registered: d['registered'] ?? 0,
      startTime: st,
      featured: d['featured'] ?? false,
      active: d['active'] ?? true,
    );
  }

  bool get isLive => startTime != null && startTime!.isBefore(DateTime.now());
  bool get isFull => registered >= maxPlayers;
  bool get isTicket => entryType == 'ticket';
  double get fillPercent => maxPlayers > 0 ? (registered / maxPlayers).clamp(0, 1) : 0;
}
