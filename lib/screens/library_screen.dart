


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/jellyfin_models.dart';
import '../services/jellyfin_api.dart';
import '../services/prefs.dart';
import '../services/core_manager.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selector_dialog.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _prefs = Prefs();
  final _api = JellyfinApi();
  final _scrollCtrl = ScrollController();

  final List<JfItem> _items = [];
  final Map<String, int> _downloading = {}; 

  int _nextIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  static const _pageSize = 24;

  String _serverUrl = '';
  String _token = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _boot();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    _serverUrl = await _prefs.serverUrl;
    _token = await _prefs.token;
    _userId = await _prefs.userId;
    _loadItems(refresh: true);
  }

  void _onScroll() {
    if (!_isLoading && _hasMore &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400) {
      _loadItems();
    }
  }

  Future<void> _loadItems({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (refresh) {
      _nextIndex = 0;
      _hasMore = true;
      _items.clear();
    }

    try {
      final result = await _api.getItems(
        _serverUrl, _token, _userId,
        recursive: true,
        includeItemTypes: 'Game',
        startIndex: _nextIndex,
        limit: _pageSize,
      );

      final newItems = result.items
          .where((item) => item.isGame && item.tags?.any((t) => t.toLowerCase() == 'pico-8') != true)
          .toList();

      setState(() {
        _items.addAll(newItems);
        _nextIndex += result.items.length;
        _hasMore = result.items.length >= _pageSize;
      });
    } catch (e) {
      _snack('ERROR: UPLINK_FAILURE [\$e]');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purgeAllCache() async {
    final cacheDir = await getTemporaryDirectory();
    final romsDir = Directory('${cacheDir.path}/roms');
    if (await romsDir.exists()) {
      await romsDir.delete(recursive: true);
      _snack('SYSTEM: ALL CACHED ROMS PURGED');
      setState(() {});
    }
  }

  Future<void> _deleteRom(JfItem item) async {
    final localFile = await _localRomFile(item);
    if (await localFile.exists()) {
      await localFile.delete();
      _snack('PURGED: LOCAL CACHE [${item.name}]');
      setState(() {});
    }
  }

  Future<void> _launchGame(JfItem item) async {
    final localFile = await _localRomFile(item);
    if (await localFile.exists()) {
      if (await localFile.length() > 1024) {
        _startEmulator(localFile.path, item);
        return;
      }
      await localFile.delete();
    }

    final downloadUrl = item.downloadUrl(_serverUrl);
    setState(() => _downloading[item.id] = -1);

    try {
      await _downloadRom(downloadUrl, localFile, (pct) {
        setState(() => _downloading[item.id] = pct);
      });
      _startEmulator(localFile.path, item);
    } catch (e) {
      _snack('ERROR: DOWNLOAD ABORTED [\$e]');
    } finally {
      setState(() => _downloading.remove(item.id));
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

  void _startEmulator(String romPath, JfItem item) {
    final ext = romPath.split('.').last;
    final corePath = (item.platformTag != null
        ? CoreManager.instance.corePathForPlatformTag(item.platformTag!)
        : null) ?? CoreManager.instance.corePathForExtension(ext);
    
    if (corePath == null) {
      _snack('ERROR: CORE NOT FOUND');
      return;
    }
    context.push('/emulator', extra: {
      'romPath': romPath,
      'corePath': corePath,
      'title': item.name,
      'itemId': item.id,
      'serverUrl': _serverUrl,
      'token': _token,
      'userId': _userId,
    });
  }

  Future<File> _localRomFile(JfItem item) async {
    final cacheDir = await getTemporaryDirectory();
    final ext = item.path?.split('.').last ?? 'rom';
    final safe = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9._\- ]'), '_');
    return File('${cacheDir.path}/roms/${item.id}/$safe.$ext');
  }

  Future<void> _downloadRom(String url, File dest, void Function(int) onProgress) async {
    await dest.parent.create(recursive: true);
    final request = http.Request('GET', Uri.parse(url));
    final streamed = await request.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) throw Exception('HTTP ${streamed.statusCode}');
    final total = streamed.contentLength ?? 0;
    var done = 0;
    final sink = dest.openWrite();
    onProgress(-1);
    await for (final chunk in streamed.stream) {
      sink.add(chunk);
      done += chunk.length;
      if (total > 0) onProgress((done * 100 ~/ total));
    }
    await sink.close();
  }

  Future<void> _logout() async {
    await _prefs.logout();
    if (mounted) context.go('/login');
  }

  int _spanCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 8;
    if (width >= 1200) return 6;
    if (width >= 800) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('LIBRARY'),
        actions: isSmall 
          ? [
              _StatusCounter(count: _items.length),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'sync') _loadItems(refresh: true);
                  if (val == 'cores') context.push('/cores');
                  if (val == 'purge') _purgeAllCache();
                  if (val == 'logout') _logout();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'sync', child: Text('SYNC')),
                  const PopupMenuItem(value: 'cores', child: Text('CORE MGR')),
                  const PopupMenuItem(value: 'purge', child: Text('PURGE CACHE', style: TextStyle(color: Colors.redAccent))),
                  const PopupMenuItem(value: 'logout', child: Text('LOGOUT', style: TextStyle(color: Color(0xFFFF5C00)))),
                ],
              ),
              _ThemeToggleButton(),
              const SizedBox(width: 8),
            ]
          : [
              _StatusCounter(count: _items.length),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _loadItems(refresh: true),
                tooltip: 'SYNC',
              ),
              IconButton(
                icon: const Icon(Icons.memory, size: 20),
                onPressed: () => context.push('/cores'),
                tooltip: 'CORE MGR',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
                onPressed: _purgeAllCache,
                tooltip: 'PURGE ALL CACHE',
              ),
              _ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.power_settings_new, size: 20, color: Color(0xFFFF5C00)),
                onPressed: _logout,
                tooltip: 'LOGOUT',
              ),
              const SizedBox(width: 12),
            ],
      ),
      body: Stack(
        children: [
          
          _LibraryBackground(isDark: isDark),

          
          _items.isEmpty && !_isLoading
              ? const Center(child: Text('NO RECORDS FOUND', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold, letterSpacing: 2)))
              : GridView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _spanCount(context),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _items.length + (_isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _items.length) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C00)));
                    }
                    return FutureBuilder<bool>(
                      future: _localRomFile(_items[i]).then((f) => f.exists()),
                      builder: (ctx, snapshot) {
                        return _NasaGameCard(
                          item: _items[i],
                          serverUrl: _serverUrl,
                          token: _token,
                          downloadProgress: _downloading[_items[i].id],
                          hasLocal: snapshot.data ?? false,
                          onTap: () => _launchGame(_items[i]),
                          onDelete: () => _deleteRom(_items[i]),
                        );
                      }
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _StatusCounter extends StatelessWidget {
  final int count;
  const _StatusCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'RECORDS: $count',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFF5C00)),
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

class _NasaGameCard extends StatefulWidget {
  final JfItem item;
  final String serverUrl;
  final String token;
  final int? downloadProgress;
  final bool hasLocal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NasaGameCard({
    required this.item, required this.serverUrl, required this.token,
    required this.downloadProgress, required this.hasLocal,
    required this.onTap, required this.onDelete,
  });

  @override
  State<_NasaGameCard> createState() => _NasaGameCardState();
}

class _NasaGameCardState extends State<_NasaGameCard> {
  bool _isFocused = false;

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rocket_launch, color: Color(0xFFFF5C00)),
              title: const Text('RE-DOWNLOAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              onTap: () { Navigator.pop(ctx); widget.onTap(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('PURGE LOCAL ROM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              onTap: () { Navigator.pop(ctx); widget.onDelete(); },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloading = widget.downloadProgress != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: InkWell(
        onTap: downloading ? null : widget.onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              if (_isFocused)
                BoxShadow(color: const Color(0xFFFF5C00).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
              else
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 6)),
            ],
            border: Border.all(
              color: _isFocused ? const Color(0xFFFF5C00) : theme.dividerColor.withOpacity(0.05),
              width: _isFocused ? 3 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              
              CachedNetworkImage(
                imageUrl: widget.item.posterUrl(widget.serverUrl, widget.token),
                fit: BoxFit.cover,
                httpHeaders: {'Authorization': 'MediaBrowser Token="${widget.token}"'},
                placeholder: (_, __) => Container(color: Colors.black.withOpacity(0.05), child: const Center(child: Icon(Icons.image, color: Colors.black12))),
                errorWidget: (_, __, ___) => Container(color: Colors.black.withOpacity(0.05), child: const Center(child: Icon(Icons.broken_image, color: Colors.black12))),
              ),

              
              Positioned(
                top: 8, left: 8,
                child: GestureDetector(
                  onTap: () => _showContextMenu(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.more_vert, color: Colors.white70, size: 16),
                  ),
                ),
              ),
              if (widget.hasLocal)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF4ADE80), borderRadius: BorderRadius.circular(8)),
                    child: const Text('CACHED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                ),

              
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.item.platformTag != null)
                        Text(widget.item.platformTag!.toUpperCase(), style: const TextStyle(color: Color(0xFFFF5C00), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text(
                        downloading ? (widget.downloadProgress! < 0 ? 'SYNCING...' : 'SYNCING ${widget.downloadProgress}%') : widget.item.name.toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),

              
              if (downloading)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: widget.downloadProgress! < 0 ? null : widget.downloadProgress! / 100.0,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFFFF5C00),
                    minHeight: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryBackground extends StatelessWidget {
  final bool isDark;
  const _LibraryBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LibraryGridPainter(isDark: isDark),
      child: Container(),
    );
  }
}

class _LibraryGridPainter extends CustomPainter {
  final bool isDark;
  _LibraryGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.black).withOpacity(0.015)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 80) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 80) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

