import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Fisika gulir ala iOS (bouncing) di semua platform.
const ScrollPhysics iosPhysics = BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
);

/// Judul seksi: "Peringkat Harian", "Terbaru", dsb.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: ctx.muted),
            const SizedBox(width: 7),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ctx.text,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ctx.accent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_compact_right,
                      size: 11,
                      color: ctx.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kondisi kosong / error dengan tombol ulang.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ctx.accent.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 26, color: ctx.accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ctx.text,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ctx.muted),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              CupertinoButton.filled(
                onPressed: onRetry,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Efek shimmer untuk kerangka pemuatan.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final base = ctx.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFE7E7EC);
        final hi = ctx.dark ? const Color(0xFF2A2A2E) : const Color(0xFFF6F6F9);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.8 + t * 2.6, -0.3),
              end: Alignment(-0.8 + t * 2.6, 0.3),
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

/// Chip filter satu baris.
class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ctx.accent : ctx.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ctx.accent : ctx.separator,
            width: 1,
          ),
          boxShadow: selected
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected
                    ? Colors.white
                    : ctx.muted.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ctx.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lencana peringkat (#1, #2, ...).
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: value <= 3
            ? ctx.accent
            : (ctx.dark ? const Color(0xFF3A3A3C) : Colors.black54).withValues(
                alpha: 0.85,
              ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Tag kecil (tipe, status) di dalam card.
class MiniTag extends StatelessWidget {
  const MiniTag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final c = color ?? ctx.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Huruf pertama (aman untuk rune non-ASCII).
String initialOf(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  return String.fromCharCode(t.runes.first).toUpperCase();
}

/// Waktu relatif ringkas.
String relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${t.day}/${t.month}/${t.year}';
}
