import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';

class ErrorDisplay {
  static void showError(
    BuildContext context,
    String message, {
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    switch (severity) {
      case ErrorSeverity.low:
        showDmSnackbar(
          context: context,
          message: Text(message),
          duration: const Duration(seconds: 2),
          actionLabel: onRetry != null ? 'RETRY' : 'DISMISS',
          onActionPressed:
              onRetry ??
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        break;
      case ErrorSeverity.medium:
        showDmSnackbar(
          context: context,
          message: Text(message),
          duration: const Duration(seconds: 4),
          actionLabel: onRetry != null ? 'RETRY' : 'DISMISS',
          onActionPressed:
              onRetry ??
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        break;
      case ErrorSeverity.high:
        _showDialog(context, message, onRetry: onRetry);
        break;
      case ErrorSeverity.critical:
        _showCriticalErrorDialog(context, message, onRetry: onRetry);
        break;
    }
  }

  static void _showDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDmDialog(
      context: context,
      title: const Text('Error'),
      content: Text(message),
      actions: [
        if (onRetry != null)
          DmDialogAction(
            onPressed: (_) => onRetry(),
            child: const Text('RETRY'),
          ),
        DmDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static void _showCriticalErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDmDialog(
      context: context,
      title: const Text('Critical Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text(
            'The app needs to restart to recover.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (onRetry != null)
          DmDialogAction(
            onPressed: (_) => onRetry(),
            child: const Text('RESTART APP'),
          ),
        DmDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

enum ErrorSeverity { low, medium, high, critical }
