import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Layar modal pemilih genre (98 genre + pencarian).
class GenreFilterScreen extends StatefulWidget {
  const GenreFilterScreen({super.key, this.current});

  final GenreInfo? current;

  @override
  State<GenreFilterScreen> createState() => _GenreFilterScreenState();
}

/// Marker hasil: "Semua genre" (bukan pembatalan).
class GenreNone {
  const GenreNone();
}

class _GenreFilterScreenState extends State<GenreFilterScreen> {
  final _controller = TextEditingController();
  List<GenreInfo>? _genres;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final genres = await KomikuClient.instance.genres();
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  List<GenreInfo> get _filtered {
    final all = _genres ?? const <GenreInfo>[];
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  void _pop(Object? result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final current = widget.current;
    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: iosPhysics,
        slivers: [
          CupertinoSliverNavigationBar(
            middle: const Text('Filter Genre'),
            trailing: current != null
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Bersihkan',
                      style: TextStyle(fontSize: 15, color: ctx.accent),
                    ),
                    onPressed: () => _pop(const GenreNone()),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: 'Cari genre…',
              ),
            ),
          ),
          if (_error != null)
            SliverFillRemaining(
              child: EmptyState(
                icon: CupertinoIcons.tag,
                title: 'Gagal memuat genre',
                subtitle: 'Periksa koneksi internet lalu coba lagi.',
                onRetry: _load,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ctx.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ctx.separator.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    _row(
                      label: 'Semua Genre',
                      selected: current == null,
                      onTap: () => _pop(const GenreNone()),
                    ),
                    const _Divider(),
                    if (_genres == null)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    else if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Genre tidak ditemukan',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: ctx.muted),
                        ),
                      )
                    else
                      ..._filtered.map(
                        (g) => _row(
                          label: g.name,
                          trailing: g.count,
                          selected: current?.slug == g.slug,
                          onTap: () => _pop(g),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    String? trailing,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ctx = Ctx(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? ctx.accent : ctx.text,
                ),
              ),
            ),
            if (trailing != null && trailing.isNotEmpty)
              Text(trailing, style: TextStyle(fontSize: 12, color: ctx.muted)),
            if (selected)
              Icon(CupertinoIcons.checkmark, size: 14, color: ctx.accent),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Container(
      height: 0.6,
      margin: const EdgeInsets.only(left: 14),
      color: ctx.separator,
    );
  }
}
