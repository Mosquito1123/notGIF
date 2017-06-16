source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def groupPods
    
    pod 'SnapKit'
    pod 'ReachabilitySwift'
    pod 'MBProgressHUD'
    pod 'RealmSwift'

end

def mainPods
	
	pod 'IQKeyboardManagerSwift', '~> 4.0.8'

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
