import 'package:flutter/foundation.dart';
import 'package:app_client_info_platform_interface/app_client_info_platform_interface.dart';
import 'models/models.dart';

/// Main class for ClientInfo plugin.
///
/// Provides a unified API for accessing client_info information
/// across all supported platforms.
class ClientInfo {
  ClientInfo._();

  static ClientInfo? _instance;

  /// Get the singleton instance of ClientInfo.
  static ClientInfo get instance {
    _instance ??= ClientInfo._();
    return _instance!;
  }

  /// The platform interface instance.
  static ClientInfoPlatform get _platform {
    return ClientInfoPlatform.instance;
  }

  /// Get client_info data.
  ///
  /// Returns a [ClientInfoData] object containing all available
  /// client_info information for the current platform.
  ///
  /// Example:
  /// ```dart
  /// final clientInfo = ClientInfo.instance;
  /// final data = await clientInfo.getData();
  /// print('Data: ${data}');
  /// ```
  Future<ClientInfoData> getData() async {
    final platformData = await _platform.getData();
    return ClientInfoData.fromMap(platformData);
  }

  /// Refresh client_info data.
  ///
  /// Forces a refresh of the cached data from the platform.
  Future<void> refresh() async {
    await _platform.refresh();
  }

  /// For testing purposes only.
  @visibleForTesting
  static void setMockPlatform(ClientInfoPlatform platform) {
    ClientInfoPlatform.instance = platform;
  }

  /// Reset the singleton instance.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}
