import 'package:mason/mason.dart';

void run(HookContext context) {
  final dynamic rawFields = context.vars['fields'];
  final List<dynamic> fieldsList = (rawFields is List)
      ? rawFields
      : (rawFields is String)
          ? rawFields.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : <dynamic>['email:email', 'password:password'];

  final processedFields = <Map<String, dynamic>>[];

  for (final field in fieldsList) {
    final str = field.toString();
    final parts = str.split(':');
    final name = parts[0].trim();
    final type = parts.length > 1 ? parts[1].trim() : 'text';

    processedFields.add({
      'name': name,
      'type': type,
      'is_text': type == 'text',
      'is_email': type == 'email',
      'is_password': type == 'password',
      'is_number': type == 'number',
      'is_boolean': type == 'boolean',
    });
  }

  context.vars['fields'] = processedFields;
}
