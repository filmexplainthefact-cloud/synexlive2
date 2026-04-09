import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tournament_model.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const TournamentCard({
    super.key, required this.tournament, required this.isJoined,
    required this.onTap, required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tournament.featured ? AppTheme.gold.withOpacity(0.4) : AppTheme.border),
          boxShadow: tournament.featured ? [
            BoxShadow(color: AppTheme.gold.withOpacity(0.1), blurRadius: 12, spreadRadius: 1)
          ] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: tournament.thumbnail != null
                ? CachedNetworkImage(
                    imageUrl: tournament.thumbnail!,
                    height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _thumbPlaceholder())
                : _thumbPlaceholder(),
            ),
            // Status badges
            Positioned(top: 10, left: 10, child: Row(children: [
              if (isJoined) _badge('Joined', AppTheme.success),
              if (tournament.isLive) ...[
                const SizedBox(width: 6),
                _badge('LIVE', AppTheme.liveRed, icon: Icons.circle, iconSize: 8),
              ],
              if (tournament.featured) ...[
                const SizedBox(width: 6),
                _badge('Featured', AppTheme.gold),
              ],
            ])),
            if (tournament.isTicket)
              Positioned(top: 10, right: 10,
                child: _badge('Ticket Only', AppTheme.purple)),
          ]),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tournament.name,
                style: const TextStyle(color: AppTheme.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // Tags row
              Wrap(spacing: 6, runSpacing: 4, children: [
                _tag(Icons.map_outlined, tournament.map),
                _tag(Icons.people_outline, '${tournament.registered}/${tournament.maxPlayers}'),
                _tag(Icons.sports_esports, _modeLabel(tournament.mode)),
              ]),
              const SizedBox(height: 10),

              // Progress bar
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Players', style: TextStyle(color: AppTheme.textSec, fontSize: 11)),
                  Text('${tournament.registered}/${tournament.maxPlayers}',
                    style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tournament.fillPercent,
                    minHeight: 6,
                    backgroundColor: AppTheme.border,
                    color: tournament.isFull ? AppTheme.danger : AppTheme.cyan,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Footer
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.emoji_events, color: AppTheme.gold, size: 16),
                  const SizedBox(width: 4),
                  Text('${AppHelpers.formatMoney(tournament.prizePool)}',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
                Row(children: [
                  // Entry fee badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tournament.isTicket ? AppTheme.purple.withOpacity(0.15)
                        : tournament.entryFee == 0 ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tournament.isTicket ? AppTheme.purple
                          : tournament.entryFee == 0 ? AppTheme.success
                          : AppTheme.cyan),
                    ),
                    child: Text(
                      tournament.isTicket ? 'Ticket'
                        : tournament.entryFee == 0 ? 'FREE'
                        : 'Rs.${tournament.entryFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: tournament.isTicket ? AppTheme.purple
                          : tournament.entryFee == 0 ? AppTheme.success
                          : AppTheme.cyan,
                        fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Join button
                  GestureDetector(
                    onTap: (isJoined || tournament.isFull) ? null : onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isJoined ? null : LinearGradient(
                          colors: tournament.isFull
                            ? [AppTheme.textSec, AppTheme.textSec]
                            : tournament.isTicket
                              ? [AppTheme.purple, const Color(0xFF4A148C)]
                              : [AppTheme.primary, const Color(0xFF0D47A1)]),
                        color: isJoined ? AppTheme.success.withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isJoined ? Border.all(color: AppTheme.success) : null,
                      ),
                      child: Text(
                        isJoined ? 'Joined' : tournament.isFull ? 'Full' : 'Join Karo',
                        style: TextStyle(
                          color: isJoined ? AppTheme.success
                            : tournament.isFull ? AppTheme.textSec
                            : Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    height: 140, width: double.infinity,
    color: AppTheme.card2,
    child: const Center(child: Icon(Icons.sports_esports, color: AppTheme.textSec, size: 48)),
  );

  Widget _badge(String text, Color color, {IconData? icon, double iconSize = 10}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: color, size: iconSize), const SizedBox(width: 3)],
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );

  Widget _tag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.card2, borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.textSec, size: 11),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
    ]),
  );

  String _modeLabel(String mode) {
    switch (mode) {
      case 'duo':   return 'Duo';
      case 'squad': return 'Squad';
      default:      return 'Solo';
    }
  }
}
