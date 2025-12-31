import 'dart:io';

import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:app_web_view/app_web_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:path_provider/path_provider.dart';

class WebViewDemoScreen extends StatefulWidget {
  static const name = 'WebView Demo';
  static const path = 'webview';

  const WebViewDemoScreen({super.key});

  @override
  State<WebViewDemoScreen> createState() => _WebViewDemoScreenState();
}

class _WebViewDemoScreenState extends State<WebViewDemoScreen> {
  String? _htmlFilePath;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createSampleHtmlFile();
  }

  Future<void> _createSampleHtmlFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_demo.html');

      const htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LocalHtmlViewer Demo</title>
  <style>
    :root {
      --primary-color: #6750A4;
      --bg-color: #FEF7FF;
      --text-color: #1D1B20;
      --card-bg: #FFFFFF;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --primary-color: #D0BCFF;
        --bg-color: #1D1B20;
        --text-color: #E6E0E9;
        --card-bg: #2B2930;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: var(--bg-color);
      color: var(--text-color);
      padding: 20px;
      line-height: 1.6;
    }
    h1 {
      color: var(--primary-color);
      margin-bottom: 16px;
      font-size: 24px;
    }
    h2 {
      color: var(--primary-color);
      margin: 24px 0 12px;
      font-size: 18px;
    }
    .card {
      background: var(--card-bg);
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 16px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .feature {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px 0;
    }
    .feature-icon {
      width: 40px;
      height: 40px;
      background: var(--primary-color);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
    }
    .button {
      background: var(--primary-color);
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 16px;
      cursor: pointer;
      margin-top: 16px;
    }
    ul { padding-left: 20px; }
    li { margin: 8px 0; }
  </style>
</head>
<body>
  <h1>LocalHtmlViewer Demo</h1>

  <div class="card">
    <h2>Features</h2>
    <div class="feature">
      <div class="feature-icon">1</div>
      <div>
        <strong>Auto Retry</strong>
        <p>Automatically retries loading up to 5 times</p>
      </div>
    </div>
    <div class="feature">
      <div class="feature-icon">2</div>
      <div>
        <strong>JavaScript Enabled</strong>
        <p>Full JavaScript support for interactive content</p>
      </div>
    </div>
    <div class="feature">
      <div class="feature-icon">3</div>
      <div>
        <strong>Zoom Support</strong>
        <p>Pinch to zoom is enabled by default</p>
      </div>
    </div>
    <div class="feature">
      <div class="feature-icon">4</div>
      <div>
        <strong>Gesture Support</strong>
        <p>Custom gesture recognizers for smooth scrolling</p>
      </div>
    </div>
  </div>

  <div class="card">
    <h2>Use Cases</h2>
    <ul>
      <li>Display offline documentation</li>
      <li>Show bundled HTML content</li>
      <li>Render rich formatted text</li>
      <li>Display extracted archive contents</li>
    </ul>
  </div>

  <div class="card">
    <h2>Interactive Test</h2>
    <p>Click the button below to test JavaScript execution:</p>
    <button class="button" onclick="showAlert()">Test JavaScript</button>
    <p id="result" style="margin-top: 12px; color: var(--primary-color);"></p>
  </div>

  <script>
    function showAlert() {
      document.getElementById('result').innerText =
        'JavaScript executed at ' + new Date().toLocaleTimeString();
    }
  </script>
</body>
</html>
''';

      await file.writeAsString(htmlContent);

      setState(() {
        _htmlFilePath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          child: Column(
            children: [
              AppBar(
                title: Text(WebViewDemoScreen.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _createSampleHtmlFile,
                    tooltip: 'Reload HTML',
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showInfo(context),
                    tooltip: 'About LocalHtmlViewer',
                  ),
                ],
              ),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating sample HTML file...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createSampleHtmlFile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_htmlFilePath == null) {
      return const Center(
        child: Text('No HTML file available'),
      );
    }

    return LocalHtmlViewer(indexFile: _htmlFilePath!);
  }

  void _showInfo(BuildContext context) {
    showAppDialog(
      context: context,
      title: const Text('LocalHtmlViewer'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A WebView widget for displaying local HTML files.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Key Features:'),
            SizedBox(height: 8),
            Text('- Automatic retry mechanism (5 attempts)'),
            Text('- File existence checking with delays'),
            Text('- JavaScript enabled'),
            Text('- Zoom support'),
            Text('- Custom gesture recognizers'),
            Text('- CSS injection for scroll optimization'),
            Text('- Error handling with retry button'),
            SizedBox(height: 12),
            Text('Usage:'),
            SizedBox(height: 4),
            Text(
              'LocalHtmlViewer(indexFile: "/path/to/file.html")',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
