import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'client_info_platform.dart';

/// An implementation of [ClientInfoPlatform] that uses method channels.
class MethodChannelClientInfo extends ClientInfoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('app_client_info');

  @override
  Future<Map<String, dynamic>> getData() async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getData');
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Platform returned null result',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> refresh() async {
    await methodChannel.invokeMethod<void>('refresh');
  }
}
