import 'dart:async';
import 'dart:ui';

import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';

import 'error_reporting_service.dart';

class CrashReportingWidget extends StatefulWidget {
  final Widget child;
  final bool showErrorScreen;
  final Widget Function(FlutterErrorDetails)? errorScreenBuilder;

  const CrashReportingWidget({
    super.key,
    required this.child,
    this.showErrorScreen = true,
    this.errorScreenBuilder,
  });

  @override
  State<CrashReportingWidget> createState() => _CrashReportingWidgetState();
}

class _CrashReportingWidgetState extends State<CrashReportingWidget> {
  final ErrorReportingService _errorService = ErrorReportingService();

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }

  void _setupErrorHandling() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _errorService.reportFlutterError(details: details);
      if (widget.showErrorScreen) {
        FlutterError.presentError(details);
      }
    };

    // Capture platform channel errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _errorService.reportError(
        error: error,
        stackTrace: stack,
        context: 'Unhandled platform error',
      );
      return true; // Indicate that the error was handled
    };

    // Capture async errors
    runZonedGuarded(
      () {
        // App runs in this zone
      },
      (Object error, StackTrace stack) {
        _errorService.reportError(
          error: error,
          stackTrace: stack,
          context: 'Unhandled async error',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onReport;

  const ErrorScreen({
    super.key,
    required this.errorDetails,
    this.onRetry,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.errorContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.onErrorContainer),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'re sorry, but an unexpected error occurred.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DmButton(
                    onPressed:
                        onRetry ??
                        () {
                          // Restart app or navigate to home
                        },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  DmButton(
                    variant: DmButtonVariant.outlined,
                    onPressed:
                        onReport ??
                        () {
                          // Open error reporting dialog
                          _showReportDialog(context);
                        },
                    child: const Text('Report Error'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDmDialog(
      context: context,
      title: const Text('Report Error'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Error details:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                errorDetails.exceptionAsString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        DmDialogAction(
          onPressed: (ctx) => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        DmDialogAction(
          onPressed: (ctx) {
            // TODO: Implement actual error reporting
            Navigator.pop(ctx);
            showDmSuccessToast(
              context: context,
              message: 'Error report submitted',
            );
          },
          child: const Text('Send Report'),
        ),
      ],
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({super.key, this.errorBuilder, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return _ErrorBoundaryWidget(errorBuilder: errorBuilder, child: child);
      },
    );
  }
}

class _ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const _ErrorBoundaryWidget({required this.child, this.errorBuilder});

  @override
  State<_ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<_ErrorBoundaryWidget> {
  FlutterErrorDetails? _lastError;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastError != null) {
      return widget.errorBuilder?.call(_lastError!) ??
          ErrorScreen(errorDetails: _lastError!);
    }

    return widget.child;
  }

  @override
  void deactivate() {
    _lastError = null;
    super.deactivate();
  }
}
