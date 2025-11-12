import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_widgets.dart';

/// Page untuk preview warna tema dan testing dark mode
class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Preview'),
        actions: const [ThemeToggleIconButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Theme: ${isDark ? "Dark" : "Light"}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toggle theme using the icon button in the app bar',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Primary Colors
          _buildColorSection(context, 'Primary Colors', [
            _ColorItem('Primary', theme.colorScheme.primary),
            _ColorItem(
              'Primary Light',
              isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
            ),
            _ColorItem(
              'Primary Dark',
              isDark ? AppColors.darkPrimaryDark : AppColors.primaryDark,
            ),
          ]),

          const SizedBox(height: 16),

          // Background Colors
          _buildColorSection(context, 'Background Colors', [
            _ColorItem('Background', theme.colorScheme.background),
            _ColorItem('Surface', theme.colorScheme.surface),
            _ColorItem(
              'Card',
              isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
            ),
          ]),

          const SizedBox(height: 16),

          // Text Colors
          _buildColorSection(context, 'Text Colors', [
            _ColorItem(
              'Primary Text',
              isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            _ColorItem(
              'Secondary Text',
              isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            _ColorItem(
              'Hint Text',
              isDark ? AppColors.darkTextHint : AppColors.textHint,
            ),
          ]),

          const SizedBox(height: 16),

          // Status Colors
          _buildColorSection(context, 'Status Colors', [
            _ColorItem('Success', AppColors.success),
            _ColorItem('Warning', AppColors.warning),
            _ColorItem('Error', theme.colorScheme.error),
            _ColorItem('Info', AppColors.info),
          ]),

          const SizedBox(height: 24),

          // UI Components Preview
          Text(
            'UI Components',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buttons',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated Button'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text Fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Text Fields',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Hint text',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'With Icon',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List Tiles
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  subtitle: const Text('Go to home page'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  subtitle: const Text('App settings'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(
    BuildContext context,
    String title,
    List<_ColorItem> colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: colors
                .map((item) => _buildColorTile(item.name, item.color))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorTile(String name, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      title: Text(name),
      subtitle: Text(
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;

  _ColorItem(this.name, this.color);
}
