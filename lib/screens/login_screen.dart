


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../services/jellyfin_api.dart';
import '../services/prefs.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selector_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _prefs = Prefs();
  final _api = JellyfinApi();

  late AnimationController _scanController;
  bool _useHttps = true;
  bool _passVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _prefs.serverUrl;
    if (saved.isNotEmpty && mounted) {
      setState(() {
        _useHttps = saved.startsWith('https');
        _serverCtrl.text = saved
            .replaceFirst('https://', '')
            .replaceFirst('http://', '');
      });
    }
  }

  Future<void> _doLogin() async {
    final host = _serverCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;

    if (host.isEmpty || user.isEmpty) {
      _snack('SYSTEM: FIELDS EMPTY');
      return;
    }

    final protocol = _useHttps ? 'https' : 'http';
    final serverUrl = '$protocol://$host';

    setState(() => _loading = true);

    try {
      final result = await _api.authenticate(serverUrl, user, pass);
      await _prefs.setServerUrl(serverUrl);
      await _prefs.setToken(result.accessToken);
      await _prefs.setUserId(result.user.id);
      if (mounted) context.go('/library');
    } catch (e) {
      if (mounted) _snack('ERROR: LOGIN TIMEOUT');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFFF5C00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final edgeOffset = isSmall ? 16.0 : 40.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          
          Positioned.fill(child: _ModernNasaBackground(isDark: isDark)),

          
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 16 : 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isSmall ? size.width * 0.9 : 400),
                child: _buildLoginCard(theme, isDark, isSmall),
              ),
            ),
          ),

          
          Positioned(
            top: edgeOffset, left: edgeOffset,
            child: _ThemeToggleButton(),
          ),

          
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: edgeOffset, right: edgeOffset,
                  child: _StatusTag(label: 'LOGIN', value: _loading ? 'SYNCING' : 'READY', active: true),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, child) {
                      return CustomPaint(painter: _ModernScanlinePainter(_scanController.value));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(ThemeData theme, bool isDark, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 24 : 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmall ? 24 : 48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C00),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/vantage.svg',
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VANTAGE',
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2, 
                      color: theme.textTheme.bodyLarge?.color
                    ),
                  ),
                  Text(
                    'Official jellyemu client.',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),

          
          _NasaField(
            label: 'SERVER HOST',
            controller: _serverCtrl,
            hint: '0.0.0.0:8096',
            enabled: !_loading,
            prefix: StatefulBuilder(
              builder: (context, setPrefixState) {
                bool isFocused = false;
                return Material(
                  type: MaterialType.transparency,
                  child: Focus(
                    onFocusChange: (f) => setPrefixState(() => isFocused = f),
                    child: InkWell(
                      onTap: _loading ? null : () => setState(() => _useHttps = !_useHttps),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (const Color(0xFFFF5C00)).withOpacity(isFocused ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isFocused ? const Color(0xFFFF5C00) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _useHttps ? 'HTTPS' : 'HTTP',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5C00),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
          const SizedBox(height: 20),

          
          _NasaField(
            label: 'USERNAME',
            controller: _userCtrl,
            hint: 'myBro',
            enabled: !_loading,
          ),
          const SizedBox(height: 20),

          
          _NasaField(
            label: 'PASSWORD',
            controller: _passCtrl,
            hint: '••••••••',
            obscure: !_passVisible,
            enabled: !_loading,
            onSubmit: (_) => _doLogin(),
            suffix: IconButton(
              icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: theme.textTheme.bodySmall?.color?.withOpacity(0.2)),
              onPressed: () => setState(() => _passVisible = !_passVisible),
            ),
          ),
          const SizedBox(height: 48),

          
          _NasaButton(
            onPressed: _loading ? null : _doLogin,
            loading: _loading,
            text: 'INITIALIZE',
          ),
        ],
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
    final isDark = ThemeService.instance.isDarkMode;
    return Material(
      type: MaterialType.transparency,
      child: Focus(
        onFocusChange: (f) => setState(() => _isFocused = f),
        child: InkWell(
          onTap: () => ThemeSelectorDialog.show(context),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? const Color(0xFFFF5C00) : Theme.of(context).dividerColor.withOpacity(0.05),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: [
                if (_isFocused) BoxShadow(color: const Color(0xFFFF5C00).withOpacity(0.4), blurRadius: 15),
                if (!_isFocused) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
              color: const Color(0xFFFF5C00),
            ),
          ),
        ),
      ),
    );
  }
}

class _NasaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onSubmit;

  const _NasaField({
    required this.label,
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.03)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              if (prefix != null) prefix!,
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  obscureText: obscure,
                  onSubmitted: onSubmit,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.2)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

class _NasaButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;

  const _NasaButton({this.onPressed, required this.loading, required this.text});

  @override
  State<_NasaButton> createState() => _NasaButtonState();
}

class _NasaButtonState extends State<_NasaButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (_isFocused) BoxShadow(color: const Color(0xFFFF5C00).withOpacity(0.6), blurRadius: 20, spreadRadius: 4),
            ],
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: _isFocused ? 2 : 0,
            ),
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), 
            ),
            child: widget.loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label, value;
  final bool active;

  const _StatusTag({required this.label, required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: theme.textTheme.bodySmall?.color?.withOpacity(0.1), letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5C00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF5C00),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernNasaBackground extends StatelessWidget {
  final bool isDark;
  const _ModernNasaBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ModernGridPainter(isDark: isDark),
    );
  }
}

class _ModernGridPainter extends CustomPainter {
  final bool isDark;
  _ModernGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, Offset pos) {
      tp.text = TextSpan(text: text, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1));
      tp.layout();
      tp.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModernScanlinePainter extends CustomPainter {
  final double value;
  _ModernScanlinePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5C00).withOpacity(0.03)
      ..strokeWidth = 1;

    final y = value * size.height;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
