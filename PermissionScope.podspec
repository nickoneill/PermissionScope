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

  s.requires_arc = true
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |sub|
    sub.source_files = 'PermissionScope/*.swift'
  end

  s.subspec 'Bluetooth' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Bluetooth.swift'
  end
  
  s.subspec 'Camera' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Camera.swift'
  end
  
  s.subspec 'Contacts' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Contacts.swift'
  end

  s.subspec 'Events' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Events.swift'
  end

  s.subspec 'Location' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Location.swift'
  end
  
  s.subspec 'Microphone' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Microphone.swift'
  end

  s.subspec 'Motion' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Motion.swift'
  end
  
  s.subspec 'Notifications' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Notifications.swift'
  end

  s.subspec 'Photos' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Photos.swift'
  end

  s.subspec 'Reminders' do |sub|
    sub.source_files = 'PermissionScope/Extensions/PermissionScope+Reminders.swift'
  end
  
end


