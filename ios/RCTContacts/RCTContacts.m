#import <AddressBook/AddressBook.h>
#import <UIKit/UIKit.h>
#import "RCTContacts.h"
#import "APAddressBook.h"
#import "APContact.h"

@implementation RCTContacts

RCT_EXPORT_MODULE();

- (NSDictionary *)constantsToExport
{
  return @{
    @"PERMISSION_DENIED": @"denied",
    @"PERMISSION_AUTHORIZED": @"authorized",
    @"PERMISSION_UNDEFINED": @"undefined"
  };
}

RCT_EXPORT_METHOD(checkPermission:(RCTResponseSenderBlock) callback)
{
  int authStatus = ABAddressBookGetAuthorizationStatus();
  if ( authStatus == kABAuthorizationStatusDenied || authStatus == kABAuthorizationStatusRestricted){
    callback(@[[NSNull null], @"denied"]);
  } else if (authStatus == kABAuthorizationStatusAuthorized){
    callback(@[[NSNull null], @"authorized"]);
  } else { //ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
    callback(@[[NSNull null], @"undefined"]);
  }
}

RCT_EXPORT_METHOD(requestPermission:(RCTResponseSenderBlock) callback)
{
  APAddressBook *addressBook = [[APAddressBook alloc] init];
  
  [addressBook requestAccess:^(BOOL granted, NSError * _Nullable error) {
    [self checkPermission:callback];
  }];
}

RCT_EXPORT_METHOD(getAll:(RCTResponseSenderBlock) callback)
{
  APAddressBook *addressBook = [[APAddressBook alloc] init];
  
  [addressBook requestAccess:^(BOOL granted, NSError * _Nullable error) {
    if (granted) {
      [self retrieveContactsFromAddressBookWithCallback:callback];
    } else {
      callback(@[@{@"type": @"permissionDenied"}, [NSNull null]]);
    }
  }];
}

- (void)retrieveContactsWithCallback:(RCTResponseSenderBlock) callback {
  NSMutableArray *contacts = [NSMutableArray array];
  APAddressBook *addressBook = [[APAddressBook alloc] init];
  
  addressBook.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
  addressBook.fieldsMask = APContactFieldAll;
  
  [addressBook loadContacts:^(NSArray<APContact *> * _Nullable apContacts, NSError * _Nullable error) {
    if (!error) {
      NSMutableArray *contacts = [NSMutableArray array];
      for (APContact *apContact in apContacts) {
        // RecordID
        NSMutableDictionary *contact = [NSMutableDictionary dictionary];
        
        [contact setObject:apContact.recordID forKey:@"recordID"];
        
        // Names
        [contact setObject:apContact.name.firstName forKey:@"givenName"];
        [contact setObject:apContact.name.lastName forKey:@"lastName"];
        [contact setObject:apContact.name.middleName forKey:@"middleName"];
        [contact setObject:apContact.name.compositeName forKey:@"compositeName"];
        
        // Job
        [contact setObject:apContact.job.jobTitle forKey:@"jobTitle"];
        [contact setObject:apContact.job.company forKey:@"company"];
        
        // Picture
        [contact setObject:[UIImagePNGRepresentation(apContact.thumbnail) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] forKey:@"thumbnail"];
        
        // Phone number
        NSMutableArray *phoneNumbers = [NSMutableArray array];
        
        for (APPhone *apPhone in apContact.phones) {
          [phoneNumbers addObject:@{@"number": apPhone.number, @"label": apPhone.localizedLabel}];
        }
      
        [contact setObject:phoneNumbers forKey:@"phoneNumbers"];
        
        // Email addresses
        NSMutableArray *emailAddresses = [NSMutableArray array];
        
        for (APEmail *apEmail in apContact.emails) {
          [emailAddresses addObject:@{@"email": apEmail.address, @"label": apEmail.localizedLabel}];
        }
        
        [contact setObject:emailAddresses forKey:@"emailAddresses"];
        
        // Addresses
        NSMutableArray *addresses = [NSMutableArray array];
        
        for (APAddress *apAddress in apContact.addresses) {
          [addresses addObject:@{
            @"street": apAddress.street,
            @"city": apAddress.city,
            @"state": apAddress.state,
            @"zip": apAddress.zip,
            @"country": apAddress.country,
            @"countryCode": apAddress.countryCode
          }];
        }
        
        [contact setObject:addresses forKey:@"addresses"];
        
        // Social profiles
        NSMutableArray *socialProfiles = [NSMutableArray array];
        
        for (APSocialProfile *apSocialProfile in apContact.socialProfiles) {
          NSString *socialNetwork;
          switch (apSocialProfile.socialNetwork) {
          case APSocialNetworkUnknown:
            socialNetwork = @"unknown";
            break;
          case APSocialNetworkFacebook:
            socialNetwork = @"facebook";
            break;
          case APSocialNetworkTwitter:
            socialNetwork = @"twitter";
          case APSocialNetworkLinkedIn:
            socialNetwork = @"linkedin";
          case APSocialNetworkFlickr:
            socialNetwork = @"flickr";
          case APSocialNetworkGameCenter:
            socialNetwork = @"gamecenter";
          }
          
          [socialProfiles addObject:@{
            @"socialNetwork": socialNetwork,
            @"username": apSocialProfile.username,
            @"userIdentifier": apSocialProfile.userIdentifier,
            @"url": [apSocialProfile.url absoluteString]
          }];
        }
        
        [contact setObject:socialProfiles forKey:@"socialProfiles"];
        
        // Birthday
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        [contact setObject:[formatter stringFromDate:apContact.birthday] forKey:@"birthday"];
        
        // Note
        [contact setObject:apContact.note forKey:@"note"];
        
        // Websites
        [contact setObject:apContact.websites forKey:@"websites"];
        
        // Related persons
        NSMutableArray *relatedPersons = [NSMutableArray array];
        
        for (APRelatedPerson *apRelatedPerson in apContact.relatedPersons) {
          [relatedPersons addObject:@{
            @"name": apRelatedPerson.name,
            @"label": apRelatedPerson.localizedLabel
          }];
        }
        
        [contact setObject:relatedPersons forKey:@"relatedPersons"];
        
        // Linked record IDs
        [contact setObject:apContact.linkedRecordIDs forKey:@"linkedRecordIDs"];
        
        // Source
        [contact setObject:@{
          @"sourceType": apContact.source.sourceType,
          @"sourceID": apContact.source.sourceID
        } forKey:@"source"];
        
        // Record date
        [contact setObject:@{
          @"creationDate": [formatter stringFromDate:apContact.recordDate.creationDate],
          @"modificationDate": [formatter stringFromDate:apContact.recordDate.modificationDate]
        } forKey:@"recordDate"];
        
        [contacts addObject:contact];
      }
    }
  }];
}

RCT_EXPORT_METHOD(addContact:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback)
{
  //@TODO keep addressbookRef in singleton
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
  ABRecordRef newPerson = ABPersonCreate();

  CFErrorRef error = NULL;
  ABAddressBookAddRecord(addressBookRef, newPerson, &error);
  //@TODO error handling

  [self updateRecord:newPerson onAddressBook:addressBookRef withData:contactData completionCallback:callback];
}

RCT_EXPORT_METHOD(updateContact:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback)
{
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
  int recordID = (int)[contactData[@"recordID"] integerValue];
  ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
  [self updateRecord:record onAddressBook:addressBookRef withData:contactData completionCallback:callback];
}

-(void) updateRecord:(ABRecordRef)record onAddressBook:(ABAddressBookRef)addressBookRef withData:(NSDictionary *)contactData completionCallback:(RCTResponseSenderBlock)callback
{
  CFErrorRef error = NULL;
  NSString *givenName = [contactData valueForKey:@"givenName"];
  NSString *familyName = [contactData valueForKey:@"familyName"];
  NSString *middleName = [contactData valueForKey:@"middleName"];
  ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFStringRef) givenName, &error);
  ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFStringRef) familyName, &error);
  ABRecordSetValue(record, kABPersonMiddleNameProperty, (__bridge CFStringRef) middleName, &error);

  ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
  NSArray* phoneNumbers = [contactData valueForKey:@"phoneNumbers"];
  for (id phoneData in phoneNumbers) {
    NSString *label = [phoneData valueForKey:@"label"];
    NSString *number = [phoneData valueForKey:@"number"];

    if ([label isEqual: @"main"]){
      ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFStringRef) number, kABPersonPhoneMainLabel, NULL);
    }
    else if ([label isEqual: @"mobile"]){
      ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFStringRef) number, kABPersonPhoneMobileLabel, NULL);
    }
    else if ([label isEqual: @"iPhone"]){
      ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFStringRef) number, kABPersonPhoneIPhoneLabel, NULL);
    }
    else{
      ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFStringRef) number, (__bridge CFStringRef) label, NULL);
    }
  }
  ABRecordSetValue(record, kABPersonPhoneProperty, multiPhone, nil);
  CFRelease(multiPhone);

  ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
  NSArray* emails = [contactData valueForKey:@"emailAddresses"];
  for (id emailData in emails) {
    NSString *label = [emailData valueForKey:@"label"];
    NSString *email = [emailData valueForKey:@"email"];

    ABMultiValueAddValueAndLabel(multiEmail, (__bridge CFStringRef) email, (__bridge CFStringRef) label, NULL);
  }
  ABRecordSetValue(record, kABPersonEmailProperty, multiEmail, nil);
  CFRelease(multiEmail);

  ABAddressBookSave(addressBookRef, &error);
  if (error != NULL)
  {
    CFStringRef errorDesc = CFErrorCopyDescription(error);
    NSString *nsErrorString = (__bridge NSString *)errorDesc;
    callback(@[nsErrorString]);
    CFRelease(errorDesc);
  }
  else{
    callback(@[[NSNull null]]);
  }
}

RCT_EXPORT_METHOD(deleteContact:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback)
{
  CFErrorRef error = NULL;
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
  int recordID = (int)[contactData[@"recordID"] integerValue];
  ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
  ABAddressBookRemoveRecord(addressBookRef, record, &error);
  ABAddressBookSave(addressBookRef, &error);
  //@TODO handle error
  callback(@[[NSNull null], [NSNull null]]);
}

@end
