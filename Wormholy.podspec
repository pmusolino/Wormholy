Pod::Spec.new do |s|
  s.name         = "Wormholy"
  s.version      = "1.2.2"
  s.summary      = "Network debugging made easy"
  s.description  = <<-DESC
    Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  DESC
  s.homepage     = "https://github.com/jihongboo/Wormholy"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Zac ji" => "jihongboo@qq.com" }
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/jihongboo/Wormholy.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*.{swift,h,m}"
  s.public_header_files = "Sources/**/*.h"
  s.resource_bundles = {
    'Wormholy' => ['Sources/**/*.storyboard', 'Sources/**/*.xib', 'Sources/**/*.{css,js}']
  }
  s.frameworks  = "Foundation"
end
