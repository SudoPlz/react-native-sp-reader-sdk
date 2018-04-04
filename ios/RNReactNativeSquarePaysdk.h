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

@import SquarePaymentSDK;

@interface RNReactNativeSquarePaysdk : NSObject <RCTBridgeModule, CLLocationManagerDelegate>
@property (strong, nonatomic) PaySDK* paySDK;
@property (strong, nonatomic) PaySDKPaymentFlowConfiguration* flowConfig;
@property (strong, nonatomic) NSString* createdAtDateFormat;
@end
