//
//  RCTACPaymentDelegate.m
//
//  Created by SudoPlz on 21/06/2018.
//

#import "RCTACPaymentDelegate.h"

@implementation RCTACPaymentDelegate

- (instancetype)initWithBlocksForSuccess: (void (^)(SQRDCheckoutResult *)) successBlock
                              forFailure: (void (^)(NSError *)) failureBlock
                         forCancellation: (void (^)(SQRDCheckoutController *)) cancellationBlock {
  self = [super init];
  if (self) {
    _didFinishCheckoutWithResult = successBlock;
    _didFailWithError = failureBlock;
    _didCancel = cancellationBlock;
  }
  return self;
}
- (void)checkoutController:(nonnull SQRDCheckoutController *)checkoutController didFailWithError:(nonnull NSError *)error {
  if (_didFailWithError != nil) {
    _didFailWithError(error);
  }
}

- (void)checkoutController:(nonnull SQRDCheckoutController *)checkoutController didFinishCheckoutWithResult:(nonnull SQRDCheckoutResult *)result {
  if (_didFinishCheckoutWithResult != nil) {
    _didFinishCheckoutWithResult(result);
  }
}

- (void)checkoutControllerDidCancel:(nonnull SQRDCheckoutController *)checkoutController {
  if (_didCancel != nil) {
    _didCancel(checkoutController);
  }
}

@end
