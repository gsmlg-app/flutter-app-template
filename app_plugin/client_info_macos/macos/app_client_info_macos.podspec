Pod::Spec.new do |s|
  s.name             = 'app_client_info_macos'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation of app_client_info'
  s.description      = <<-DESC
macOS implementation of app_client_info plugin.
                       DESC
  s.homepage         = 'https://github.com/app'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'GSMLG Team' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
