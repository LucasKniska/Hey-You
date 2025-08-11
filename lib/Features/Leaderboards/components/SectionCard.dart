import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../../../Data/models/LeaderboardData.dart';


class LeaderboardTab extends StatelessWidget {
  final List<LBEntry> entries;
  final String currentUserId;
  final String valueLabel; // e.g., "matches" or "days" or ""
  final Color accent;

  /// If true, the list under the podium will include ranks 1–5.
  /// Default false: show ranks 4–5 only (avoids duplication with podium).
  final bool listIncludesTop3;

  const LeaderboardTab({
    super.key,
    required this.entries,
    required this.currentUserId,
    required this.valueLabel,
    required this.accent,
    this.listIncludesTop3 = true,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = topNNonZero(entries, 3);
    final top5 = topNNonZero(entries, 5);

    if (top3.isEmpty) {
      return _EmptyState(accent: accent);
    }

    // Decide which ranks to list under the podium
    final listStart = listIncludesTop3 ? 0 : top3.length.clamp(0, top5.length);
    final listItems = (listStart < top5.length) ? top5.sublist(listStart) : <LBEntry>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PodiumRow(
          items: top3,
          currentUserId: currentUserId,
          valueLabel: valueLabel,
        ),
        if (listItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CompactList(
            items: listItems,
            startRankOffset: listStart, // so ranks show correctly (4/5)
            currentUserId: currentUserId,
            valueLabel: valueLabel,
            accent: accent,
          ),
        ],
      ],
    );
  }
}

/// ---------- Responsive Podium (no overflow) ----------
class _PodiumRow extends StatelessWidget {
  final List<LBEntry> items; // top 3, non-zero
  final String currentUserId;
  final String valueLabel;
  const _PodiumRow({
    required this.items,
    required this.currentUserId,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Available width for the three tiles (+ 2 gaps of 10)
        final tileW = (constraints.maxWidth - 20) / 3;

        // Tallest tile height derived from width (keeps things responsive)
        final tallest = (tileW * 2).clamp(120.0, 180.0);
        final h1 = tallest;                // #1
        final h2 = tallest * 0.86;         // #2
        final h3 = tallest * 0.78;         // #3

        // 👉 This SizedBox bounds the row's height to the tallest tile
        return SizedBox(
          height: tallest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PedestalTile(
                  rank: 2,
                  entry: items.length > 1 ? items[1] : null,
                  isMe: items.length > 1 && items[1].id == currentUserId,
                  height: h2,
                  valueLabel: valueLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PedestalTile(
                  rank: 1,
                  entry: items.isNotEmpty ? items[0] : null,
                  isMe: items.isNotEmpty && items[0].id == currentUserId,
                  height: h1,
                  emphasize: true,
                  valueLabel: valueLabel,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: _PedestalTile(
                  rank: 3,
                  entry: items.length > 2 ? items[2] : null,
                  isMe: items.length > 2 && items[2].id == currentUserId,
                  height: h3,
                  valueLabel: valueLabel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single pedestal with a colored base (gold/silver/bronze) and the name printed on it.
class _PedestalTile extends StatelessWidget {
  final int rank; // 1..3
  final LBEntry? entry;
  final bool isMe;
  final double height;
  final bool emphasize;
  final String valueLabel;

  const _PedestalTile({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.height,
    required this.valueLabel,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final colors = _pedestalColors(rank);
    final youPill = isMe ? _YouPill(accent: colors.text) : const SizedBox.shrink();

    // The pedestal base height
    final baseH = (height * 0.32).clamp(32, 64).toDouble();
    final topH  = height - baseH;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: topH,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _MedalCircle(rank: rank),
                      const Spacer(),
                      youPill,
                    ],
                  ),
                  const Spacer(),
                  // Value
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatValue(entry!.value),
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: emphasize ? 24 : 22,
                        letterSpacing: 0.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (valueLabel.isNotEmpty)
                    Text(
                      valueLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Pedestal base (colored) with masked name printed on it
          Container(
            height: baseH,
            decoration: BoxDecoration(
              color: colors.base,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: colors.base.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  maskName(entry!.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact list for additional ranks (4–5 by default)
class _CompactList extends StatelessWidget {
  final List<LBEntry> items;
  final int startRankOffset; // 0 if including top3; 3 if showing 4–5
  final String currentUserId;
  final String valueLabel;
  final Color accent;

  const _CompactList({
    required this.items,
    required this.startRankOffset,
    required this.currentUserId,
    required this.valueLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: List.generate(items.length, (i) {
            final rank = startRankOffset + i + 1;
            final e = items[i];
            final isMe = e.id == currentUserId;
            return Column(
              children: [
                if (i != 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Divider(height: 1, color: Colors.grey[200]),
                  ),
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: _RankBadge(rank: rank),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          maskName(e.name),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isMe) _YouPill(accent: accent),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatValue(e.value),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (valueLabel.isNotEmpty)
                        Text(
                          valueLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// ---------- Small bits ----------
class _MedalCircle extends StatelessWidget {
  final int rank; // 1..3
  const _MedalCircle({required this.rank});

  @override
  Widget build(BuildContext context) {
    final c = _pedestalColors(rank);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.base,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.base.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: c.text,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (rank) {
      case 1: bg = const Color(0xFFFFD54F); fg = const Color(0xFF6D4C41); break;
      case 2: bg = const Color(0xFFCFD8DC); fg = const Color(0xFF37474F); break;
      case 3: bg = const Color(0xFFCD7F32); fg = Colors.white; break;
      default: bg = Colors.white; fg = Colors.black87;
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _YouPill extends StatelessWidget {
  final Color accent;
  const _YouPill({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'You',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accent;
  const _EmptyState({required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Text(
        'No results yet',
        style: TextStyle(
          color: Colors.black.withOpacity(0.5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// ---------- Helpers (public) ----------
String maskName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return name;
  if (parts.length == 1) return parts.first;
  final lastInitial = parts.last[0].toUpperCase();
  return '${parts.first} $lastInitial.';
}

List<LBEntry> topNNonZero(List<LBEntry> src, int n) {
  final sorted = [...src]..sort((a, b) => b.value.compareTo(a.value));
  return sorted.where((e) => (e.value is num) && (e.value as num) > 0).take(n).toList();
}

String formatValue(num v) =>
    (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);

class _PedestalPalette {
  final Color base;
  final Color text;
  const _PedestalPalette(this.base, this.text);
}


_PedestalPalette _pedestalColors(int rank) {
  switch (rank) {
    case 1: return const _PedestalPalette(Color(0xFFFFD54F), Color(0xFF8C5F51)); // gold
    case 2: return const _PedestalPalette(Color(0xFFCFD8DC), Color(0xFF37474F)); // silver
    case 3: return const _PedestalPalette(Color(0xFFC39365), Color(0xFF532D09));      // bronze
    default: return const _PedestalPalette(Colors.white, Colors.black87);
  }
}
