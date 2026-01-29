import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design textarea tile implementation.
///
/// Provides a multi-line text field with Material Design 3 styling for Android, Linux, and Web.
class MaterialTextareaTile extends StatelessWidget {
  const MaterialTextareaTile({
    required this.title,
    required this.enabled,
    required this.textareaMaxLines,
    this.leading,
    this.description,
    this.textareaValue,
    this.onTextareaChanged,
    this.textareaHint,
    this.textareaMaxLength,
    super.key,
  });

  // M3 specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 24.0;
  static const double _leadingGap = 16.0;
  static const double _titleFontSize = 16.0;
  static const double _descriptionFontSize = 14.0;

  final Widget? title;
  final Widget? leading;
  final Widget? description;
  final bool enabled;
  final String? textareaValue;
  final void Function(String)? onTextareaChanged;
  final String? textareaHint;
  final int textareaMaxLines;
  final int? textareaMaxLength;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with leading icon
              Row(
                children: [
                  if (leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: _leadingIconSize,
                        color: enabled
                            ? theme.themeData.leadingIconsColor ??
                                colorScheme.onSurfaceVariant
                            : theme.themeData.inactiveTitleColor ??
                                colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: _leadingGap),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: enabled
                            ? theme.themeData.settingsTileTextColor ??
                                colorScheme.onSurface
                            : theme.themeData.inactiveTitleColor ??
                                colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      child: title ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Multi-line text field
              TextFormField(
                initialValue: textareaValue,
                onChanged: enabled ? onTextareaChanged : null,
                enabled: enabled,
                maxLines: textareaMaxLines,
                maxLength: textareaMaxLength,
                decoration: InputDecoration(
                  hintText: textareaHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                  counterText: textareaMaxLength != null ? null : '',
                ),
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: enabled
                          ? theme.themeData.tileDescriptionTextColor ??
                              colorScheme.onSurfaceVariant
                          : theme.themeData.inactiveSubtitleColor ??
                              colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.38),
                      fontSize: _descriptionFontSize,
                    ),
                    child: description!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
