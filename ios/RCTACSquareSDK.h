#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#else
#import "RCTBridgeModule.h"
#import "RCTConvert.h"
#endif
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "RCTACPaymentDelegate.h"
#import "RCTACReaderSettingsDelegate.h"

@import SquareReaderSDK;

@interface RCTACSquareSDK :  NSObject <RCTBridgeModule, CLLocationManagerDelegate>
  @property (strong, nonatomic) SQRDReaderSDK* paySDK;
  @property (strong, nonatomic) SQRDCheckoutParameters* defaultPaymentParams;
  @property (strong, nonatomic) NSString* createdAtDateFormat;
+ (BOOL)requiresMainQueueSetup;
@end
