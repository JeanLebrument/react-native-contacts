<<<<<<< HEAD
Pod::Spec.new do |s|

    s.name                  = "react-native-contacts"
    s.version               = "0.1.4"
    s.summary               = "react-native-contacts"

    s.homepage              = "https://github.com/jeanlebrument/react-native-contacts"

    s.author                = { "Jean Lebrument" => "jean@vimies.com" }

    s.platform              = :ios, '7.1'

    s.source                = { :git => "https://github.com/jeanlebrument/react-native-contacts", :tag => s.version.to_s }

    s.source_files          = 'ios/RCTContacts/*.{h,m,swift}'

    s.dependency            'APAddressBook'
    s.dependency            'APContactEasyMapping'
    s.dependency            'EasyMapping'

end
