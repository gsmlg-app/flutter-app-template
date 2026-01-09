import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:demo_form/demo_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class FormDemoScreen extends StatelessWidget {
  static const name = 'Form Demo';
  static const path = 'form';

  const FormDemoScreen({super.key});

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
                        'This demo showcases various form field types and '
                        'validation patterns using form_bloc and flutter_form_bloc.',
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
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildFeatureChips(BuildContext context) {
    final features = [
      'TextFieldBloc',
      'SelectFieldBloc',
      'MultiSelectFieldBloc',
      'BooleanFieldBloc',
      'Custom Validators',
      'Async Submit',
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
