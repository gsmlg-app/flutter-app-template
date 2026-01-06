#include "include/app_client_info_linux/client_info_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <cstring>

#define CLIENT_INFO_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), client_info_plugin_get_type(), \
                               ClientInfoPlugin))

struct _ClientInfoPlugin {
  GObject parent_instance;
  FlValue* cached_data;
};

G_DEFINE_TYPE(ClientInfoPlugin, client_info_plugin, g_object_get_type())

// Get system information
static FlValue* get_data(ClientInfoPlugin* self) {
  if (self->cached_data != nullptr) {
    return fl_value_ref(self->cached_data);
  }

  struct utsname buffer;
  if (uname(&buffer) != 0) {
    return nullptr;
  }

  g_autoptr(FlValue) additional_data = fl_value_new_map();
  fl_value_set_string_take(additional_data, "sysname",
                           fl_value_new_string(buffer.sysname));
  fl_value_set_string_take(additional_data, "nodename",
                           fl_value_new_string(buffer.nodename));
  fl_value_set_string_take(additional_data, "release",
                           fl_value_new_string(buffer.release));
  fl_value_set_string_take(additional_data, "version",
                           fl_value_new_string(buffer.version));
  fl_value_set_string_take(additional_data, "machine",
                           fl_value_new_string(buffer.machine));

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "platform", fl_value_new_string("linux"));

  // Get current timestamp
  g_autoptr(GDateTime) now = g_date_time_new_now_utc();
  g_autofree gchar* timestamp = g_date_time_format_iso8601(now);
  fl_value_set_string_take(result, "timestamp", fl_value_new_string(timestamp));

  fl_value_set_string_take(result, "additionalData", fl_value_ref(additional_data));

  self->cached_data = fl_value_ref(result);
  return fl_value_ref(result);
}

// Called when a method call is received from Flutter
static void client_info_plugin_handle_method_call(
    ClientInfoPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getData") == 0) {
    g_autoptr(FlValue) result = get_data(self);
    if (result != nullptr) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "ERROR", "Failed to get data", nullptr));
    }
  } else if (strcmp(method, "refresh") == 0) {
    if (self->cached_data != nullptr) {
      fl_value_unref(self->cached_data);
      self->cached_data = nullptr;
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void client_info_plugin_dispose(GObject* object) {
  ClientInfoPlugin* self = CLIENT_INFO_PLUGIN(object);
  if (self->cached_data != nullptr) {
    fl_value_unref(self->cached_data);
    self->cached_data = nullptr;
  }
  G_OBJECT_CLASS(client_info_plugin_parent_class)->dispose(object);
}

static void client_info_plugin_class_init(ClientInfoPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = client_info_plugin_dispose;
}

static void client_info_plugin_init(ClientInfoPlugin* self) {
  self->cached_data = nullptr;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  ClientInfoPlugin* plugin = CLIENT_INFO_PLUGIN(user_data);
  client_info_plugin_handle_method_call(plugin, method_call);
}

void client_info_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ClientInfoPlugin* plugin = CLIENT_INFO_PLUGIN(
      g_object_new(client_info_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                           "app_client_info",
                           FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                           g_object_ref(plugin),
                                           g_object_unref);

  g_object_unref(plugin);
}
