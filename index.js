/* eslint-disable no-restricted-properties, no-caller */
import {
  // findNodeHandle,
  NativeModules,
} from 'react-native';

const { ACSquareSDK } = NativeModules;


function SquareSDKModule() { // es5 singleton
  //
  if (arguments.callee.singletonInstance) {
    return arguments.callee.singletonInstance;
  }

  arguments.callee.singletonInstance = this;

  this.hasInitialized = false;

  this.initSdk =
    function initSdk() {
      if (/* __DEV__ != true &&  */this.hasInitialized !== true) {
        this.hasInitialized = true;
        return ACSquareSDK.initSdk();
      }
      return Promise.resolve();
    };

  this.hasInit =
    function hasInit() {
      if (this.hasInitialized) {
        return ACSquareSDK.hasInit().then(res => res.hasInit);
      }
      return Promise.resolve(false);
    };

  this.requestPermissions =
    function requestPermissions() {
      return ACSquareSDK.requestPermissions();
    };

  this.isLoggedIn =
    function isLoggedIn() {
      return ACSquareSDK.isLoggedIn().then(res => res.isLoggedIn);
    };

  this.authorizeWithCode =
    function authorizeWithCode(deviceCode) {
      return ACSquareSDK.authorizeWithCode(deviceCode);
    };

  this.deauthorize =
    function deauthorize() {
      return ACSquareSDK.deauthorize();
    };

  this.checkoutWithAmount =
    function checkoutWithAmount(cents, note) {
      return ACSquareSDK.checkoutWithAmount(cents, note || '');
    };

  this.getAuthorizedLocation =
    function getAuthorizedLocation() {
      return ACSquareSDK.getAuthorizedLocation();
    };

  this.presentReaderSettingsScreen =
    function presentReaderSettingsScreen() {
      return ACSquareSDK.presentReaderSettingsScreen();
    };

  this.setCheckoutParameters = function setCheckoutParameters(
    additionalPaymentTypes,
    tipPercentages,
    tipsEnabled = true,
    customTipFieldVisible = false,
    separateTipScreenVisible = false,
    skipReceipt = false,
    alwaysRequireSignature = false,
    allowSplitTender = false,
  ) {
    return ACSquareSDK.setCheckoutParameters(
      tipsEnabled,
      customTipFieldVisible,
      tipPercentages,
      separateTipScreenVisible,
      skipReceipt,
      alwaysRequireSignature,
      allowSplitTender,
      additionalPaymentTypes || 0,
    ).catch((e) => {
      // eslint-disable-next-line
      console.log(`ACSquareSDK.setCheckoutParameters err: ${e}`);
    });
  };

  // this.setTenderType = function setTenderType(tenderType) {
  //   return ACSquareSDK.setTenderType(tenderType);
  // };
}

SquareSDKModule.AdditionalPaymentTypes = {
  MANUAL_CARD_ENTRY: ACSquareSDK.SQRDAdditionalPaymentTypeManualCardEntry,
  CASH: ACSquareSDK.SQRDAdditionalPaymentTypeCash,
  OTHER: ACSquareSDK.SQRDAdditionalPaymentTypeOther,
};
module.exports = SquareSDKModule;
