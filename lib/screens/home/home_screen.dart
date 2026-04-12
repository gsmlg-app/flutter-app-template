import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'Home Screen';
  static const path = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DmAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(HomeScreen.name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: DmAppBar(
        title: Text(context.l10n.appName),
      ),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Hero section ──
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.flutter_dash,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Flutter App Template',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A modular monorepo template with BLoC state management, '
                      'DuskMoon UI, and comprehensive tooling.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick navigation ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickNavCard(
                        icon: Icons.widgets,
                        label: 'Showcase',
                        color: Colors.blue,
                        onTap: () => context.goNamed(ShowcaseScreen.name),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickNavCard(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: Colors.grey,
                        onTap: () => context.goNamed(SettingsScreen.name),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Architecture overview ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Architecture',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverGrid.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: const [
                  _PackageTile(
                    icon: Icons.hub,
                    label: 'app_bloc',
                    detail: 'BLoC state mgmt',
                  ),
                  _PackageTile(
                    icon: Icons.library_books,
                    label: 'app_lib',
                    detail: 'Core utilities',
                  ),
                  _PackageTile(
                    icon: Icons.widgets_outlined,
                    label: 'app_widget',
                    detail: 'Reusable UI',
                  ),
                  _PackageTile(
                    icon: Icons.edit_note,
                    label: 'app_form',
                    detail: 'Form modules',
                  ),
                  _PackageTile(
                    icon: Icons.extension,
                    label: 'app_plugin',
                    detail: 'Native plugins',
                  ),
                  _PackageTile(
                    icon: Icons.construction,
                    label: 'bricks',
                    detail: 'Mason templates',
                  ),
                ],
              ),
            ),

            // ── Key features ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Features',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _FeatureTile(
                    icon: Icons.palette,
                    title: 'DuskMoon UI',
                    description:
                        'Theme, adaptive widgets, feedback, forms, '
                        'data visualization, and code editor',
                    color: colorScheme.primary,
                  ),
                  _FeatureTile(
                    icon: Icons.account_tree,
                    title: 'BLoC Pattern',
                    description:
                        'State management with events, states, '
                        'and reactive streams',
                    color: Colors.teal,
                  ),
                  _FeatureTile(
                    icon: Icons.storage,
                    title: 'Local Storage',
                    description:
                        'Drift database, SharedPreferences, '
                        'and platform-native secure storage',
                    color: Colors.orange,
                  ),
                  _FeatureTile(
                    icon: Icons.translate,
                    title: 'Localization',
                    description:
                        'Multi-language support with ARB files '
                        'and generated l10n',
                    color: Colors.indigo,
                  ),
                  _FeatureTile(
                    icon: Icons.devices,
                    title: 'Multi-Platform',
                    description:
                        'Android, iOS, macOS, Linux, Windows, '
                        'and Web from a single codebase',
                    color: Colors.green,
                  ),
                  _FeatureTile(
                    icon: Icons.gamepad,
                    title: 'Gamepad Support',
                    description:
                        'Controller input handling with '
                        'configurable button mapping',
                    color: Colors.purple,
                  ),
                ]),
              ),
            ),

            // ── Tech stack ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Tech Stack',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _TechChip('Flutter 3.8+'),
                    _TechChip('Dart 3.8+'),
                    _TechChip('BLoC / Cubit'),
                    _TechChip('GoRouter'),
                    _TechChip('DuskMoon UI'),
                    _TechChip('Drift'),
                    _TechChip('Mason'),
                    _TechChip('Melos'),
                    _TechChip('Nix / Devenv'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;

  const _PackageTile({
    required this.icon,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;

  const _TechChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: Theme.of(context).textTheme.labelSmall),
      visualDensity: VisualDensity.compact,
    );
  }
}
