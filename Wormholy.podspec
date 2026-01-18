Pod::Spec.new do |s|
  s.name         = "Wormholy"
  s.version      = "2.2.0"
  s.summary      = "Network debugging made easy"
  s.description  = <<-DESC
    Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  DESC
  s.homepage     = "https://github.com/pmusolino/Wormholy"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Paolo Musolino" => "info@codeido.com" }
  s.social_media_url   = "https://www.x.com/pmusolino"
  s.ios.deployment_target = "16.0"
  s.source       = { :git => "https://github.com/pmusolino/Wormholy.git", :tag => s.version.to_s }
  s.swift_version = "5.0"
  s.frameworks  = "Foundation", "UIKit", "SwiftUI"
  
  # Include WormholySwift by default
  s.default_subspecs = ['WormholyObjC', 'WormholySwift']

  s.subspec 'WormholySwift' do |ss|
    ss.source_files = 'Sources/WormholySwift/**/*.{swift}'
  end
  
  s.subspec 'WormholyObjC' do |ss|
    ss.source_files = 'Sources/WormholyObjC/**/*'
    ss.dependency 'Wormholy/WormholySwift'
    ss.public_header_files = 'Sources/WormholyObjC/**/*.h'
    ss.exclude_files = 'Sources/WormholyObjC/module.modulemap'
  end
end
