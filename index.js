/* eslint-disable no-restricted-properties, no-caller */

import { NativeModules } from 'react-native';


const { RNReactNativeSquarePaysdk } = NativeModules;


function SquareSDKModule() { // es5 singleton
  //
  if (arguments.callee.singletonInstance) {
    return arguments.callee.singletonInstance;
  }

  arguments.callee.singletonInstance = this;

  this.hasInitialized = false;

  this.initWithKey =
    function initWithKey(key) {
      if (this.hasInitialized !== true && key != null) {
        this.hasInitialized = true;
        return RNReactNativeSquarePaysdk.initWithApplicationID(key);
      }
      return Promise.resolve();
    };

  this.hasInit =
    function hasInit() {
      if (this.hasInitialized) {
        return RNReactNativeSquarePaysdk.hasInit().then(res => res.hasInit);
      }
      return Promise.resolve(false);
    };

  this.requestPermissions =
    function requestPermissions() {
      return RNReactNativeSquarePaysdk.requestPermissions();
    };

  this.isLoggedIn =
    function isLoggedIn() {
      return RNReactNativeSquarePaysdk.isLoggedIn().then(res => res.isLoggedIn);
    };

  this.loginWithDeviceCode =
    function loginWithDeviceCode(deviceCode) {
      return RNReactNativeSquarePaysdk.loginWithDeviceCode(deviceCode);
    };

  this.logout =
    function logout() {
      return RNReactNativeSquarePaysdk.logout();
    };

  this.transactionRequestWithCentsAmount =
    function transactionRequestWithCentsAmount(cents, note, customerId) {
      return RNReactNativeSquarePaysdk.transactionRequestWithCentsAmount(cents, note, customerId);
    };

  this.presentNewReaderScreenWithAnimation =
    function presentNewReaderScreenWithAnimation(animated = true) {
      return RNReactNativeSquarePaysdk.presentNewReaderScreenWithAnimation(animated);
    };

  this.setFlowConfig = function setFlowConfig(
    tipPercentages,
    tipsEnabled = true,
    customTipFieldVisible = false,
    separateTipScreenVisible = false,
    skipReceipt = true,
    skipSignature = true,
    allowSplitTender = false) {
    return RNReactNativeSquarePaysdk.setFlowConfig(
      tipsEnabled,
      customTipFieldVisible,
      tipPercentages,
      separateTipScreenVisible,
      skipReceipt,
      skipSignature,
      allowSplitTender,
    );
  };

  this.setTenderType = function setTenderType(tenderType) {
    return RNReactNativeSquarePaysdk.setTenderType(tenderType);
  };
}

SquareSDKModule.TenderTypes = {
  ALL: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeAll,
  READER_ONLY: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeCardFromReader,
  KEYED_IN_CARD: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeKeyedInCard,
  CASH: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeCash,
  OTHER: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeOther,
  GIFT_CARD: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeSquareGiftCard,
  CARD_ON_FILE: RNReactNativeSquarePaysdk.PaySDKTransactionRequestTenderTypeCardOnFile,
};
module.exports = SquareSDKModule;
