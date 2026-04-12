import 'package:duskmoon_feedback/duskmoon_feedback.dart';
import 'package:flutter/material.dart';
import 'package:duskmoon_form/duskmoon_form.dart';

import '../bloc/demo_form_bloc.dart';

/// Demo form widget showcasing all FormBloc field widgets.
class DemoFormWidget extends StatelessWidget {
  final VoidCallback? onSuccess;

  const DemoFormWidget({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DemoFormBloc(),
      child: Builder(
        builder: (context) {
          final formBloc = context.read<DemoFormBloc>();

          return DmFormBlocListener<DemoFormBloc, String, String>(
            onSubmitting: (context, state) {},
            onSuccess: (context, state) {
              _showResultDialog(
                context,
                title: 'Success',
                message: state.successResponse ?? 'Form submitted!',
                isError: false,
              );
              onSuccess?.call();
            },
            onFailure: (context, state) {
              _showResultDialog(
                context,
                title: 'Error',
                message: state.failureResponse ?? 'Something went wrong',
                isError: true,
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Text Fields ──
                  _buildSectionHeader(context, 'Text Fields'),
                  const SizedBox(height: 12),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.name,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter your full name',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.email,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'example@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.password,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: 'Min 8 chars, 1 uppercase, 1 number',
                    ),
                    suffixButton: SuffixButton.obscureText,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  DmTextFieldBlocBuilder(
                    textFieldBloc: formBloc.age,
                    decoration: const InputDecoration(
                      labelText: 'Age (optional)',
                      prefixIcon: Icon(Icons.cake_outlined),
                      hintText: 'Your age',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 24),

                  // ── Dropdown ──
                  _buildSectionHeader(context, 'Dropdown'),
                  const SizedBox(height: 12),
                  DmDropdownFieldBlocBuilder<String>(
                    selectFieldBloc: formBloc.country,
                    decoration: const InputDecoration(
                      labelText: 'Country *',
                      prefixIcon: Icon(Icons.public),
                    ),
                    itemBuilder: (context, value) =>
                        FieldItem(child: Text(value)),
                  ),

                  const SizedBox(height: 24),

                  // ── Choice Chips ──
                  _buildSectionHeader(context, 'Choice Chips (single select)'),
                  const SizedBox(height: 8),
                  _buildDescription(context, 'Select a priority level'),
                  const SizedBox(height: 8),
                  DmChoiceChipFieldBlocBuilder<String>(
                    selectFieldBloc: formBloc.priority,
                    itemBuilder: (context, value) =>
                        ChipFieldItem(label: Text(value)),
                  ),

                  const SizedBox(height: 24),

                  // ── Radio Buttons ──
                  _buildSectionHeader(context, 'Radio Buttons (single select)'),
                  const SizedBox(height: 8),
                  _buildDescription(context, 'Select your experience level'),
                  const SizedBox(height: 8),
                  DmRadioButtonGroupFieldBlocBuilder<String>(
                    selectFieldBloc: formBloc.experienceLevel,
                    itemBuilder: (context, value) =>
                        FieldItem(child: Text(value)),
                  ),

                  const SizedBox(height: 24),

                  // ── Checkbox Group ──
                  _buildSectionHeader(context, 'Checkbox Group (multi-select)'),
                  const SizedBox(height: 8),
                  _buildDescription(
                    context,
                    'Select your interests (optional)',
                  ),
                  const SizedBox(height: 8),
                  DmCheckboxGroupFieldBlocBuilder<String>(
                    multiSelectFieldBloc: formBloc.interests,
                    itemBuilder: (context, value) =>
                        FieldItem(child: Text(value)),
                  ),

                  const SizedBox(height: 24),

                  // ── Filter Chips ──
                  _buildSectionHeader(context, 'Filter Chips (multi-select)'),
                  const SizedBox(height: 8),
                  _buildDescription(context, 'Select your skills'),
                  const SizedBox(height: 8),
                  DmFilterChipFieldBlocBuilder<String>(
                    multiSelectFieldBloc: formBloc.skills,
                    itemBuilder: (context, value) =>
                        ChipFieldItem(label: Text(value)),
                  ),

                  const SizedBox(height: 24),

                  // ── Checkbox ──
                  _buildSectionHeader(context, 'Checkbox'),
                  const SizedBox(height: 8),
                  DmCheckboxFieldBlocBuilder(
                    booleanFieldBloc: formBloc.acceptTerms,
                    body: Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'I accept the Terms of Service and Privacy Policy *',
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Switch ──
                  _buildSectionHeader(context, 'Switch'),
                  const SizedBox(height: 8),
                  DmSwitchFieldBlocBuilder(
                    booleanFieldBloc: formBloc.enableNotifications,
                    body: const Text('Enable push notifications'),
                  ),

                  const SizedBox(height: 24),

                  // ── Slider ──
                  _buildSectionHeader(context, 'Slider'),
                  const SizedBox(height: 8),
                  DmSliderFieldBlocBuilder(
                    inputFieldBloc: formBloc.satisfaction,
                    decoration: const InputDecoration(
                      labelText: 'Satisfaction Level',
                      prefixIcon: Icon(Icons.sentiment_satisfied_alt),
                    ),
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    labelBuilder: (context, value) =>
                        '${(value * 100).round()}%',
                  ),

                  const SizedBox(height: 24),

                  // ── Date Picker ──
                  _buildSectionHeader(context, 'Date Picker'),
                  const SizedBox(height: 12),
                  DmDateTimeFieldBlocBuilder(
                    dateTimeFieldBloc: formBloc.birthDate,
                    format: DateFormat.yMMMd(),
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    decoration: const InputDecoration(
                      labelText: 'Birth Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'Select your birth date',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Time Picker ──
                  _buildSectionHeader(context, 'Time Picker'),
                  const SizedBox(height: 12),
                  DmTimeFieldBlocBuilder(
                    timeFieldBloc: formBloc.preferredTime,
                    format: DateFormat.jm(),
                    initialTime: TimeOfDay.now(),
                    decoration: const InputDecoration(
                      labelText: 'Preferred Contact Time',
                      prefixIcon: Icon(Icons.access_time),
                      hintText: 'Select a time',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Markdown Editor ──
                  _buildSectionHeader(context, 'Markdown Editor'),
                  const SizedBox(height: 12),
                  DmMarkdownFieldBlocBuilder(
                    markdownFieldBloc: formBloc.bio,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    showLineNumbers: true,
                    minLines: 8,
                  ),

                  const SizedBox(height: 24),

                  // ── Code Editor ──
                  _buildSectionHeader(context, 'Code Editor'),
                  const SizedBox(height: 12),
                  DmCodeEditorFieldBlocBuilder(
                    codeEditorFieldBloc: formBloc.codeSnippet,
                    lineNumbers: true,
                    highlightActiveLine: true,
                    minHeight: 200,
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  BlocBuilder<DemoFormBloc, FormBlocState>(
                    builder: (context, state) {
                      final isSubmitting = state is FormBlocSubmitting;
                      return FilledButton(
                        onPressed: isSubmitting ? null : formBloc.submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Form'),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Clear Button
                  OutlinedButton(
                    onPressed: formBloc.clear,
                    child: const Text('Clear Form'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDescription(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _showResultDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isError,
  }) {
    showDmDialog(
      context: context,
      title: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Theme.of(context).colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        DmDialogAction(
          onPressed: (ctx) => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
