Pod::Spec.new do |s|
  s.name = "HappyTwitterKit"
  s.version = "1.0.0"
  s.summary = "Increase user engagement and app growth."
  s.homepage = "https://github.com/twitter/twitter-kit-ios"
  s.documentation_url = "https://github.com/twitter/twitter-kit-ios/wiki"
  s.social_media_url = "https://twitter.com/TwitterDev"
  s.authors = {"pcjbird" => "pcjbird@hotmail.com"}
  s.platform = :ios, "9.0"
  s.source = { :http => "https://github.com/pcjbird/HappyTwitterKit/releases/download/v#{s.version}/TwitterKit.zip" }
  s.vendored_frameworks = "TwitterKit.framework"
  s.license = { :type => "Commercial", :text => "Twitter Kit: Copyright Twitter, Inc. All Rights Reserved. Use of this software is subject to the terms and conditions of the Twitter Kit Agreement located at https://dev.twitter.com/overview/terms/twitterkit and the Developer Agreement located at https://dev.twitter.com/overview/terms/agreement. OSS: https://github.com/twitter/twitter-kit-ios/blob/master/OS_LICENSES.md"}
  s.resources = ["TwitterKitResources.bundle"]
  s.frameworks = "CoreText", "QuartzCore", "CoreData", "CoreGraphics", "Foundation", "Security", "UIKit", "CoreMedia", "AVFoundation", "SafariServices", "WebKit", "MapKit", "MobileCoreServices", "CoreLocation"
  s.dependency "HappyTwitterCore"
end