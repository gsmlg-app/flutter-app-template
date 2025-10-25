import 'package:app_client_info_platform_interface/app_client_info_platform_interface.dart';

/// The Android implementation of [ClientInfoPlatform].
class ClientInfoAndroid extends ClientInfoPlatform {
  /// Registers this class as the default instance of [ClientInfoPlatform].
  static void registerWith() {
    ClientInfoPlatform.instance = ClientInfoAndroid();
  }
}
