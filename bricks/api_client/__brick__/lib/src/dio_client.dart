import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Environment variable to disable API logging in debug mode.
/// Set `DISABLE_API_LOG=true` to disable logging in dev builds.
const String _disableLogEnvKey = 'DISABLE_API_LOG';

/// Creates a pre-configured [Dio] instance for API requests.
///
/// Features:
/// - In debug mode: LogInterceptor enabled by default
/// - In debug mode: Can be disabled via `DISABLE_API_LOG=true` env variable
/// - In release mode: LogInterceptor disabled by default
/// - In release mode: Can be enabled via `enableLogging: true` parameter
///
/// Example usage:
/// ```dart
/// final dio = createDioClient(baseUrl: 'https://api.example.com');
/// final api = MyApi(dio);
/// ```
Dio createDioClient({
  required String baseUrl,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Map<String, dynamic>? headers,
  List<Interceptor>? interceptors,
  bool? enableLogging,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      headers: headers,
    ),
  );

  // Add custom interceptors first
  if (interceptors != null) {
    dio.interceptors.addAll(interceptors);
  }

  // Determine if logging should be enabled
  final shouldEnableLogging = enableLogging ?? _shouldEnableLoggingByDefault();

  if (shouldEnableLogging) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  return dio;
}

/// Determines if logging should be enabled by default based on build mode
/// and environment variables.
bool _shouldEnableLoggingByDefault() {
  if (kReleaseMode) {
    // Production: logging disabled by default
    return false;
  }

  // Debug/Profile mode: check environment variable
  const disableLog = String.fromEnvironment(_disableLogEnvKey, defaultValue: 'false');
  return disableLog.toLowerCase() != 'true';
}
