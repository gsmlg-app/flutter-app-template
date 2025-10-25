import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel_client_info.dart';

/// The interface that platform-specific implementations of
/// `app_client_info` must extend.
abstract class ClientInfoPlatform extends PlatformInterface {
  /// Constructs a ClientInfoPlatform.
  ClientInfoPlatform() : super(token: _token);

  static final Object _token = Object();

  static ClientInfoPlatform _instance = MethodChannelClientInfo();

  /// The default instance of [ClientInfoPlatform] to use.
  ///
  /// Defaults to [MethodChannelClientInfo].
  static ClientInfoPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own
  /// platform-specific class that extends [ClientInfoPlatform] when
  /// they register themselves.
  static set instance(ClientInfoPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Get client_info data from the platform.
  ///
  /// Returns a map containing platform-specific client_info data.
  Future<Map<String, dynamic>> getData() {
    throw UnimplementedError('getData() has not been implemented.');
  }

  /// Refresh the cached client_info data.
  Future<void> refresh() {
    throw UnimplementedError('refresh() has not been implemented.');
  }
}
