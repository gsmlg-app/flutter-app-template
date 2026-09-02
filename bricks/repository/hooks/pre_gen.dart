import 'package:mason/mason.dart';

void run(HookContext context) {
  final name = context.vars['name'] as String? ?? 'user';
  final modelName = context.vars['model_name'] as String?;
  if (modelName == null || modelName.isEmpty || modelName == '{{name.pascalCase()}}') {
    context.vars['model_name'] = name;
  }
}
