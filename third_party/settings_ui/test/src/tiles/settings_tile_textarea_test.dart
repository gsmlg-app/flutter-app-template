import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.textarea', () {
    testWidgets('creates textarea tile with required properties', (tester) async {
      String? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.textarea(
                      title: const Text('Bio'),
                      textareaValue: 'Initial bio text',
                      onTextareaChanged: (value) => capturedValue = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bio'), findsOneWidget);
    });

    testWidgets('creates textarea tile with hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.textarea(
                      title: const Text('Notes'),
                      textareaHint: 'Enter your notes here...',
                      onTextareaChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('creates textarea tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.textarea(
                      title: const Text('Description'),
                      leading: const Icon(Icons.description),
                      onTextareaChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('creates textarea tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.textarea(
                      title: const Text('Feedback'),
                      description: const Text('Share your thoughts'),
                      onTextareaChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Share your thoughts'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.textarea(
        title: const Text('Test'),
        onTextareaChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.textareaTile);
    });

    test('stores textarea properties correctly', () {
      void callback(String value) {}

      final tile = SettingsTile.textarea(
        title: const Text('Test'),
        textareaValue: 'test content',
        onTextareaChanged: callback,
        textareaHint: 'hint text',
        textareaMaxLines: 5,
        textareaMaxLength: 500,
      );

      expect(tile.textareaValue, 'test content');
      expect(tile.onTextareaChanged, callback);
      expect(tile.textareaHint, 'hint text');
      expect(tile.textareaMaxLines, 5);
      expect(tile.textareaMaxLength, 500);
    });

    test('has default maxLines value', () {
      final tile = SettingsTile.textarea(
        title: const Text('Test'),
        onTextareaChanged: (_) {},
      );

      expect(tile.textareaMaxLines, 3);
    });

    test('can be disabled', () {
      final tile = SettingsTile.textarea(
        title: const Text('Test'),
        onTextareaChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });
  });
}
