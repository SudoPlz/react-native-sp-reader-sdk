
package com.sudoplz.rnsquarepaysdk;


import android.app.Activity;
import android.content.Intent;

import com.facebook.common.internal.Ints;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.squareup.paysdk.PaySdk;
import com.squareup.paysdk.PaySdkClient;
import com.squareup.paysdk.PaySdkError;
import com.squareup.paysdk.PaySdkLoginCallback;
import com.squareup.paysdk.PaySdkLogoutCallback;
import com.squareup.paysdk.TippingOptions;
import com.squareup.paysdk.TransactionRequest;
import com.squareup.paysdk.TransactionResult;
import com.squareup.paysdk.transaction.Money;
import com.squareup.paysdk.transaction.Order;
import com.squareup.paysdk.transaction.Tender;
import com.squareup.server.account.protos.Tipping;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static java.lang.Math.toIntExact;

/**
 * Created by Dynopia on 30/03/2018.
 */

public class RNReactNativeSquarePaysdkModule extends ReactContextBaseJavaModule {
    private PaySdkClient sdkClient;
    private static final int TRANSACTION_REQUEST_CODE = 9191;
    private static final int CONNECT_READER_REQUEST_CODE = 9192;

    private static final int TENDER_TYPE_CARD_FROM_READER = 1 << 0;
    private static final int TENDER_TYPE_KEYED_IN_CARD = 1 << 1;
    private static final int TENDER_TYPE_CASH = 1 << 2;
    private static final int TENDER_TYPE_OTHER= 1 << 3;
    private static final int TENDER_TYPE_GIFT_CARD = 1 << 4;
    private static final int TENDER_TYPE_CARD_ON_FILE = 1 << 5;
    private static final int TENDER_TYPE_ALL = // should be 63
            TENDER_TYPE_CARD_FROM_READER
            + TENDER_TYPE_KEYED_IN_CARD
            + TENDER_TYPE_CASH
            + TENDER_TYPE_OTHER
            + TENDER_TYPE_GIFT_CARD
            + TENDER_TYPE_CARD_ON_FILE;

    private ArrayList<TransactionRequest.TenderType> tenderTypesAllowed;

    private SquareFlowConfig flowConfig;
//    private
    public RCTACSquareSDKModule(ReactApplicationContext reactContext) {
        super(reactContext);
        flowConfig = new SquareFlowConfig();
        tenderTypesAllowed = new ArrayList<TransactionRequest.TenderType>();
    }

    @Override
	public String getName() {
	    return "RNReactNativeSquarePaysdk";
	}

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("PaySDKTransactionRequestTenderTypeCardFromReader", TENDER_TYPE_CARD_FROM_READER);
        constants.put("PaySDKTransactionRequestTenderTypeKeyedInCard", TENDER_TYPE_KEYED_IN_CARD);
        constants.put("PaySDKTransactionRequestTenderTypeCash", TENDER_TYPE_CASH);
        constants.put("PaySDKTransactionRequestTenderTypeOther", TENDER_TYPE_OTHER);
        constants.put("PaySDKTransactionRequestTenderTypeSquareGiftCard", TENDER_TYPE_GIFT_CARD);
        constants.put("PaySDKTransactionRequestTenderTypeCardOnFile", TENDER_TYPE_CARD_ON_FILE);
        constants.put("PaySDKTransactionRequestTenderTypeAll", TENDER_TYPE_ALL);
        return constants;
    }


    @ReactMethod
    public void initWithApplicationID(String applicationID, Promise promise) {
        // Create the client with your Square-assigned application ID
        if (applicationID == null) {
            promise.reject("1", "initWithApplicationID->applicationID parameter was null");
            return;
        }
        // sdkClient  =   PaySdk . createClient( APPLICATION_ID ) ;
        sdkClient = PaySdk.createClient(applicationID);

        promise.resolve(new WritableNativeMap());
        return;
    }

    @ReactMethod
    public void isLoggedIn(Promise promise) {
        WritableNativeMap responseObj = new WritableNativeMap();
        if (sdkClient == null) {
            responseObj.putBoolean("isLoggedIn", false);
            responseObj.putBoolean("hasInit", false);
        } else {
            responseObj.putBoolean("isLoggedIn", sdkClient.isLoggedIn());
            responseObj.putBoolean("hasInit", true);
        }

        promise.resolve(responseObj);
    }

    @ReactMethod
    public void hasInit(Promise promise) {
        WritableNativeMap responseObj = new WritableNativeMap();
        responseObj.putBoolean("hasInit", sdkClient != null);
        promise.resolve(responseObj);
    }

    @ReactMethod
    public void loginWithDeviceCode(String deviceCode, final Promise promise) {
        if (deviceCode == null) {
            promise.reject("2", "We need a device code in order to log you in");
            return;
        }
        if (sdkClient == null) {
            promise.reject("1", "You haven't initialized paySDK. Run initWithApplicationID first.");
        } else { // if sdkClient is NOT null
            Boolean isLoggedIn = sdkClient.isLoggedIn();
            if (isLoggedIn == false) {
                sdkClient.login(deviceCode, new PaySdkLoginCallback() {

                    @Override
                    public void onLoginSuccess() {
                        WritableNativeMap responseObj = new WritableNativeMap();
                        responseObj.putBoolean("success", true);
                        promise.resolve(responseObj);
                    }

                    @Override
                    public void onLoginError(PaySdkError paySdkError) {
                        promise.reject("0", paySdkError.code+","+paySdkError.debugDescription);
                    }
                });
            } else {
                WritableNativeMap responseObj = new WritableNativeMap();
                responseObj.putBoolean("success", true);
                promise.resolve(responseObj);
            }
        }
    }

    @ReactMethod
    public void transactionRequestWithCentsAmount(int centsAmount, String note, String customerID, final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("1", initializationErr);
            return;
        }
        if (flowConfig == null) {
            flowConfig = new SquareFlowConfig();
        }
        Activity activity = getCurrentActivity();
        if (activity == null) {
            promise.reject("1", "Can't get current activity");
            return;
        }

        TransactionRequest transactionRequest = new TransactionRequest
                .Builder(centsAmount)
                .customerId(customerID)
                .note(note)
                .skipReceipt(flowConfig.getSkipReceipt())
                .skipSignature(flowConfig.getSkipSignature())
                .allowSplitTender(flowConfig.getAllowSplitTender())
                .tipping(flowConfig.getTippingOpts())
                .restrictTendersTo(tenderTypesAllowed)
                .build();

        final ReactApplicationContext ctx = getReactApplicationContext();
        ActivityEventListener resultListener = new ActivityEventListener() {
            @Override
            public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
                if (requestCode == TRANSACTION_REQUEST_CODE) {
                    ctx.removeActivityEventListener(this);
                    if (resultCode == Activity.RESULT_OK) {
                        TransactionResult transaction = sdkClient.parseTransactionSuccess(data);
                        String message = "Client transaction id: " + transaction.clientId();

                        WritableNativeMap responseObj = new WritableNativeMap();
                        responseObj.putMap("transaction", transactionSerializer(transaction));
                        promise.resolve(responseObj);
                    } else {
                        PaySdkError error = sdkClient.parseError(data);
                        promise.reject("2", error.code+", "+error.debugDescription);
                    }
                }
            }

            @Override
            public void onNewIntent(Intent intent) {
            }
        };
        ctx.addActivityEventListener(resultListener);

        Intent intent = sdkClient.createTransactionIntent(transactionRequest);
        activity.startActivityForResult(intent , TRANSACTION_REQUEST_CODE);
    }

    @ReactMethod
    public void presentNewReaderScreenWithAnimation(Boolean animated, final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("1", initializationErr);
            return;
        }
        Activity activity = getCurrentActivity();
        if (activity == null) {
            promise.reject("1", "Can't get current activity");
            return;
        }

        final ReactApplicationContext ctx = getReactApplicationContext();
        ActivityEventListener resultListener = new ActivityEventListener() {
            @Override
            public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
                if (requestCode == CONNECT_READER_REQUEST_CODE) {
                    ctx.removeActivityEventListener(this);
                    if (resultCode == Activity.RESULT_OK) {
                        WritableNativeMap responseObj = new WritableNativeMap();
                        responseObj.putBoolean("success", true);
                        promise.resolve(responseObj);
                    } else {
                        promise.reject("2", "Could not initialize the ReaderManagementIntent");
                    }
                }
            }

            @Override
            public void onNewIntent(Intent intent) {
            }
        };
        ctx.addActivityEventListener(resultListener);
        Intent readerManagementIntent = sdkClient.createReaderManagementIntent();
        activity.startActivityForResult(readerManagementIntent, CONNECT_READER_REQUEST_CODE);
    }

    @ReactMethod
    public void logout(final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("1", initializationErr);
            return;
        }

        sdkClient.logOut(new PaySdkLogoutCallback() {
            @Override public void onSuccess() {
                promise.resolve("");
            }
            @Override public void onFailure(FailureReason reason, String localizedFailureMessage) {
                promise.reject("1", localizedFailureMessage);
            }
        });
    }

    @ReactMethod
    public void setFlowConfig(
            Boolean tipsEnabled,
    // tipsEnabled: Enables tipping in the payment flow. Tips can only be added to credit card and Square gift card payments.
    //                  Tipping is disabled by default.
    Boolean customTipFieldVisible,
    // customTipFieldVisible: Display the option to enter a custom tip amount. Tipping must be enabled to allow custom tip amounts.
    ReadableArray tipPercentages,
    //                  tipPercentages: Set tip percentages for the buyer during the payment flow. This list can contain up to three values, each of which must
    //                  be a nonnegative integer, from 0 to 100, inclusive. The default tipping options are 15%, 20%, and 25%. Tipping must be
    //                  enabled for these options to be displayed.
    Boolean separateTipScreenVisible,
    // separateTipScreenVisible: Present the tip options on its own screen before presenting the signature screen during credit card transactions. By default,
    //                  tip options are displayed on the signature screen.  Tipping must be enabled for this setting to take effect.
    Boolean skipReceipt,
    //                  skipReceipt:Do not present the receipt screen to the buyer. If the buyer has previously linked their payment method to their email address, he or
    //                  she will still receive an email receipt.
    Boolean skipSignature,
    //                  skipSignature: Skip the signature screen if allowed. This is usually possible for transactions under $25, but it is subject to change depending on card
    //                  brand.
    Boolean allowSplitTender,
    //                  allowSplitTender: Allow multiple tenders to be used in a single transaction. The split tender option is disabled by default.
            Promise promise) {
        try {
            flowConfig.setSkipReceipt(skipReceipt);
            flowConfig.setSkipSignature(skipSignature);
            int[] tipPercentagesIntArr;
            if (tipPercentages != null) {
                tipPercentagesIntArr = new int[tipPercentages.size()];;
                for (int i = 0; i < tipPercentages.size(); i++ ) {
                    Number curTip = tipPercentages.getDouble(i);
                    if (curTip != null) {
                        tipPercentagesIntArr[i] = curTip.intValue();
                    }
                }
            } else {
                tipPercentagesIntArr = new int[0];
            }

            TippingOptions.Builder tipBuilder = TippingOptions.builder();
            if (tipPercentagesIntArr.length > 0) {
                tipBuilder.tipPercentages(tipPercentagesIntArr);
            }
            TippingOptions newTippingOptions = tipBuilder
//                    .enabled(tipsEnabled) // TODO: Ask Gabe why that's protected and not public
                    .showSeparateTipScreen(separateTipScreenVisible)
                    .showCustomTipField(customTipFieldVisible)
                    .build();

            flowConfig.setAllowSplitTender(allowSplitTender);
            flowConfig.setTippingOpts(newTippingOptions);
            promise.resolve("");
        } catch(Exception err) {
            promise.reject(err);
        }
    }

    @ReactMethod
    public void setTenderType(int tenderTypes, Promise promise) {
        if (tenderTypesAllowed == null) {
            tenderTypesAllowed = new ArrayList<TransactionRequest.TenderType>();
        } else if (tenderTypesAllowed.size() > 0) {
            tenderTypesAllowed.clear();
        }

        if (tenderTypes >= TENDER_TYPE_ALL) {
            // 63 = 1<<0 + 1<<1 + 1<<2 + 1<<3 + 1<<4 + 1<<5
            tenderTypesAllowed.add(TransactionRequest.TenderType.GIFT_CARD);
            tenderTypesAllowed.add(TransactionRequest.TenderType.OTHER);
            tenderTypesAllowed.add(TransactionRequest.TenderType.CARD_FROM_READER);
            tenderTypesAllowed.add(TransactionRequest.TenderType.CASH);
            tenderTypesAllowed.add(TransactionRequest.TenderType.CARD_ON_FILE);
            tenderTypesAllowed.add(TransactionRequest.TenderType.KEYED_IN_CARD);
        } else {
            if ((tenderTypes & TENDER_TYPE_GIFT_CARD) == TENDER_TYPE_GIFT_CARD) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.GIFT_CARD);
            }

            if ((tenderTypes & TENDER_TYPE_OTHER) == TENDER_TYPE_OTHER) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.OTHER);
            }

            if ((tenderTypes & TENDER_TYPE_CARD_FROM_READER) == TENDER_TYPE_CARD_FROM_READER) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.CARD_FROM_READER);
            }

            if ((tenderTypes & TENDER_TYPE_CASH) == TENDER_TYPE_CASH) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.CASH);
            }

            if ((tenderTypes & TENDER_TYPE_CARD_ON_FILE) == TENDER_TYPE_CARD_ON_FILE) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.CARD_ON_FILE);
            }

            if ((tenderTypes & TENDER_TYPE_KEYED_IN_CARD) == TENDER_TYPE_KEYED_IN_CARD) {
                tenderTypesAllowed.add(TransactionRequest.TenderType.KEYED_IN_CARD);
            }
        }


        promise.resolve("");
    }

    @ReactMethod
    public void requestPermissions(Promise promise) {
        promise.resolve("");
        // we implemented that just for parity reasons with the iOS SDK
        // looks like permissions are handled internally for the Android SDK
    }



    private WritableMap transactionSerializer(TransactionResult result) {
        WritableNativeMap mapToReturn = new WritableNativeMap();
        if (result == null) {
            return mapToReturn;
        }

        if (result.serverId() != null) {
            mapToReturn.putString("serverID", result.serverId());
        }

        if (result.clientId() != null) {
            mapToReturn.putString("clientID", result.clientId());
        }

        if (result.locationId() != null) {
            mapToReturn.putString("locationID", result.locationId());
        }

        if (result.createdAt() != null) {
            mapToReturn.putString("createdAt", result.createdAt().iso8601DateString());
        }

        if (result.order() != null) {
            WritableNativeMap orderMap = new WritableNativeMap();
            Order curOrder = result.order();

            Money totalMoney = curOrder.totalMoney();
            if (totalMoney != null) {
                orderMap.putInt("totalMoneyAmount", safeLongToInt(totalMoney.amount()));
                orderMap.putString("totalMoneyCurrency", totalMoney.currencyCode().name());
            }

            Money totalTaxMoney = curOrder.totalTaxMoney();
            if (totalTaxMoney != null) {
                orderMap.putInt("totalTaxMoneyAmount", safeLongToInt(totalTaxMoney.amount()));
                orderMap.putString("totalTaxMoneyCurrency", totalTaxMoney.currencyCode().name());
            }
            Money totalTipMoney = curOrder.totalTipMoney();
            if (totalTipMoney != null) {
                orderMap.putInt("totalTipMoneyAmount", safeLongToInt(totalTipMoney.amount()));
                orderMap.putString("totalTipMoneyCurrency", totalTipMoney.currencyCode().name());
            }

            mapToReturn.putMap("order", orderMap);
        }

        if (result.tenders() != null && result.tenders().size() > 0) {
            mapToReturn.putInt("tenderCnt", result.tenders().size());
        }
        return mapToReturn;
    }

    private String returnErrorIfNotInitializedAndLoggedIn() {
        if (sdkClient == null) {
            return "You haven't initialized paySDK. Run initWithApplicationID first.";
        } else {
            if (sdkClient.isLoggedIn() != true) {
                return "You have not logged in yet. Run loginWithDeviceCode first.";
            }
        }
        return null;
    }

    public static int safeLongToInt(long l) {
        return (int) Math.max(Math.min(Integer.MAX_VALUE, l), Integer.MIN_VALUE);
    }
}
