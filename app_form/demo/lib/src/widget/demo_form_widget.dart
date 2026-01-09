import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

import '../bloc/demo_form_bloc.dart';

/// Demo form widget showcasing various FormBloc field widgets.
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

          return FormBlocListener<DemoFormBloc, String, String>(
            onSubmitting: (context, state) {
              // Loading dialog is shown by BlocBuilder below
            },
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
                  // Section: Personal Information
                  _buildSectionHeader(context, 'Personal Information'),
                  const SizedBox(height: 12),
                  TextFieldBlocBuilder(
                    textFieldBloc: formBloc.name,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter your full name',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextFieldBlocBuilder(
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
                  TextFieldBlocBuilder(
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
                  TextFieldBlocBuilder(
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

                  // Section: Location
                  _buildSectionHeader(context, 'Location'),
                  const SizedBox(height: 12),
                  DropdownFieldBlocBuilder<String>(
                    selectFieldBloc: formBloc.country,
                    decoration: const InputDecoration(
                      labelText: 'Country *',
                      prefixIcon: Icon(Icons.public),
                    ),
                    itemBuilder: (context, value) => FieldItem(
                      child: Text(value),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Interests
                  _buildSectionHeader(context, 'Interests'),
                  const SizedBox(height: 8),
                  Text(
                    'Select your interests (optional)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxGroupFieldBlocBuilder<String>(
                    multiSelectFieldBloc: formBloc.interests,
                    itemBuilder: (context, value) => FieldItem(
                      child: Text(value),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Terms
                  _buildSectionHeader(context, 'Terms & Conditions'),
                  const SizedBox(height: 8),
                  CheckboxFieldBlocBuilder(
                    booleanFieldBloc: formBloc.acceptTerms,
                    body: Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'I accept the Terms of Service and Privacy Policy *',
                      ),
                    ),
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

  void _showResultDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isError,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color:
                  isError ? Theme.of(context).colorScheme.error : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
