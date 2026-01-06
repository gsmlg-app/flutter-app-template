#include "client_info_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <memory>
#include <sstream>
#include <string>
#include <chrono>
#include <iomanip>

namespace client_info_windows {

class ClientInfoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ClientInfoPlugin();

  virtual ~ClientInfoPlugin();

  ClientInfoPlugin(const ClientInfoPlugin&) = delete;
  ClientInfoPlugin& operator=(const ClientInfoPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::EncodableMap GetData();
  std::string GetCurrentTimestamp();

  flutter::EncodableMap cached_data_;
  bool has_cached_data_ = false;
};

void ClientInfoPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "app_client_info",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ClientInfoPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ClientInfoPlugin::ClientInfoPlugin() {}

ClientInfoPlugin::~ClientInfoPlugin() {}

std::string ClientInfoPlugin::GetCurrentTimestamp() {
  auto now = std::chrono::system_clock::now();
  auto itt = std::chrono::system_clock::to_time_t(now);
  std::ostringstream ss;
  ss << std::put_time(gmtime(&itt), "%FT%TZ");
  return ss.str();
}

flutter::EncodableMap ClientInfoPlugin::GetData() {
  if (has_cached_data_) {
    return cached_data_;
  }

  OSVERSIONINFOW osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOW));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOW);
  GetVersionExW(&osvi);

  SYSTEM_INFO siSysInfo;
  GetSystemInfo(&siSysInfo);

  MEMORYSTATUSEX statex;
  statex.dwLength = sizeof(statex);
  GlobalMemoryStatusEx(&statex);

  flutter::EncodableMap additional_data;
  additional_data[flutter::EncodableValue("majorVersion")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwMajorVersion));
  additional_data[flutter::EncodableValue("minorVersion")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwMinorVersion));
  additional_data[flutter::EncodableValue("buildNumber")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwBuildNumber));
  additional_data[flutter::EncodableValue("numberOfProcessors")] =
      flutter::EncodableValue(static_cast<int>(siSysInfo.dwNumberOfProcessors));
  additional_data[flutter::EncodableValue("totalPhysicalMemory")] =
      flutter::EncodableValue(static_cast<int64_t>(statex.ullTotalPhys));

  flutter::EncodableMap result;
  result[flutter::EncodableValue("platform")] = flutter::EncodableValue("windows");
  result[flutter::EncodableValue("timestamp")] =
      flutter::EncodableValue(GetCurrentTimestamp());
  result[flutter::EncodableValue("additionalData")] =
      flutter::EncodableValue(additional_data);

  cached_data_ = result;
  has_cached_data_ = true;

  return result;
}

void ClientInfoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getData") == 0) {
    try {
      auto data = GetData();
      result->Success(flutter::EncodableValue(data));
    } catch (const std::exception& e) {
      result->Error("ERROR", "Failed to get data: " + std::string(e.what()));
    }
  } else if (method_call.method_name().compare("refresh") == 0) {
    has_cached_data_ = false;
    cached_data_.clear();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace client_info_windows

void ClientInfoPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  client_info_windows::ClientInfoPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
