Pod::Spec.new do |s|
  s.name         = "Wormholy"
  s.version      = "1.7.0"
  s.summary      = "Network debugging made easy"
  s.description  = <<-DESC
    Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  DESC
  s.homepage     = "https://github.com/pmusolino/Wormholy"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Paolo Musolino" => "info@codeido.com" }
  s.social_media_url   = "https://twitter.com/pmusolino"
  s.ios.deployment_target = "11.0"
  s.source       = { :git => "https://github.com/pmusolino/Wormholy.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*.{swift,h,m}"
  s.swift_version = "5.0"
  s.public_header_files = "Sources/**/*.h"
  s.resource_bundles = {
    'Wormholy' => ['Sources/**/*.storyboard', 'Sources/**/*.xib', 'Sources/**/*.{css,js}']
  }
  s.frameworks  = "Foundation"
end
