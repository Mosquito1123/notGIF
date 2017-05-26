source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def pods
    pod 'SnapKit'
    pod 'ReachabilitySwift'
    pod 'MBProgressHUD'
    pod 'RealmSwift'
end

target ‘notGIF’ do
    
    pods

end

target 'notGIFMessage' do
    
    pods
    
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
