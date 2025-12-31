import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class AdaptiveDemoScreen extends StatelessWidget {
  static const name = 'Adaptive Demo';
  static const path = 'adaptive';

  const AdaptiveDemoScreen({super.key});

  List<AppAdaptiveAction> _buildActions(BuildContext context) {
    return [
      AppAdaptiveAction(
        title: 'Edit',
        icon: Icons.edit,
        onPressed: () => showSnackbar(
          context: context,
          message: const Text('Edit action pressed'),
        ),
      ),
      AppAdaptiveAction(
        title: 'Share',
        icon: Icons.share,
        onPressed: () => showSnackbar(
          context: context,
          message: const Text('Share action pressed'),
        ),
      ),
      AppAdaptiveAction(
        title: 'Delete',
        icon: Icons.delete,
        onPressed: () => showSnackbar(
          context: context,
          message: const Text('Delete action pressed'),
        ),
      ),
      AppAdaptiveAction(
        title: 'Disabled',
        icon: Icons.block,
        onPressed: () {},
        disabled: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(name)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSection(
                      context,
                      title: 'AppAdaptiveActionList',
                      description:
                          'Responsive action list that adapts to different sizes',
                      children: [
                        _buildSizeDemo(
                          context,
                          title: 'Small (PopupMenu)',
                          size: AppAdaptiveActionSize.small,
                        ),
                        const SizedBox(height: 16),
                        _buildSizeDemo(
                          context,
                          title: 'Medium (IconButtons)',
                          size: AppAdaptiveActionSize.medium,
                        ),
                        const SizedBox(height: 16),
                        _buildSizeDemo(
                          context,
                          title: 'Large (TextButtons with icons)',
                          size: AppAdaptiveActionSize.large,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'Direction Options',
                      description: 'Actions can be laid out horizontally or vertically',
                      children: [
                        _buildDirectionDemo(
                          context,
                          title: 'Horizontal (default)',
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(height: 16),
                        _buildDirectionDemo(
                          context,
                          title: 'Vertical',
                          direction: Axis.vertical,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'Disabled Actions',
                      description: 'Show or hide disabled actions',
                      children: [
                        _buildDisabledDemo(
                          context,
                          title: 'Hide Disabled (default)',
                          hideDisabled: true,
                        ),
                        const SizedBox(height: 16),
                        _buildDisabledDemo(
                          context,
                          title: 'Show Disabled',
                          hideDisabled: false,
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSizeDemo(
    BuildContext context, {
    required String title,
    required AppAdaptiveActionSize size,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppAdaptiveActionList(
              size: size,
              actions: _buildActions(context),
              hideDisabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionDemo(
    BuildContext context, {
    required String title,
    required Axis direction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppAdaptiveActionList(
              size: AppAdaptiveActionSize.large,
              direction: direction,
              actions: _buildActions(context),
              hideDisabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledDemo(
    BuildContext context, {
    required String title,
    required bool hideDisabled,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppAdaptiveActionList(
              size: AppAdaptiveActionSize.large,
              actions: _buildActions(context),
              hideDisabled: hideDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
