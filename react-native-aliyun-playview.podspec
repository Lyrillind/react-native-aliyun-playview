require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']

  s.authors      = { 'Lyrillind' => 'Lyrillind@outlook.com' }
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/Lyrillind/react-native-aliyun-playview#dev" }
  s.source_files  = "ios/AliyunPlayView/**/*.{h,m}"

  s.dependency 'React'
  s.dependency 'VODUpload'
  s.dependency 'AliyunPlayer_iOS'
  s.dependency 'AliPlayerSDK_iOS'
end
