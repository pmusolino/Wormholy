Pod::Spec.new do |s|
  s.name         = "Wormholy"
  s.version      = "1.5.2"
  s.summary      = "Network debugging made easy"
  s.description  = <<-DESC
    A fork from the original project of Paolo Musolino ( https://github.com/pmusolino/Wormholy ) with some enhancements.
  DESC
  s.homepage     = "https://github.com/smarttuner/Wormholy"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Daniele Saitta" => "support@smarttuner.net" }
  s.social_media_url   = "https://twitter.com/smarttuner"
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/smarttuner/Wormholy.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*.{swift,h,m}"
  s.public_header_files = "Sources/**/*.h"
  s.resource_bundles = {
    'Wormholy' => ['Sources/**/*.storyboard', 'Sources/**/*.xib', 'Sources/**/*.{css,js}']
  }
  s.frameworks  = "Foundation"
end
