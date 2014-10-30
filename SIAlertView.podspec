Pod::Spec.new do |s|
  s.name     = 'SIAlertView'
  s.version  = '1.32'
  s.platform = :ios, '5.0'
  s.license  = 'MIT'
  s.summary  = 'An UIAlertView replacement.'
  s.homepage = 'https://github.com/qiaoxueshi/SIAlertView'
  s.author   = { 'Sumi Interactive' => 'developer@sumi-sumi.com' }
  s.source   = { :git => 'https://github.com/qiaoxueshi/SIAlertView.git',
                 :tag => '1.32' }

  s.description = 'An UIAlertView replacement with block syntax and fancy transition styles.'

  s.requires_arc = true
  s.framework    = 'QuartzCore'
  s.source_files = 'SIAlertView/*.{h,m}'
  s.resources    = 'SIAlertView/SIAlertView.bundle'
end
