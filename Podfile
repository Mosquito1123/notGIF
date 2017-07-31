source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def groupPods
    
    pod 'MBProgressHUD', '~> 1.0'
    pod 'RealmSwift', '~> 2.9'

end

def mainPods
	
    pod 'SnapKit', '~> 3.2'
    pod 'ReachabilitySwift', '~> 3.0'
	pod 'IQKeyboardManagerSwift', '~> 4.0'
    pod 'Buglife',  '~> 1.6'

end

target 'notGIF' do
    
    groupPods
    mainPods

end

target 'notGIFMessage' do
    
    groupPods

end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '3.0'
#        end
#    end
#end
