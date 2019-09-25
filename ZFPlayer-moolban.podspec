#
# Be sure to run `pod lib lint ZFPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'ZFPlayer-moolban'
    s.version          = '3.1.4.3'
    s.summary          = 'A good player made by renzifeng'
    s.homepage         = 'https://github.com/rws08/ZFPlayer-moolban'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'renzifeng' => 'zifeng1300@gmail.com' }
    s.source           = { :git => 'https://github.com/rws08/ZFPlayer-moolban.git', :tag => s.version.to_s }
    s.social_media_url = 'http://weibo.com/zifeng1300'
    s.ios.deployment_target = '7.0'
    s.requires_arc = true
    
    s.default_subspec = 'Core'
    
    s.subspec 'Core' do |core|
        core.source_files = 'ZFPlayer-moolban/Classes/Core/**/*'
        core.public_header_files = 'ZFPlayer-moolban/Classes/Core/**/*.h'
        core.frameworks = 'UIKit', 'MediaPlayer', 'AVFoundation'
    end
    
    s.subspec 'ControlView' do |controlView|
        controlView.source_files = 'ZFPlayer-moolban/Classes/ControlView/**/*.{h,m}'
        controlView.public_header_files = 'ZFPlayer-moolban/Classes/ControlView/**/*.h'
        controlView.resource = 'ZFPlayer-moolban/Classes/ControlView/ZFPlayer.bundle'
        controlView.dependency 'ZFPlayer-moolban/Core'
    end
    
    s.subspec 'AVPlayer' do |avPlayer|
        avPlayer.source_files = 'ZFPlayer-moolban/Classes/AVPlayer/**/*.{h,m}'
        avPlayer.public_header_files = 'ZFPlayer-moolban/Classes/AVPlayer/**/*.h'
        avPlayer.dependency 'ZFPlayer-moolban/Core'
    end
    
end
