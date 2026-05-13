


import 'dart:io';
import 'package:flutter/material.dart';
import '../models/core_entry.dart';
import '../services/core_manager.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selector_dialog.dart';

class CoresScreen extends StatefulWidget {
  const CoresScreen({super.key});

  @override
  State<CoresScreen> createState() => _CoresScreenState();
}

class _CoresScreenState extends State<CoresScreen> {
  final Map<String, int?> _downloading = {};

  Future<void> _downloadCore(CoreEntry entry) async {
    setState(() => _downloading[entry.id] = -1);

    try {
      await CoreManager.instance.downloadCore(
        entry,
        onProgress: (pct) {
          if (mounted) setState(() => _downloading[entry.id] = pct);
        },
      );
      setState(() => _downloading.remove(entry.id));
      _snack('SYSTEM: ${entry.displayName.toUpperCase()} READY');
    } catch (e) {
      setState(() => _downloading.remove(entry.id));
      _snack('ERROR: DOWNLOAD FAILURE [\$e]');
    }
  }

  void _deleteCore(CoreEntry entry) {
    if (CoreManager.instance.deleteCore(entry)) {
      setState(() {});
      _snack('SYSTEM: ${entry.displayName.toUpperCase()} PURGED');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFFF5C00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('CORES'),
        actions: [
          _ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _CoresBackground(isDark: isDark),
          ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: coreCatalog.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _NasaCoreCard(
              entry: coreCatalog[i],
              installed: CoreManager.instance.isInstalled(coreCatalog[i]),
              downloadProgress: _downloading[coreCatalog[i].id],
              onDownload: () => _downloadCore(coreCatalog[i]),
              onDelete: () => _deleteCore(coreCatalog[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NasaCoreCard extends StatelessWidget {
  final CoreEntry entry;
  final bool installed;
  final int? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _NasaCoreCard({
    required this.entry, required this.installed, required this.downloadProgress,
    required this.onDownload, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.displayName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      installed ? 'STATUS: READY' : 'STATUS: NOT INSTALLED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: installed ? const Color(0xFF4ADE80) : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDownloading) ...[
                if (installed)
                  StatefulBuilder(
                    builder: (context, setIconState) {
                      bool isFocused = false;
                      return Focus(
                        onFocusChange: (f) => setIconState(() => isFocused = f),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFocused ? Colors.redAccent : Colors.transparent,
                              width: 2,
                            ),
                            color: isFocused ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: onDelete,
                            tooltip: 'PURGE',
                          ),
                        ),
                      );
                    }
                  ),
                const SizedBox(width: 8),
                _ActionButton(onPressed: onDownload, text: installed ? 'UPDATE' : 'INSTALL'),
              ],
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: downloadProgress! < 0 ? null : downloadProgress! / 100.0,
              backgroundColor: theme.dividerColor.withOpacity(0.05),
              color: const Color(0xFFFF5C00),
              minHeight: 6,
              borderRadius: BorderRadius.circular(100),
            ),
            const SizedBox(height: 8),
            Text(
              downloadProgress! < 0 ? 'EXTRACTING RESOURCES...' : 'DOWNLOADING DATA: $downloadProgress%',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFF5C00)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  const _ActionButton({required this.onPressed, required this.text});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isFocused ? const Color(0xFFFF5C00) : Colors.transparent,
              width: _isFocused ? 2 : 0,
            ),
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 36),
            ),
            child: Text(widget.text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatefulWidget {
  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;
        return Focus(
          onFocusChange: (f) => setState(() => _isFocused = f),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isFocused ? const Color(0xFFFF5C00) : Colors.transparent,
                width: 2,
              ),
              color: _isFocused ? const Color(0xFFFF5C00).withOpacity(0.1) : Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
              onPressed: () => ThemeSelectorDialog.show(context),
            ),
          ),
        );
      },
    );
  }
}

class _CoresBackground extends StatelessWidget {
  final bool isDark;
  const _CoresBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CoresGridPainter(isDark: isDark),
      child: Container(),
    );
  }
}

class _CoresGridPainter extends CustomPainter {
  final bool isDark;
  _CoresGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.black).withOpacity(0.015)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 80) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 80) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

