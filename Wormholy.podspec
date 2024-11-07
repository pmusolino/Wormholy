Pod::Spec.new do |s|
  s.name         = "Wormholy"
  s.version      = "2.0.0"
  s.summary      = "Network debugging made easy"
  s.description  = <<-DESC
    Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  DESC
  s.homepage     = "https://github.com/pmusolino/Wormholy"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Paolo Musolino" => "info@codeido.com" }
  s.social_media_url   = "https://twitter.com/pmusolino"
  s.ios.deployment_target = "12.0"
  s.source       = { :git => "https://github.com/pmusolino/Wormholy.git", :tag => s.version.to_s }
  s.swift_version = "5.0"
  s.frameworks  = "Foundation", "UIKit"
  
  # Include WormholySwift by default
  s.default_subspecs = ['WormholyObjC', 'WormholySwift']

  s.subspec 'WormholySwift' do |ss|
    ss.source_files = 'Sources/WormholySwift/**/*.{swift}'
    ss.resource_bundles = {
      'WormholyResources' => [
        'Sources/**/*.storyboard', 'Sources/**/*.xib'
      ]
    }
  end
  
  s.subspec 'WormholyObjC' do |ss|
    ss.source_files = 'Sources/WormholyObjC/**/*'
    ss.dependency 'Wormholy/WormholySwift'
    ss.public_header_files = 'Sources/WormholyObjC/**/*.h'
  end
end
