#import <AddressBook/AddressBook.h>
#import <UIKit/UIKit.h>
#import "RCTContacts.h"
#import "APAddressBook.h"
#import "APContact.h"
#import "EasyMapping.h"
#import "APContact+EasyMapping.h"

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
      NSArray *serializedContacts = [EKSerializer serializeCollection:contacts withMapping:[APContact objectMapping]];
      
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
