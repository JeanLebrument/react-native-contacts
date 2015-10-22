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
      [self retrieveContactsWithCallback:callback];
    } else {
      callback(@[@{@"type": @"permissionDenied"}, [NSNull null]]);
    }
  }];
}

- (void)retrieveContactsWithCallback:(RCTResponseSenderBlock) callback {
  APAddressBook *addressBook = [[APAddressBook alloc] init];
  
  addressBook.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name.lastName" ascending:YES]];
  addressBook.fieldsMask = APContactFieldAll;
  
  [addressBook loadContacts:^(NSArray<APContact *> * _Nullable apContacts, NSError * _Nullable error) {
    if (!error) {
      NSMutableArray *contacts = [NSMutableArray array];
      for (APContact *apContact in apContacts) {
        // RecordID
        NSMutableDictionary *contact = [NSMutableDictionary dictionary];
        
        [contact setValue:apContact.recordID forKey:@"recordID"];
        
        // Names
        [contact setValue:apContact.name.firstName forKey:@"givenName"];
        [contact setValue:apContact.name.lastName forKey:@"lastName"];
        [contact setValue:apContact.name.middleName forKey:@"middleName"];
        [contact setValue:apContact.name.compositeName forKey:@"compositeName"];
        
        // Job
        [contact setValue:apContact.job.jobTitle forKey:@"jobTitle"];
        [contact setValue:apContact.job.company forKey:@"company"];
        
        // Picture
        [contact setValue:[UIImagePNGRepresentation(apContact.thumbnail) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] forKey:@"thumbnail"];
        
        // Phone number
        NSMutableArray *phoneNumbers = [NSMutableArray array];
        
        for (APPhone *apPhone in apContact.phones) {
          NSMutableDictionary *phoneNumber = [NSMutableDictionary dictionary];
          
          [phoneNumber setValue:apPhone.number forKey:@"number"];
          [phoneNumber setValue:apPhone.localizedLabel forKey:@"label"];
          
          [phoneNumbers addObject:phoneNumber];
        }
        
        [contact setValue:phoneNumbers forKey:@"phoneNumbers"];
        
        // Email addresses
        NSMutableArray *emailAddresses = [NSMutableArray array];
        
        for (APEmail *apEmail in apContact.emails) {
          NSMutableDictionary *emailAddress = [NSMutableDictionary dictionary];
          
          [emailAddress setValue:apEmail.address forKey:@"email"];
          [emailAddress setValue:apEmail.localizedLabel forKey:@"label"];
          
          [emailAddresses addObject:emailAddress];
        }
        
        [contact setValue:emailAddresses forKey:@"emailAddresses"];
        
        // Addresses
        NSMutableArray *addresses = [NSMutableArray array];
        
        for (APAddress *apAddress in apContact.addresses) {
          NSMutableDictionary *address = [NSMutableDictionary dictionary];
          
          [address setValue:apAddress.street forKey:@"street"];
          [address setValue:apAddress.city forKey:@"city"];
          [address setValue:apAddress.state forKey:@"state"];
          [address setValue:apAddress.zip forKey:@"zip"];
          [address setValue:apAddress.country forKey:@"country"];
          [address setValue:apAddress.countryCode forKey:@"countryCode"];
          
          [addresses addObject:address];
        }
        
        [contact setValue:addresses forKey:@"addresses"];
        
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
              break;
            case APSocialNetworkLinkedIn:
              socialNetwork = @"linkedin";
              break;
            case APSocialNetworkFlickr:
              socialNetwork = @"flickr";
              break;
            case APSocialNetworkGameCenter:
              socialNetwork = @"gamecenter";
              break;
          }
          
          NSMutableDictionary *socialProfile = [NSMutableDictionary dictionary];
          
          [socialProfile setValue:socialNetwork forKey:@"socialNetwork"];
          [socialProfile setValue:apSocialProfile.username forKey:@"username"];
          [socialProfile setValue:apSocialProfile.userIdentifier forKey:@"userIdentifier"];
          [socialProfile setValue:[apSocialProfile.url absoluteString] forKey:@"url"];
          
          [socialProfiles addObject:socialProfile];
        }
        
        [contact setValue:socialProfiles forKey:@"socialProfiles"];
        
        // Birthday
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        [contact setValue:[formatter stringFromDate:apContact.birthday] forKey:@"birthday"];
        
        // Note
        [contact setValue:apContact.note forKey:@"note"];
        
        // Websites
        [contact setValue:apContact.websites forKey:@"websites"];
        
        // Related persons
        NSMutableArray *relatedPersons = [NSMutableArray array];
        
        for (APRelatedPerson *apRelatedPerson in apContact.relatedPersons) {
          NSMutableDictionary *relatedPersons = [NSMutableDictionary dictionary];
          [relatedPersons setValue:apRelatedPerson.name forKey:@"name"];
          [relatedPersons setValue:apRelatedPerson.localizedLabel forKey:@"label"];
        }
        
        [contact setValue:relatedPersons forKey:@"relatedPersons"];
        
        // Linked record IDs
        [contact setValue:apContact.linkedRecordIDs forKey:@"linkedRecordIDs"];
        
        // Source
        NSMutableDictionary *source = [NSMutableDictionary dictionary];
        
        [source setValue:apContact.source.sourceType forKey:@"sourceType"];
        [source setValue:apContact.source.sourceID forKey:@"sourceID"];
        
        [contact setValue:source forKey:@"source"];
        
        // Record date
        NSMutableDictionary *recordDate = [NSMutableDictionary dictionary];
        
        [recordDate setValue:[formatter stringFromDate:apContact.recordDate.creationDate] forKey:@"creationDate"];
        [recordDate setValue:[formatter stringFromDate:apContact.recordDate.modificationDate]forKey:@"modificationDate"];
        
        [contact setValue:recordDate forKey:@"recordDate"];
        
        [contacts addObject:contact];
      }
      
      callback(@[[NSNull null], contacts]);
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
