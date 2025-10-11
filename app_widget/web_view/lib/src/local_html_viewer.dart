import 'dart:io';
import 'dart:async';

import 'package:app_locale/app_locale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LocalHtmlViewer extends StatefulWidget {
  const LocalHtmlViewer({
    super.key,
    required this.indexFile,
  });

  final String indexFile;

  @override
  State<LocalHtmlViewer> createState() => _LocalHtmlViewerState();
}

class _LocalHtmlViewerState extends State<LocalHtmlViewer> {
  WebViewController? _controller;
  String? _error;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewWithRetry();
  }

  void _initializeWebViewWithRetry() async {
    const maxRetries = 5;
    int attempt = 0;

    while (attempt < maxRetries) {
      debugPrint(
          'LocalHtmlViewer: Attempt ${attempt + 1} of $maxRetries at ${DateTime.now()}');

      final success = await _initializeWebView();
      if (success) {
        debugPrint(
            'LocalHtmlViewer: Successfully loaded on attempt ${attempt + 1}');
        return;
      }

      attempt++;
      if (attempt < maxRetries) {
        // Use shorter delays for first attempts, then increase
        final delaySeconds = attempt <= 2 ? 1 : attempt;
        debugPrint('LocalHtmlViewer: Retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // If all retries failed, show final error
    setState(() {
      _error =
          'Failed to load document after $maxRetries attempts. Please try again.';
    });
  }

  Future<bool> _initializeWebView() async {
    try {
      debugPrint('LocalHtmlViewer: Loading file ${widget.indexFile}');
      debugPrint(
          'LocalHtmlViewer: File exists: ${File(widget.indexFile).existsSync()}');

      // Normalize the file path for the platform
      final normalizedPath = Uri.file(widget.indexFile).toFilePath();
      debugPrint('LocalHtmlViewer: Normalized path: $normalizedPath');

      setState(() {
        _error = null;
      });

      // Check if file exists before loading
      final file = File(widget.indexFile);

      // Wait a bit for file to be fully written (if just extracted)
      int retries = 0;
      while (!file.existsSync() && retries < 20) {
        // Increased retries
        debugPrint(
            'LocalHtmlViewer: File not found, waiting... retry $retries');
        await Future.delayed(Duration(milliseconds: 200)); // Increased delay
        retries++;
      }

      if (!file.existsSync()) {
        debugPrint('LocalHtmlViewer: File does not exist: ${widget.indexFile}');
        return false; // Return failure instead of setting final error
      }

      debugPrint(
          'LocalHtmlViewer: File found, size: ${file.lengthSync()} bytes');

      // Additional wait time to ensure file is fully released by OS
      await Future.delayed(Duration(milliseconds: 500));
      debugPrint('LocalHtmlViewer: Finished waiting for file system to settle');

      // Create the controller first
      final controller = WebViewController();

      // Configure the controller
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('LocalHtmlViewer: Page started loading: $url');
            },
            onPageFinished: (String url) {
              // Inject CSS to improve scrolling behavior
              controller.runJavaScript('''
                document.body.style.overflow = 'auto';
                document.body.style.webkitOverflowScrolling = 'touch';
                document.documentElement.style.overflow = 'auto';
                document.documentElement.style.webkitOverflowScrolling = 'touch';
              ''');
              debugPrint('LocalHtmlViewer: Page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView resource error: ${error.description}');
              // Don't set state here, let the loadFile catch block handle it
            },
          ),
        );

      // Load the file with proper error handling
      await controller.loadFile(widget.indexFile);
      debugPrint(
          'LocalHtmlViewer: WebView loadFile completed for: ${widget.indexFile}');

      // Set the controller and mark as initialized
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      return true; // Success
    } catch (e, stackTrace) {
      debugPrint('LocalHtmlViewer: Error loading file: $e');
      debugPrint('LocalHtmlViewer: Stack trace: $stackTrace');
      return false; // Failure
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeWebViewWithRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    // Show empty container while initializing (will be very brief due to retry mechanism)
    if (!_isInitialized || _controller == null) {
      return Container(); // Empty container during initialization
    }

    return WebViewWidget(
      controller: _controller!,
      gestureRecognizers: {
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
        Factory<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(),
        ),
        Factory<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
        ),
      },
    );
  }
}
