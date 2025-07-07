import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'state.dart';

class {{name.pascalCase()}}Bloc extends Bloc<{{name.pascalCase()}}Event, {{name.pascalCase()}}State> {
  {{name.pascalCase()}}Bloc() : super({{name.pascalCase()}}State.initial()) {
    on<{{name.pascalCase()}}EventInit>(_on{{name.pascalCase()}}EventInit);
  }

  Future<void> _on{{name.pascalCase()}}EventInit(
    {{name.pascalCase()}}EventInit event,
    Emitter<{{name.pascalCase()}}State> emitter,
  ) async {
    emitter(state.copyWith());
  }

}
