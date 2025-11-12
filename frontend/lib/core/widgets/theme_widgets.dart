import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// Widget untuk toggle dark mode dengan switch
class ThemeToggleSwitch extends StatelessWidget {
  final bool showLabel;

  const ThemeToggleSwitch({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: showLabel ? const Text('Dark Mode') : null,
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            if (value) {
              themeProvider.setDarkMode();
            } else {
              themeProvider.setLightMode();
            }
          },
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
        );
      },
    );
  }
}

/// Widget untuk memilih theme mode (Light, Dark, System)
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Theme Mode',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Tema terang'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.light_mode),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Tema gelap'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Mengikuti pengaturan sistem'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.brightness_auto),
            ),
          ],
        );
      },
    );
  }
}

/// Simple icon button untuk toggle theme
class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: 'Toggle Theme',
        );
      },
    );
  }
}
