//
//  RCTACPaymentDelegate.h
//
//  Created by SudoPlz on 21/06/2018.
//

#import <Foundation/Foundation.h>
@import SquareReaderSDK;


@interface RCTACPaymentDelegate : NSObject <SQRDCheckoutControllerDelegate> {
  
}
@property (copy) void (^didFailWithError) (NSError *);
@property (copy) void (^didFinishCheckoutWithResult) (SQRDCheckoutResult *);
@property (copy) void (^didCancel) (SQRDCheckoutController *);

- (instancetype)initWithBlocksForSuccess: (void (^)(SQRDCheckoutResult *)) successBlock
                              forFailure: (void (^)(NSError *)) failureBlock
                         forCancellation: (void (^)(SQRDCheckoutController *)) cancellationBlock;
@end
