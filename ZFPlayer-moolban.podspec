Pod::Spec.new do |s|
    s.name         = 'ZFPlayer-moolban'
    s.version      = '2.1.6.9'
    s.summary      = 'A good player made by renzifeng'
    s.homepage     = 'https://github.com/rws08/ZFPlayer'
    s.license      = 'MIT'
    s.authors      = { 'renzifeng' => 'zifeng1300@gmail.com' }
    #s.platform     = :ios, '7.0'
    s.ios.deployment_target = '8.0'
    s.source       = { :git => 'https://github.com/rws08/ZFPlayer.git', :tag => s.version.to_s }
    s.source_files = 'ZFPlayer/**/*.{h,m}'
    s.resource     = 'ZFPlayer/ZFPlayer.bundle'
    s.framework    = 'UIKit','MediaPlayer'
    s.dependency 'Masonry'
    s.requires_arc = true
end
