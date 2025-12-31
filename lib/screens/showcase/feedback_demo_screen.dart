import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class FeedbackDemoScreen extends StatelessWidget {
  static const name = 'Feedback Demo';
  static const path = 'feedback';

  const FeedbackDemoScreen({super.key});

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
                      title: 'Dialogs',
                      children: [
                        _buildDemoButton(
                          context,
                          label: 'Show Dialog',
                          onPressed: () => _showDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Snackbars',
                      children: [
                        _buildDemoButton(
                          context,
                          label: 'Show Snackbar',
                          onPressed: () => _showSnackbar(context),
                        ),
                        const SizedBox(height: 8),
                        _buildDemoButton(
                          context,
                          label: 'Show Undo Snackbar',
                          onPressed: () => _showUndoSnackbar(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Toasts',
                      children: [
                        _buildDemoButton(
                          context,
                          label: 'Show Success Toast',
                          onPressed: () => _showSuccessToast(context),
                        ),
                        const SizedBox(height: 8),
                        _buildDemoButton(
                          context,
                          label: 'Show Error Toast',
                          onPressed: () => _showErrorToast(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Bottom Sheets',
                      children: [
                        _buildDemoButton(
                          context,
                          label: 'Show Bottom Sheet Actions',
                          onPressed: () => _showBottomSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Fullscreen Dialogs',
                      children: [
                        _buildDemoButton(
                          context,
                          label: 'Show Fullscreen Dialog',
                          onPressed: () => _showFullscreen(context),
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
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDemoButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showAppDialog(
      context: context,
      title: const Text('Dialog Title'),
      content: const Text('This is a platform-adaptive dialog. '
          'It uses AlertDialog.adaptive to match the platform style.'),
      actions: [
        AppDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: Text(context.l10n.cancel),
        ),
        AppDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }

  void _showSnackbar(BuildContext context) {
    showSnackbar(
      context: context,
      message: const Text('This is a simple snackbar message'),
      showCloseIcon: true,
      actionLabel: 'Action',
      onActionPressed: () {},
    );
  }

  void _showUndoSnackbar(BuildContext context) {
    showUndoSnackbar(
      context: context,
      message: const Text('Item deleted'),
      onUndoPressed: () {
        showSnackbar(
          context: context,
          message: const Text('Undo action triggered!'),
        );
      },
    );
  }

  void _showSuccessToast(BuildContext context) {
    showSuccessToast(
      context: context,
      title: 'Success!',
      message: 'Operation completed successfully.',
      showCloseIcon: true,
    );
  }

  void _showErrorToast(BuildContext context) {
    showErrorToast(
      context: context,
      title: 'Error!',
      message: 'Something went wrong. Please try again.',
      showCloseIcon: true,
    );
  }

  void _showBottomSheet(BuildContext context) {
    showBottomSheetActionList(
      context: context,
      actions: [
        BottomSheetAction(
          title: const Text('Option 1'),
          onTap: () {},
        ),
        BottomSheetAction(
          title: const Text('Option 2'),
          onTap: () {},
        ),
        BottomSheetAction(
          title: const Text('Option 3'),
          onTap: () {},
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onError,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  void _showFullscreen(BuildContext context) {
    showFullScreenDialog(
      context: context,
      title: const Text('Fullscreen Dialog'),
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fullscreen,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'This is a fullscreen dialog',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Tap the X button to close'),
            ],
          ),
        );
      },
    );
  }
}
