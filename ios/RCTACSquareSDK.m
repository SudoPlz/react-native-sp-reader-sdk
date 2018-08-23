#import "RCTACSquareSDK.h"

@interface RCTACSquareSDK() {
//  NSUInteger tenderType;
  RCTACPaymentDelegate* paymentDelegate;
  RCTACReaderSettingsDelegate* presentDelegate;
}
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) AVAudioSession *audioSession;
@end

@implementation RCTConvert (SQRDReaderSDKTransactionRequestTenderTypes)

RCT_ENUM_CONVERTER(SQRDAdditionalPaymentTypes,
   (@{
      @"SQRDAdditionalPaymentTypeManualCardEntry": @(SQRDAdditionalPaymentTypeManualCardEntry),
      @"SQRDAdditionalPaymentTypeCash": @(SQRDAdditionalPaymentTypeCash),
      @"SQRDAdditionalPaymentTypeOther": @(SQRDAdditionalPaymentTypeOther),
    }), SQRDAdditionalPaymentTypeManualCardEntry, integerValue)


@end


@implementation RCTACSquareSDK
@synthesize locationManager;
@synthesize audioSession;
@synthesize paySDK;
@synthesize defaultPaymentParams;

RCT_EXPORT_MODULE()

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self setupSquareInstance];
  }
  return self;
}

#pragma mark - REACT NATIVE UTIL METHODS:

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSDictionary *)constantsToExport
{
  return @{
     @"SQRDAdditionalPaymentTypeManualCardEntry": @(SQRDAdditionalPaymentTypeManualCardEntry),
     @"SQRDAdditionalPaymentTypeCash": @(SQRDAdditionalPaymentTypeCash),
     @"SQRDAdditionalPaymentTypeOther": @(SQRDAdditionalPaymentTypeOther),
  };
}


#pragma mark - REACT NATIVE EXPOSED METHODS:


#pragma mark initSdk()
RCT_EXPORT_METHOD(initSdk:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (paySDK == nil) {
    [self setupSquareInstance];
  }
  return resolve(@{});
}


#pragma mark requestPermissions()
RCT_EXPORT_METHOD(requestPermissions: (RCTPromiseResolveBlock)resolve
                            rejecter: (RCTPromiseRejectBlock)reject) {
  if (locationManager == nil) {
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
  }
//  CLAuthorizationStatus status = self.locationManager.authorizationStatus;
  
  
  NSMutableDictionary* propsToBeReturned = [[NSMutableDictionary alloc] init];
  
  CLAuthorizationStatus locAuthStatus = [CLLocationManager authorizationStatus];
  BOOL locationServicesEnabled = [CLLocationManager locationServicesEnabled];
  
  //Checking authorization status
  if (locationServicesEnabled == YES) {
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
      [locationManager requestWhenInUseAuthorization];
    }
  }
  
  if (locationServicesEnabled == NO || locAuthStatus == kCLAuthorizationStatusDenied) {
    propsToBeReturned[@"appLocationPermission"] = [NSNumber numberWithBool:NO];
    propsToBeReturned[@"appLocationStatus"] = [NSNumber numberWithInt:locAuthStatus];
    propsToBeReturned[@"deviceLocationEnabled"] = [NSNumber numberWithBool:locationServicesEnabled];
  } else {
    propsToBeReturned[@"appLocationPermission"] = [NSNumber numberWithBool:YES];
    propsToBeReturned[@"appLocationStatus"] = [NSNumber numberWithInt:locAuthStatus];
    propsToBeReturned[@"deviceLocationEnabled"] = [NSNumber numberWithBool:locationServicesEnabled];
  }
  
  audioSession = [AVAudioSession sharedInstance];
  if([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
    [audioSession requestRecordPermission:^(BOOL granted) {
        propsToBeReturned[@"appRecordingPermission"] = [NSNumber numberWithBool:granted];
        resolve(propsToBeReturned);
    }];
  } else {
    propsToBeReturned[@"appRecordingPermission"] = [NSNumber numberWithBool:YES];
    resolve(propsToBeReturned);
  }
}


#pragma mark authorizeWithCode(deviceCode)
RCT_EXPORT_METHOD(authorizeWithCode: (NSString*) deviceCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (paySDK != nil) {
      BOOL isLoggedIn = paySDK.isAuthorized;
      if (isLoggedIn == NO && deviceCode != nil) {
        [paySDK authorizeWithCode:deviceCode completionHandler:^(SQRDLocation * _Nullable location, NSError * _Nullable error) {
          if (error != nil) {
            reject([NSString stringWithFormat: @"%ld", error.code], error.localizedDescription, error);
          } else {
            NSMutableDictionary* response = [self locationToDictionary: location];
            [response setObject:[NSNumber numberWithBool:YES] forKey:@"success"];
            resolve(response);
          }
        }];
      } else {
        resolve(@{@"success":[NSNumber numberWithBool:YES]});
      }
    } else { // paySDK nil
      reject(@"", @"You haven't initialized paySDK. Run initSdk first.", nil);
    }
  });
}


#pragma mark isLoggedIn()
RCT_EXPORT_METHOD(isLoggedIn:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@{
    @"isLoggedIn": [NSNumber numberWithBool:paySDK != nil && paySDK.isAuthorized == YES]
  });
}

#pragma mark hasInit()
RCT_EXPORT_METHOD(hasInit:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@{@"hasInit": [NSNumber numberWithBool:paySDK != nil]});
}


#pragma mark deauthorize()
RCT_EXPORT_METHOD(deauthorize:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
    if (initializationErr == nil) {
      if (paySDK.canDeauthorize) {
        [paySDK deauthorizeWithCompletionHandler:^(NSError * _Nullable error) {
          if (error != nil) {
            reject([NSString stringWithFormat: @"%ld", error.code], error.localizedDescription, error);
          } else {
            resolve(@{});
          }
        }];
      }
    } else { // paySDK nil or not logged in
      reject(@"", initializationErr, nil);
    }
  });
}

#pragma mark getAuthorizedLocation()
RCT_EXPORT_METHOD(getAuthorizedLocation:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
    if (initializationErr == nil) {
      SQRDLocation* location = paySDK.authorizedLocation;
      if (location != nil) {
        resolve(@{
                  @"businessName": location.businessName,
                  @"name": location.name,
                  @"locationId": location.locationID,
                  @"maxCardPaymentAmount": [[NSNumber alloc] initWithInteger:location.maximumCardPaymentAmountMoney.amount],
                  @"minCardPaymentAmount": [[NSNumber alloc] initWithInteger:location.minimumCardPaymentAmountMoney.amount],
                  @"locationId": location.locationID,
        });
      } else {
        reject(@"", @"Location empty.", nil);
        
      }
    } else { // paySDK nil or not logged in
      reject(@"", initializationErr, nil);
    }
  });
}

#pragma mark setCheckoutParameters()
RCT_EXPORT_METHOD(setCheckoutParameters: (BOOL) tipsEnabled
                  // tipsEnabled: Enables tipping in the payment flow. Tips can only be added to credit card and Square gift card payments.
                  //                  Tipping is disabled by default.
                  withCustomTipField: (BOOL) customTipFieldVisible
                  // customTipFieldVisible: Display the option to enter a custom tip amount. Tipping must be enabled to allow custom tip amounts.
                  andListOfTipPercentages: (NSArray*) tipPercentages
                  //                  tipPercentages: Set tip percentages for the buyer during the payment flow. This list can contain up to three values, each of which must
                  //                  be a nonnegative integer, from 0 to 100, inclusive. The default tipping options are 15%, 20%, and 25%. Tipping must be
                  //                  enabled for these options to be displayed.
                  withSeparateTipScreenVisible: (BOOL) separateTipScreenVisible
                  // separateTipScreenVisible: Present the tip options on its own screen before presenting the signature screen during credit card transactions. By default,
                  //                  tip options are displayed on the signature screen.  Tipping must be enabled for this setting to take effect.
                  shouldSkipReceipt: (BOOL) skipReceipt
                  //                  skipReceipt:Do not present the receipt screen to the buyer. If the buyer has previously linked their payment method to their email address, he or
                  //                  she will still receive an email receipt.
                  shouldAlwaysRequireSignature: (BOOL) alwaysRequireSignature
                  //                  alwaysRequireSignature: Skip the signature screen if allowed. This is usually possible for transactions under $25, but it is subject to change depending on card
                  //                  brand.
                  allowSplitTender: (BOOL) allowSplitTender
                  //                  allowSplitTender: Allow multiple tenders to be used in a single transaction. The split tender option is disabled by default.
                  withAditionalPaymentTypes: (nonnull NSNumber*) additionalPaymentTypes
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  if (defaultPaymentParams == nil) {
    defaultPaymentParams = [[SQRDCheckoutParameters alloc] initWithAmountMoney:[[SQRDMoney alloc] initWithAmount: 0]];
  }
  
  @try {
    defaultPaymentParams.skipReceipt = skipReceipt;
    defaultPaymentParams.alwaysRequireSignature = alwaysRequireSignature;
    defaultPaymentParams.allowSplitTender = allowSplitTender;

    if (additionalPaymentTypes != nil && additionalPaymentTypes.intValue >= 0) {
      defaultPaymentParams.additionalPaymentTypes = additionalPaymentTypes.intValue;
    }

    if (tipsEnabled) {
      SQRDTipSettings* tipSettings = [[SQRDTipSettings alloc] init];
      tipSettings.showCustomTipField = customTipFieldVisible;
      tipSettings.showSeparateTipScreen = separateTipScreenVisible;
      if (tipPercentages != nil && tipPercentages.count > 0) {
        tipSettings.tipPercentages = tipPercentages;
      }
      defaultPaymentParams.tipSettings = tipSettings;
    } else {
      defaultPaymentParams.tipSettings = nil;
    }
    resolve(@{});
  } @catch (NSException *exception) {
    reject(@"", exception.description, nil);
  }
}

 
#pragma mark checkoutWithAmount(cents, note)
RCT_EXPORT_METHOD(checkoutWithAmount: (NSInteger) amountInCents
                  andNote: (NSString*) note
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock) reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
    if (initializationErr == nil) {
    
      SQRDLocation* location = paySDK.authorizedLocation;
      if (amountInCents > location.maximumCardPaymentAmountMoney.amount) {
        reject(@"square_amount_more_than_max_allowed", @"square_amount_more_than_max_allowed", nil);
        return;
      }
      
      if (amountInCents < location.minimumCardPaymentAmountMoney.amount) {
        reject(@"square_amount_less_than_min_allowed", @"square_amount_less_than_min_allowed", nil);
        return;
      }
      
      
      SQRDCheckoutParameters* curPaymentParams = [self getPaymentParamsForAmount: (int) amountInCents andNote:note];
      paymentDelegate = [[RCTACPaymentDelegate alloc] initWithBlocksForSuccess:^(SQRDCheckoutResult* result) {
        resolve(@{@"transaction": [self checkoutResultSerializer:result]});
      } forFailure:^(NSError * error) {
        reject([NSString stringWithFormat: @"%ld", error.code], error.localizedDescription, error);
      } forCancellation:^(SQRDCheckoutController * checkoutController) {
        reject(@"", @"Cancelled", nil);
      }];
      SQRDCheckoutController* controller = [[SQRDCheckoutController alloc] initWithParameters:curPaymentParams delegate:paymentDelegate];
      UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
      [controller presentFromViewController:root];
      
    } else { // paySDK nil or not logged in
      reject(@"", initializationErr, nil);
    }
  });
}



#pragma mark presentReaderSettingsScreen()
RCT_EXPORT_METHOD(presentReaderSettingsScreen:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
    if (initializationErr == nil) {
      UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
      
      presentDelegate = [[RCTACReaderSettingsDelegate alloc] initWithBlocksForSuccess:^(SQRDReaderSettingsController* readerSettingsController) {
        resolve(@{@"success":[NSNumber numberWithBool:YES]});
      } forFailure:^(SQRDReaderSettingsController* readerSettingsController, NSError *error) {
        if (error != nil) {
          reject([NSString stringWithFormat: @"%ld", error.code], error.localizedDescription, error);
        } else {
          reject(@"", @"Could not initialize the newReaderManagementView", nil);
        }
      }];
      SQRDReaderSettingsController* readerSettingsController = [[SQRDReaderSettingsController alloc] initWithDelegate:presentDelegate];
      [readerSettingsController presentFromViewController:root];
    } else { // paySDK nil or not logged in
      reject(@"", initializationErr, nil);
    }
  });
}

# pragma mark - Utilities


- (SQRDCheckoutParameters*) getPaymentParamsForAmount: (int) amount andNote: (NSString*) note {
  if (defaultPaymentParams == nil) {
    defaultPaymentParams = [[SQRDCheckoutParameters alloc] initWithAmountMoney:[[SQRDMoney alloc] initWithAmount: amount]];
  }
  SQRDCheckoutParameters* toBeReturned = [[SQRDCheckoutParameters alloc] initWithAmountMoney:[[SQRDMoney alloc] initWithAmount: amount]];
  toBeReturned.skipReceipt = defaultPaymentParams.skipReceipt;
  toBeReturned.alwaysRequireSignature = defaultPaymentParams.alwaysRequireSignature;
  toBeReturned.allowSplitTender = defaultPaymentParams.allowSplitTender;
  toBeReturned.additionalPaymentTypes = defaultPaymentParams.additionalPaymentTypes;
  toBeReturned.tipSettings = defaultPaymentParams.tipSettings;
  toBeReturned.note = note;
  return toBeReturned;
}

- (NSDictionary*) checkoutResultSerializer: (SQRDCheckoutResult*) result {
  NSMutableDictionary* resultObj = [[NSMutableDictionary alloc] init];
  if (result) {
    if (result.transactionID != nil) {
      resultObj[@"transactionID"] = result.transactionID;
    }
    
    if (result.transactionClientID != nil) {
      resultObj[@"transactionClientID"] = result.transactionClientID;
    }
    
    if (result.locationID != nil) {
      resultObj[@"locationID"] = result.locationID;
    }
    
    if (result.createdAt != nil) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:_createdAtDateFormat];
      resultObj[@"createdAt"] = [dateFormatter stringFromDate:result.createdAt];
    }
    
    if (result.totalMoney != nil) {
      resultObj[@"totalMoneyAmount"] = [NSNumber numberWithFloat:result.totalMoney.amount];
      NSString* currencyCode = SQRDCurrencyCodeGetISOCurrencyCode(result.totalMoney.currencyCode);
      if (currencyCode != nil) {
        resultObj[@"totalMoneyCurrency"] = currencyCode;
      }
    }
    
    if (result.totalTipMoney != nil) {
      resultObj[@"totalTipMoneyAmount"] = [NSNumber numberWithFloat:result.totalTipMoney.amount];
      NSString* currencyCode = SQRDCurrencyCodeGetISOCurrencyCode(result.totalTipMoney.currencyCode);
      if (currencyCode != nil) {
        resultObj[@"totalTipMoneyCurrency"] = currencyCode;
      }
    }
    
    if (result.tenders && result.tenders.count > 0) {
      resultObj[@"tenderCnt"] = [NSNumber numberWithInt:(int) result.tenders.count];
    }
    
  }
  return resultObj;
}

- (NSMutableDictionary*) locationToDictionary: (SQRDLocation*) location {
  NSMutableDictionary* toBeReturned = [[NSMutableDictionary alloc] init];
  if (location != nil) {
    if (location.locationID != nil) {
      [toBeReturned setObject:location.locationID forKey:@"locationID"];
    }
    
    if (location.name != nil) {
      [toBeReturned setObject:location.name forKey:@"name"];
    }
    
    if (location.name != nil) {
      [toBeReturned setObject:location.businessName forKey:@"businessName"];
    }
    
    if (location.name != nil) {
      [toBeReturned setObject:[NSNumber numberWithBool:location.isCardProcessingActivated] forKey:@"isCardProcessingActivated"];
    }
    
    if (location.minimumCardPaymentAmountMoney != nil) {
      [toBeReturned setObject:[NSNumber numberWithLong:location.minimumCardPaymentAmountMoney.amount] forKey:@"minimumCardPaymentAmountMoney"];
    }
    
    if (location.maximumCardPaymentAmountMoney != nil) {
      [toBeReturned setObject:[NSNumber numberWithLong:location.maximumCardPaymentAmountMoney.amount] forKey:@"maximumCardPaymentAmountMoney"];
    }
    
    NSString* currencyCode = SQRDCurrencyCodeGetISOCurrencyCode(location.currencyCode);
    if (currencyCode != nil) {
      [toBeReturned setObject:currencyCode forKey:@"currencyCode"];
    }
  }
  return toBeReturned;
}

- (NSString*) returnErrorIfNotInitializedAndLoggedIn {
  if (paySDK == nil) {
    return @"You haven't initialized paySDK. Run initSdk first.";
  } else {
    if (paySDK.isAuthorized == NO) {
      return @"You have not logged in yet. Run authorizeWithCode first.";
    }
  }
  return nil;
}


- (void) setupSquareInstance {
  if (paySDK == nil) {
    @try {
      paySDK = [SQRDReaderSDK sharedSDK];
    } @catch(NSException *exception) {
      NSLog(@"Couldn't initialise SQRDReaderSDK: %@", exception);
    }
    defaultPaymentParams = [[SQRDCheckoutParameters alloc] initWithAmountMoney:[[SQRDMoney alloc] initWithAmount: 0]];
    _createdAtDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
  }
}
@end

