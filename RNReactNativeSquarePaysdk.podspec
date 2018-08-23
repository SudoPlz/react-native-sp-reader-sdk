
Pod::Spec.new do |s|
  s.name         = "RNReactNativeSquareReaderSdk"
  s.version      = "1.0.0"
  s.summary      = "RNReactNativeSquareReaderSdk"
  s.description  = <<-DESC
                  RNReactNativeSquareReaderSdk
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "sudoplz@gmail.com" }
  s.platform = :ios, "8.0"
  s.source       = { :git => "https://github.com/SudoPlz/react-native-square-readerSDK.git", :tag => "master" }
  s.source_files = "ios/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end
