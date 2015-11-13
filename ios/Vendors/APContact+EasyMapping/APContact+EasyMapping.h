//
//  APContact+EasyMapping.h
//  APContact+EasyMappingDemo
//
//  Created by Jean Lebrument on 11/7/15.
//  Copyright © 2015 Jean Lebrument. All rights reserved.
//

#import <Foundation/Foundation.h>
<<<<<<< HEAD
#import <APAddressBook/APAddressBook.h>
#import <APAddressBook/APContact.h>
#import <EasyMapping/EasyMapping.h>
=======
#import "APAddressBook.h"
#import "APContact.h"
#import "EasyMapping.h"
>>>>>>> origin/feature/moreInfosFromUser

@interface APContact (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APName (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APJob (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APPhone (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APEmail (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APAddress (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APSocialProfile (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APRelatedPerson (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APSource (APContact_EasyMapping) <EKMappingProtocol>

@end

@interface APRecordDate (APContact_EasyMapping) <EKMappingProtocol>

@end