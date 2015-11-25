Pod::Spec.new do |s|
  s.name         = "CorePaycoin"
  s.version      = "0.6.7"
  s.summary      = "CorePaycoin is an implementation of Paycoin protocol in Objective-C."
  s.description  = <<-DESC
                   CorePaycoin is a complete toolkit to work with Paycoin data structures.
                   DESC
  s.homepage     = "https://github.com/ligerzero459/CorePaycoin"
  s.license      = 'WTFPL'
  s.author       = { "Ryan Mottley" => "ligerzero459@gmail.com" }
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.source       = { :git => "https://github.com/ligerzero459/CorePaycoin.git", :tag => s.version.to_s }
  s.source_files = 'CorePaycoin'
  s.exclude_files = 'CorePaycoin/**/*+Tests.{h,m}'
  s.requires_arc = true
  s.framework    = 'Foundation'
  s.ios.framework = 'UIKit'
  s.osx.framework = 'AppKit'
  s.dependency 'OpenSSL-Universal', '1.0.1.j-2'
  s.dependency 'ISO8601DateFormatter'
end
