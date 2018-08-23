//
//  RCTACReaderSettingsDelegate.h
//
//  Created by SudoPlz on 21/06/2018.
//

#import <Foundation/Foundation.h>
@import SquareReaderSDK;

@interface RCTACReaderSettingsDelegate : NSObject <SQRDReaderSettingsControllerDelegate>
@property (copy) void (^onPresentSuccess) (SQRDReaderSettingsController *);
@property (copy) void (^onPresentFailure) (SQRDReaderSettingsController *, NSError*);

- (instancetype)initWithBlocksForSuccess: (void (^)(SQRDReaderSettingsController *)) successBlock
                              forFailure: (void (^)(SQRDReaderSettingsController*, NSError *)) failureBlock;
@end
