
Pod::Spec.new do |s|
  s.name         = "RNReactNativeSquarePaysdk"
  s.version      = "1.0.0"
  s.summary      = "RNReactNativeSquarePaysdk"
  s.description  = <<-DESC
                  RNReactNativeSquarePaysdk
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform = :ios, "8.0"
  s.source       = { :git => "https://github.com/SudoPlz/react-native-square-paysdk.git", :tag => "master" }
  s.source_files = "ios/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end
