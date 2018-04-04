
#import "RNReactNativeSquarePaysdk.h"

@interface RNReactNativeSquarePaysdk() {
    NSUInteger tenderType;
}
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) AVAudioSession *audioSession;
@end

@implementation RCTConvert (PaySDKTransactionRequestTenderTypes)

RCT_ENUM_CONVERTER(PaySDKTransactionRequestTenderTypes,
                   (@{
                      @"PaySDKTransactionRequestTenderTypeAll": @(PaySDKTransactionRequestTenderTypeAll),
                      @"PaySDKTransactionRequestTenderTypeCardFromReader": @(PaySDKTransactionRequestTenderTypeCardFromReader),
                      @"PaySDKTransactionRequestTenderTypeKeyedInCard": @(PaySDKTransactionRequestTenderTypeKeyedInCard),
                      @"PaySDKTransactionRequestTenderTypeCash": @(PaySDKTransactionRequestTenderTypeCash),
                      @"PaySDKTransactionRequestTenderTypeOther": @(PaySDKTransactionRequestTenderTypeOther),
                      @"PaySDKTransactionRequestTenderTypeSquareGiftCard": @(PaySDKTransactionRequestTenderTypeSquareGiftCard),
                      @"PaySDKTransactionRequestTenderTypeCardOnFile": @(PaySDKTransactionRequestTenderTypeCardOnFile),
                      }), PaySDKTransactionRequestTenderTypeAll, integerValue)

@end


@implementation RNReactNativeSquarePaysdk
@synthesize locationManager;
@synthesize audioSession;
@synthesize paySDK;
@synthesize flowConfig;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()


- (NSDictionary *)constantsToExport
{
    return @{
             @"PaySDKTransactionRequestTenderTypeAll": @(PaySDKTransactionRequestTenderTypeAll),
             @"PaySDKTransactionRequestTenderTypeCardFromReader": @(PaySDKTransactionRequestTenderTypeCardFromReader),
             @"PaySDKTransactionRequestTenderTypeKeyedInCard": @(PaySDKTransactionRequestTenderTypeKeyedInCard),
             @"PaySDKTransactionRequestTenderTypeCash": @(PaySDKTransactionRequestTenderTypeCash),
             @"PaySDKTransactionRequestTenderTypeOther": @(PaySDKTransactionRequestTenderTypeOther),
             @"PaySDKTransactionRequestTenderTypeSquareGiftCard": @(PaySDKTransactionRequestTenderTypeSquareGiftCard),
             @"PaySDKTransactionRequestTenderTypeCardOnFile": @(PaySDKTransactionRequestTenderTypeCardOnFile),
             };
}

#pragma mark -
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

#pragma mark initWithApplicationID(appId)
RCT_EXPORT_METHOD(initWithApplicationID: (NSString*) appID
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    tenderType = PaySDKTransactionRequestTenderTypeAll;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* defaultWindow = [[[UIApplication sharedApplication] delegate] window];
        @try {
            paySDK = [PaySDK sharedSDK];
        } @catch(NSException *exception) {
            [PaySDK initializeWithApplicationID:appID defaultWindow:defaultWindow];
            paySDK = [PaySDK sharedSDK];
        }
        flowConfig = PaySDKPaymentFlowConfiguration.defaultConfiguration;
        _createdAtDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        //  flowConfig.tipPercentages
        resolve(@{});
    });
}

#pragma mark loginWithDeviceCode(deviceCode)
RCT_EXPORT_METHOD(loginWithDeviceCode: (NSString*) deviceCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (paySDK != nil) {
            BOOL isLoggedIn = paySDK.isLoggedIn;
            if (isLoggedIn == NO) {
                PaySDKLoginRequest* loginReq = [paySDK loginRequestWithDeviceCode:deviceCode];
                [loginReq performWithCompletionHandler:^(NSError* error) {
                    if (error != nil) {
                        reject(@"0", error.localizedDescription, error);
                    } else {
                        resolve(@{@"success":[NSNumber numberWithBool:YES]});
                    }
                }];
            } else {
                resolve(@{@"success":[NSNumber numberWithBool:YES]});
            }
        } else { // paySDK nil
            reject(@"1", @"You haven't initialized paySDK. Run initWithApplicationID first.", nil);
        }
    });
}

#pragma mark isLoggedIn()
RCT_EXPORT_METHOD(isLoggedIn:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve(@{
              @"isLoggedIn": [NSNumber numberWithBool:paySDK.isLoggedIn == YES],
              @"hasInit": [NSNumber numberWithBool:paySDK!=nil]
              });
}

RCT_EXPORT_METHOD(hasInit:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve(@{@"hasInit": [NSNumber numberWithBool:paySDK!=nil]});
}


#pragma mark logout()
RCT_EXPORT_METHOD(logout) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
        if (initializationErr == nil) {
            [paySDK logout];
            
        }
    });
}

#pragma mark transactionRequestWithCentsAmount(cents, note, customerId)
RCT_EXPORT_METHOD(transactionRequestWithCentsAmount: (NSUInteger) cents
                  andNote: (NSString*) note
                  andCustomerID: (NSString*) customerID
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock) reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
        if (initializationErr == nil) {
            PaySDKTransactionRequest* transaction = [paySDK transactionRequestWithCentsAmount:cents
                                                                                  tenderTypes:tenderType
                                                                     paymentFlowConfiguration:flowConfig
                                                                                         note:note
                                                                                   customerID:customerID];
            [transaction startTransactionWithSuccessHandler:^(PaySDKTransaction *transaction) {
                resolve(@{
                          @"transaction": [self transactionSerializer:transaction]});
            } errorHandler:^(NSError * error) {
                reject(@"2", error.localizedDescription, error);
            } cancellationHandler:^{
                reject(@"2", @"Cancelled", nil);
            }];
        } else { // paySDK nil or not logged in
            reject(@"1", initializationErr, nil);
        }
    });
}

#pragma mark presentNewReaderScreenWithAnimation(animated)
RCT_EXPORT_METHOD(presentNewReaderScreenWithAnimation: (BOOL) animated
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* initializationErr = [self returnErrorIfNotInitializedAndLoggedIn];
        if (initializationErr == nil) {
            UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            
            NSError* newReaderViewErr;
            UINavigationController* readerManagementViewController = [paySDK newReaderManagementViewControllerWithError:&newReaderViewErr];
            if (root != nil && readerManagementViewController != nil && newReaderViewErr == nil) {
                [root presentViewController:readerManagementViewController animated:animated completion:^{
                    resolve(@{@"success":[NSNumber numberWithBool:YES]});
                }];
            } else if (newReaderViewErr != nil){
                reject(@"3", newReaderViewErr.localizedDescription, newReaderViewErr);
            } else {
                reject(@"3", @"Could not initialize the newReaderManagementView", nil);
            }
        } else { // paySDK nil or not logged in
            reject(@"1", initializationErr, nil);
        }
    });
}

#pragma mark -
- (NSDictionary*) transactionSerializer: (PaySDKTransaction*) transaction {
    NSMutableDictionary* transactionObj = [[NSMutableDictionary alloc] init];
    if (transaction) {
        if (transaction.clientID != nil) {
            transactionObj[@"clientID"] = transaction.clientID;
        }
        
        if (transaction.serverID != nil) {
            transactionObj[@"serverID"] = transaction.serverID;
        }
        
        if (transaction.locationID != nil) {
            transactionObj[@"locationID"] = transaction.locationID;
        }
        
        if (transaction.createdAt != nil) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:_createdAtDateFormat];
            transactionObj[@"createdAt"] = [dateFormatter stringFromDate:transaction.createdAt];
        }
        
        if (transaction.order != nil) {
            NSMutableDictionary* orderObj = [[NSMutableDictionary alloc] init];
            PaySDKOrder* order = transaction.order;
            if (order) {
                PaySDKMoney* totalMoney = order.totalMoney;
                if (totalMoney) {
                    orderObj[@"totalMoneyAmount"] = [NSNumber numberWithFloat:totalMoney.amount];
                    orderObj[@"totalMoneyCurrency"] = totalMoney.currency;
                }
                PaySDKMoney* totalTaxMoney = order.totalTaxMoney;
                if (totalTaxMoney) {
                    orderObj[@"totalTaxMoneyAmount"] = [NSNumber numberWithFloat:totalTaxMoney.amount];
                    orderObj[@"totalTaxMoneyCurrency"] = totalTaxMoney.currency;
                }
                PaySDKMoney* totalTipMoney = order.totalTipMoney;
                if (totalTipMoney) {
                    orderObj[@"totalTipMoneyAmount"] = [NSNumber numberWithFloat:totalTipMoney.amount];
                    orderObj[@"totalTipMoneyCurrency"] = totalTipMoney.currency;
                }
            }
            transactionObj[@"order"] = orderObj;
        }
        
        if (transaction.tenders && transaction.tenders.count > 0) {
            transactionObj[@"tenderCnt"] = [NSNumber numberWithInt:(int) transaction.tenders.count];
        }
        
    }
    return transactionObj;
}


- (NSString*) returnErrorIfNotInitializedAndLoggedIn {
    if (paySDK == nil) {
        return @"You haven't initialized paySDK. Run initWithApplicationID first.";
    } else {
        if (paySDK.isLoggedIn == NO) {
            return @"You have not logged in yet. Run loginWithDeviceCode first.";
        }
    }
    return nil;
}


RCT_EXPORT_METHOD(setFlowConfig: (BOOL) tipsEnabled
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
                  shouldSkipSignature: (BOOL) skipSignature
                  //                  skipSignature: Skip the signature screen if allowed. This is usually possible for transactions under $25, but it is subject to change depending on card
                  //                  brand.
                  allowSplitTender: (BOOL) allowSplitTender
                  //                  allowSplitTender: Allow multiple tenders to be used in a single transaction. The split tender option is disabled by default.
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if (flowConfig == nil) {
        flowConfig = PaySDKPaymentFlowConfiguration.defaultConfiguration;
    }
    
    @try {
        flowConfig.enableTipping = tipsEnabled;
        flowConfig.showCustomTipField = customTipFieldVisible;
        flowConfig.showSeparateTipScreen = separateTipScreenVisible;
        flowConfig.skipReceipt = skipReceipt;
        flowConfig.skipSignature = skipSignature;
        flowConfig.allowSplitTender = allowSplitTender;
        if (tipPercentages != nil && tipPercentages.count > 0) {
            flowConfig.tipPercentages = tipPercentages;
        }
        resolve(@{});
    } @catch (NSException *exception) {
        reject(@"1", exception.description, nil);
    }
}

RCT_EXPORT_METHOD(setTenderType: (int) newTenderType
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    tenderType = newTenderType;
    resolve(@{});
}
@end

