Pod::Spec.new do |s|
  s.name = 'PermissionScope'
  s.version = '1.1.1'
  s.license = 'MIT'
  s.summary = 'A Periscope-inspired way to ask for iOS permissions'
  s.homepage = 'https://github.com/nickoneill/PermissionScope'
  s.social_media_url = 'https://twitter.com/objctoswift'
  s.authors = { "Nick O'Neill" => 'nick.oneill@gmail.com' }
  s.source = { :git => 'https://github.com/nickoneill/PermissionScope.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'PermissionScope/*.swift'

  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files         = 'PermissionScope/*.{swift,h}'
  end

  s.subspec 'Motion' do |motion|
    motion.dependency 'PermissionScope/Core'
    motion.weak_framework       = 'CoreMotion'
    feature_flags               = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestMotionEnabled' }
    motion.pod_target_xcconfig  = feature_flags
    motion.user_target_xcconfig = feature_flags
  end

  s.subspec 'Bluetooth' do |bluetooth|
    bluetooth.dependency 'PermissionScope/Core'
    bluetooth.weak_framework       = 'CoreBluetooth'
    feature_flags               = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestBluetoothEnabled' }
    bluetooth.pod_target_xcconfig  = feature_flags
    bluetooth.user_target_xcconfig = feature_flags
  end

  s.subspec 'Location' do |location|
    location.dependency 'PermissionScope/Core'
    location.weak_framework       = 'CoreLocation'
    feature_flags                 = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestLocationEnabled' }
    location.pod_target_xcconfig  = feature_flags
    location.user_target_xcconfig = feature_flags
  end

  s.subspec 'Microphone' do |mic|
    mic.dependency 'PermissionScope/Core'
    mic.weak_framework       = 'AVFoundation'
    feature_flags            = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestMicrophoneEnabled' }
    mic.pod_target_xcconfig  = feature_flags
    mic.user_target_xcconfig = feature_flags
  end

  s.subspec 'PhotoLibrary' do |photo|
    photo.dependency 'PermissionScope/Core'
    photo.weak_framework       = 'Photos', 'AssetsLibrary'
    feature_flags              = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestPhotoLibraryEnabled' }
    photo.pod_target_xcconfig  = feature_flags
    photo.user_target_xcconfig = feature_flags
  end

  s.subspec 'Camera' do |cam|
    cam.dependency 'PermissionScope/Core'
    cam.weak_framework       = 'AVFoundation'
    feature_flags            = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestCameraEnabled' }
    cam.pod_target_xcconfig  = feature_flags
    cam.user_target_xcconfig = feature_flags
  end

  s.subspec 'Notifications' do |note|
    note.dependency 'PermissionScope/Core'
    note.weak_framework       = 'UIKit', 'UserNotifications'
    feature_flags             = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestNotificationsEnabled' }
    note.pod_target_xcconfig  = feature_flags
    note.user_target_xcconfig = feature_flags
  end

  s.subspec 'Contacts' do |contacts|
    contacts.dependency 'PermissionScope/Core'
    contacts.weak_framework       = 'Contacts', 'AddressBook'
    feature_flags                 = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestContactsEnabled' }
    contacts.pod_target_xcconfig  = feature_flags
    contacts.user_target_xcconfig = feature_flags
  end

  s.subspec 'Events' do |cal|
    cal.dependency 'PermissionScope/Core'
    cal.weak_framework       = 'EventKit'
    feature_flags            = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestEventsEnabled' }
    cal.pod_target_xcconfig  = feature_flags
    cal.user_target_xcconfig = feature_flags
  end

  s.subspec 'Reminders' do |rem|
    rem.dependency 'PermissionScope/Core'
    rem.weak_framework       = 'EventKit'
    feature_flags            = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'PermissionScopeRequestRemindersEnabled' }
    rem.pod_target_xcconfig  = feature_flags
    rem.user_target_xcconfig = feature_flags
  end

end
