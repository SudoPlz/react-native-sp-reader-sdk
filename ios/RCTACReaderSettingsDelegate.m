//
//  RCTACReaderSettingsDelegate.m
//
//  Created by SudoPlz on 21/06/2018.
//

#import "RCTACReaderSettingsDelegate.h"

@implementation RCTACReaderSettingsDelegate
- (instancetype)initWithBlocksForSuccess: (void (^)(SQRDReaderSettingsController *)) successBlock
                              forFailure: (void (^)(SQRDReaderSettingsController*, NSError *)) failureBlock {
  self = [super init];
  if (self) {
    _onPresentSuccess = successBlock;
    _onPresentFailure = failureBlock;
  }
  return self;
}

- (void)readerSettingsController:(nonnull SQRDReaderSettingsController *)readerSettingsController didFailToPresentWithError:(nonnull NSError *)error {
  if (_onPresentFailure != nil) {
    _onPresentFailure(readerSettingsController, error);
  }
}

- (void)readerSettingsControllerDidPresent:(nonnull SQRDReaderSettingsController *)readerSettingsController {
  if (_onPresentSuccess != nil) {
    _onPresentSuccess(readerSettingsController);
  }
}

@end
