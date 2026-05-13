import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';
import '../models/nasa_theme.dart';

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themes = ThemeService.instance.allThemes;
    final current = ThemeService.instance.currentTheme;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: const Text(
        'THEME SELECTOR',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: themes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isSelected = theme.id == current.id;
                  
                  return _ThemeTile(
                    theme: theme,
                    isSelected: isSelected,
                    onTap: () {
                      ThemeService.instance.setTheme(theme);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _OpenFolderButton(),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final NasaTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({required this.theme, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.background.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5C00) : Colors.black.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.background,
                shape: BoxShape.circle,
                border: Border.all(color: theme.text.withOpacity(0.1)),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    theme.brightness == Brightness.dark ? 'DARK MODE' : 'LIGHT MODE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF5C00), size: 20),
          ],
        ),
      ),
    );
  }
}

class _OpenFolderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      icon: const Icon(Icons.folder_open, size: 18),
      label: const Text('OPEN THEMES FOLDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
      onPressed: () async {
        final docDir = await getApplicationDocumentsDirectory();
        final themeDir = Directory('${docDir.path}/Vantage/themes');
        if (!await themeDir.exists()) await themeDir.create(recursive: true);
        
        if (Platform.isWindows) {
          await Process.run('explorer.exe', [themeDir.path]);
        } else {
          final uri = Uri.file(themeDir.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }
}

