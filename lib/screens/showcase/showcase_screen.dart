import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/adaptive_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/artwork_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/feedback_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/webview_demo_screen.dart';
import 'package:go_router/go_router.dart';

class ShowcaseScreen extends StatelessWidget {
  static const name = 'Showcase';
  static const path = '/showcase';

  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: const Text('Widget Showcase'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Explore the widgets available in this template',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              _buildDemoCard(
                context,
                title: 'Feedback Widgets',
                subtitle: 'app_feedback',
                description: 'Dialogs, Snackbars, Toasts, Bottom Sheets, Fullscreen Dialogs',
                icon: Icons.notifications_active,
                color: Colors.orange,
                onTap: () => context.goNamed(FeedbackDemoScreen.name),
              ),
              const SizedBox(height: 12),
              _buildDemoCard(
                context,
                title: 'Adaptive Widgets',
                subtitle: 'app_adaptive_widgets',
                description: 'Responsive action lists, adaptive scaffolds',
                icon: Icons.devices,
                color: Colors.blue,
                onTap: () => context.goNamed(AdaptiveDemoScreen.name),
              ),
              const SizedBox(height: 12),
              _buildDemoCard(
                context,
                title: 'Artwork Widgets',
                subtitle: 'app_artwork',
                description: 'Lottie animations, custom logos',
                icon: Icons.palette,
                color: Colors.purple,
                onTap: () => context.goNamed(ArtworkDemoScreen.name),
              ),
              const SizedBox(height: 12),
              _buildDemoCard(
                context,
                title: 'WebView Widget',
                subtitle: 'app_web_view',
                description: 'Local HTML viewer with retry logic',
                icon: Icons.web,
                color: Colors.green,
                onTap: () => context.goNamed(WebViewDemoScreen.name),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontFamily: 'monospace',
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
