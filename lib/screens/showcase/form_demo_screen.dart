import 'package:demo_form/demo_form.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class FormDemoScreen extends StatelessWidget {
  static const name = 'Form Demo';
  static const path = 'form';

  const FormDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DmAdaptiveScaffold(
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
              SliverAppBar(title: const Text(name), pinned: true),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FormBloc Demo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This demo showcases all available form field types '
                        'and validation patterns using duskmoon_form.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureChips(context),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider()),
              const SliverToBoxAdapter(child: DemoFormWidget()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureChips(BuildContext context) {
    final features = [
      'TextFieldBloc',
      'SelectFieldBloc',
      'MultiSelectFieldBloc',
      'BooleanFieldBloc',
      'InputFieldBloc',
      'MarkdownFieldBloc',
      'CodeEditorFieldBloc',
      'Dropdown',
      'ChoiceChips',
      'FilterChips',
      'RadioButtons',
      'CheckboxGroup',
      'Switch',
      'Slider',
      'DatePicker',
      'TimePicker',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features
          .map(
            (f) => Chip(
              label: Text(f, style: Theme.of(context).textTheme.labelSmall),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}
