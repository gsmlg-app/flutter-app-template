import 'package:equatable/equatable.dart';

/// Information about a connected gamepad controller
class ControllerInfo extends Equatable {
  const ControllerInfo({
    required this.id,
    required this.name,
    this.type = ControllerType.unknown,
  });

  /// Unique identifier for the controller
  final String id;

  /// Display name of the controller
  final String name;

  /// Detected controller type
  final ControllerType type;

  @override
  List<Object?> get props => [id, name, type];

  ControllerInfo copyWith({String? id, String? name, ControllerType? type}) {
    return ControllerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

/// Types of game controllers
enum ControllerType { xbox, playstation, nintendo, generic, unknown }

extension ControllerTypeExtension on ControllerType {
  String get displayName {
    switch (this) {
      case ControllerType.xbox:
        return 'Xbox Controller';
      case ControllerType.playstation:
        return 'PlayStation Controller';
      case ControllerType.nintendo:
        return 'Nintendo Controller';
      case ControllerType.generic:
        return 'Generic Controller';
      case ControllerType.unknown:
        return 'Unknown Controller';
    }
  }
}
