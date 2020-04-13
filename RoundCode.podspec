Pod::Spec.new do |s|
  s.name             = 'RoundCode'
  s.version          = '1.0.0'
  s.summary          = 'Facebook messenger style custom barcode.'
  s.description      = <<-DESC
                     Facebook messenger style custom barcode.
                     DESC
  s.homepage         = 'https://github.com/aslanyanhaik/RoundCode'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Haik Aslanyan' => 'aslanyanhaik@gmail.com' }
  s.source           = { :git => 'https://github.com/aslanyanhaik/RoundCode', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'UIKit'
  s.social_media_url = 'http://twitter.com/aslanyanhaik'
  s.swift_versions = ['5.1', '5.2']
end
