
Pod::Spec.new do |s|
  s.name         = "RNReactNativeSquareReaderSdk"
  s.version      = "1.0.0"
  s.summary      = "RNReactNativeSquareReaderSdk"
  s.homepage     = "https://github.com/SudoPlz/react-native-sp-reader-sdk"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "sudoplz@gmail.com" }
  s.platform = :ios, "8.0"
  s.source       = { :git => "https://github.com/SudoPlz/react-native-sp-reader-sdk.git", :tag => "master" }
  s.source_files = "ios/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end
