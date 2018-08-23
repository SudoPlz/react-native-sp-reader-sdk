
package com.sudoplz.rnsquarepaysdk;


import android.app.Activity;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.squareup.sdk.reader.ReaderSdk;
import com.squareup.sdk.reader.authorization.AuthorizeCallback;
import com.squareup.sdk.reader.authorization.AuthorizeErrorCode;
import com.squareup.sdk.reader.authorization.DeauthorizeCallback;
import com.squareup.sdk.reader.authorization.DeauthorizeErrorCode;
import com.squareup.sdk.reader.authorization.Location;
import com.squareup.sdk.reader.checkout.AdditionalPaymentType;
import com.squareup.sdk.reader.checkout.CheckoutActivityCallback;
import com.squareup.sdk.reader.checkout.CheckoutErrorCode;
import com.squareup.sdk.reader.checkout.CheckoutManager;
import com.squareup.sdk.reader.checkout.CheckoutParameters;
import com.squareup.sdk.reader.checkout.CheckoutResult;
import com.squareup.sdk.reader.checkout.CurrencyCode;
import com.squareup.sdk.reader.checkout.Money;
import com.squareup.sdk.reader.checkout.TipSettings;
import com.squareup.sdk.reader.core.CallbackReference;
import com.squareup.sdk.reader.core.Result;
import com.squareup.sdk.reader.core.ResultError;
import com.squareup.sdk.reader.hardware.ReaderSettingsActivityCallback;
import com.squareup.sdk.reader.hardware.ReaderSettingsErrorCode;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Created by Dynopia on 30/03/2018.
 */

public class RCTACSquareSDKModule extends ReactContextBaseJavaModule {
    protected CheckoutParameters checkoutParams;

    protected CallbackReference authorizeCallbackRef;
    protected CallbackReference checkoutCallbackRef;
    protected CallbackReference readerSettingsCallbackRef;
    protected CallbackReference deauthorizeCallbackRef;

    protected static final int ADDITIONAL_PAYMENT_TYPE_MANUAL_CARD_ENTRY = 1 << 0; // 1
    protected static final int ADDITIONAL_PAYMENT_TYPE_CASH = 1 << 1; // 2
    protected static final int ADDITIONAL_PAYMENT_TYPE_OTHER = 1 << 2; // 4

    public RCTACSquareSDKModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public void onCatalystInstanceDestroy() {
        // clear all callback listeners
        clearAuthCallbackListener();
        clearCheckoutCallbackListener();
        clearDeauthCallbackListener();
        clearSettingsCallbackListener();
        super.onCatalystInstanceDestroy();
    }

    @Override
    public String getName() {
        return "RCTACSquareSDK";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("SQRDAdditionalPaymentTypeManualCardEntry", 1);
        constants.put("SQRDAdditionalPaymentTypeCash", 2);
        constants.put("SQRDAdditionalPaymentTypeOther", 4);
        return constants;
    }


    @ReactMethod
    public void initSdk(Promise promise) {
        // No-op in Android
        promise.resolve(new WritableNativeMap());
    }

    @ReactMethod
    public void isLoggedIn(Promise promise) {
        boolean isLoggedIn = ReaderSdk.authorizationManager().getAuthorizationState().isAuthorized();
        WritableNativeMap responseObj = new WritableNativeMap();
        responseObj.putBoolean("isLoggedIn", isLoggedIn);
        responseObj.putBoolean("hasInit", true);
        promise.resolve(responseObj);
    }

    @ReactMethod
    public void hasInit(Promise promise) {
        // No-op in Android
        WritableNativeMap responseObj = new WritableNativeMap();
        responseObj.putBoolean("hasInit", true);
        promise.resolve(responseObj);
    }

    @ReactMethod
    public void authorizeWithCode(final String authorizationCode, final Promise promise) {
        if (authorizationCode == null) {
            promise.reject("2", "We need a device code in order to log you in");
            return;
        }
        getReactApplicationContext().runOnUiQueueThread(new Runnable() {
            @Override
            public void run() {
                if (ReaderSdk.authorizationManager().getAuthorizationState().isAuthorized() == false) {
                    clearAuthCallbackListener();

                    // New (Response)
                    authorizeCallbackRef = ReaderSdk.authorizationManager().addAuthorizeCallback(new AuthorizeCallback() {
                        @Override
                        public void onResult(Result<Location, ResultError<AuthorizeErrorCode>> result) {
                            // handle result

                            clearAuthCallbackListener(); // clear previous callback listeners

                            if (result.isSuccess()) { // on success
                                WritableNativeMap responseObj = new WritableNativeMap();
                                responseObj.putBoolean("success", true);
                                promise.resolve(responseObj);
                            } else { // on failure
                                ResultError<AuthorizeErrorCode> error = result.getError();
                                switch (error.getCode()) {
                                    case NO_NETWORK:
                                        promise.reject("NO_NETWORK", error.toString());
                                        break;
                                    case USAGE_ERROR:
                                        promise.reject("USAGE_ERROR", error.toString());
                                        break;
                                }
                            }
                        }
                    });
                    ReaderSdk.authorizationManager().authorize(authorizationCode);
                } else {
                    WritableNativeMap responseObj = new WritableNativeMap();
                    responseObj.putBoolean("success", true);
                    promise.resolve(responseObj);
                }
            }
        });
    }


    @ReactMethod
    public void getAuthorizedLocation(Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("", initializationErr);
            return;
        }

        Location authLocation = ReaderSdk.authorizationManager().getAuthorizationState().getAuthorizedLocation();
        if (authLocation != null) {
            WritableNativeMap responseObj = new WritableNativeMap();

            String businessName = authLocation.getBusinessName();
            if (businessName != null) {
                responseObj.putString("businessName", businessName );
            }

            String name = authLocation.getName();
            if (name != null) {
                responseObj.putString("name", name );
            }

            String locationId = authLocation.getLocationId();
            if (locationId != null) {
                responseObj.putString("locationId", locationId );
            }

            CurrencyCode currencyCode = authLocation.getCurrencyCode();
            if (currencyCode != null) {
                responseObj.putString("currencyCode", currencyCode.name());
            }

            Money maxMoney = authLocation.getMaximumCardPaymentAmountMoney();
            if (maxMoney != null) {
                responseObj.putDouble("maxCardPaymentAmount", new Double(maxMoney.getAmount()));
            }

            Money minMoney = authLocation.getMinimumCardPaymentAmountMoney();
            if (minMoney != null) {
                responseObj.putDouble("minCardPaymentAmount", new Double(minMoney.getAmount()));
            }

            promise.resolve(responseObj);
        } else {
            promise.reject("", "Location empty");
            return;
        }

    }


    @ReactMethod
    public void deauthorize(final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("", initializationErr);
            return;
        }


        if (ReaderSdk.authorizationManager().getAuthorizationState().isAuthorized() == true) {

            clearDeauthCallbackListener(); // clear past de-auth callback listener

            // New (Response)
            deauthorizeCallbackRef = ReaderSdk.authorizationManager().addDeauthorizeCallback(new DeauthorizeCallback() {
                @Override
                public void onResult(Result<Void, ResultError<DeauthorizeErrorCode>> result) {

                    clearDeauthCallbackListener(); // clear current de-auth callback listener

                    if (result.isSuccess()) {
                        promise.resolve("");
                    } else {
                        ResultError<DeauthorizeErrorCode> error = result.getError();
                        promise.reject("USAGE_ERROR", error.toString());
                    }
                }
            });
            ReaderSdk.authorizationManager().deauthorize();
        } else {
            promise.resolve("");
        }
    }


    @ReactMethod
    public void checkoutWithAmount(int centsAmount, String note, final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("", initializationErr);
            return;
        }

        Location authLoc = ReaderSdk.authorizationManager().getAuthorizationState().getAuthorizedLocation();
        if (authLoc != null) {
            long minPaymentAmount = authLoc.getMinimumCardPaymentAmountMoney().getAmount();
            long maxPaymentAmount = authLoc.getMaximumCardPaymentAmountMoney().getAmount();
            if (centsAmount < minPaymentAmount) {
                promise.reject("square_amount_less_than_min_allowed", ""+minPaymentAmount);
                return;
            }
            if (centsAmount > maxPaymentAmount) {
                promise.reject("square_amount_more_than_max_allowed", ""+maxPaymentAmount);
                return;
            }

        }

//        ReaderSdk.checkoutManager().startCheckoutActivity();
        if (checkoutParams == null) {
            checkoutParams  = this.createCheckoutParamsBuilderFor(
                true,
                false,
                null,
                false,
                false,
                false,
                false,
                0
            ).build();
        }


        // copy the checkout params builder
        CheckoutParameters.Builder newParamsBuilder = this.createCheckoutParamsBuilderFor(checkoutParams);
//                checkoutParams.buildUpon();

        // add the amount of money
        newParamsBuilder.amountMoney(new Money(centsAmount, CurrencyCode.current()));

        // add the note
        if (note != null && note.length() > 0) {
            newParamsBuilder.note(note);
        } else {
            newParamsBuilder.noNote();
        }

        final CheckoutParameters curTransactionCheckoutParams = newParamsBuilder.build();



        getReactApplicationContext().runOnUiQueueThread(new Runnable() {
            @Override
            public void run() {
                final Activity activity = getCurrentActivity();
                if (activity == null) {
                    promise.reject("", "Can't get current activity");
                    return;
                }

                CheckoutManager checkoutManager = ReaderSdk.checkoutManager();

                clearCheckoutCallbackListener(); // clear previous callback listeners

                checkoutCallbackRef = checkoutManager.addCheckoutActivityCallback(new CheckoutActivityCallback() {
                    @Override
                    public void onResult(Result<CheckoutResult, ResultError<CheckoutErrorCode>> result) {
                        clearCheckoutCallbackListener(); // clear this callback listener

                        if (result.isSuccess()) { // on success
                            CheckoutResult checkoutResult = result.getSuccessValue();
                            WritableNativeMap responseObj = new WritableNativeMap();
                            responseObj.putMap("transaction", checkoutResultSerializer(checkoutResult));
                            promise.resolve(responseObj);
                        } else { // on failure
                            ResultError<CheckoutErrorCode> error = result.getError();
                            switch (error.getCode()) {
                                case SDK_NOT_AUTHORIZED:
                                    promise.reject("SDK_NOT_AUTHORIZED", error.toString());
                                    break;
                                case CANCELED:
                                    promise.reject("CANCELED", error.toString());
                                    break;
                                case USAGE_ERROR:
                                    promise.reject("USAGE_ERROR", error.toString());
                                    break;
                            }
                        }

                    }
                });
                checkoutManager.startCheckoutActivity(activity, curTransactionCheckoutParams);
            }
        });
    }

    @ReactMethod
    public void presentReaderSettingsScreen(final Promise promise) {
        String initializationErr = returnErrorIfNotInitializedAndLoggedIn();
        if (initializationErr != null) {
            promise.reject("", initializationErr);
            return;
        }

        getReactApplicationContext().runOnUiQueueThread(new Runnable() {
            @Override
            public void run() {
                Activity activity = getCurrentActivity();
                if (activity == null) {
                    promise.reject("", "Can't get current activity");
                    return;
                }

                clearSettingsCallbackListener(); // clear previous reader settings callback

                readerSettingsCallbackRef = ReaderSdk.readerManager().addReaderSettingsActivityCallback(new ReaderSettingsActivityCallback() {
                    @Override
                    public void onResult(Result<Void, ResultError<ReaderSettingsErrorCode>> result) {
                        clearSettingsCallbackListener(); // clear current reader settings callback

                        if (result.isError()) { // on failure
                            ResultError<ReaderSettingsErrorCode> error = result.getError();
                            switch (error.getCode()) {
                                case SDK_NOT_AUTHORIZED:
                                    promise.reject("SDK_NOT_AUTHORIZED", error.toString());
                                    break;
                                case USAGE_ERROR:
                                    promise.reject("USAGE_ERROR", error.toString());
                                    break;
                            }
                        } else { // on success
                            WritableNativeMap responseObj = new WritableNativeMap();
                            responseObj.putBoolean("success", true);
                            promise.resolve(responseObj);
                        }
                    }
                });

                ReaderSdk.readerManager().startReaderSettingsActivity(activity);
            }
        });
    }


    @ReactMethod
    public void setCheckoutParameters(
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
    Boolean alwaysRequireSignature,
    //                  alwaysRequireSignature: Skip the signature screen if allowed. This is usually possible for transactions under $25, but it is subject to change depending on card
    //                  brand.
    Boolean allowSplitTender,
    //                  Additional payment types: i.e Cash, or keyed in card
    int additionalPaymentTypes,
    //                  allowSplitTender: Allow multiple tenders to be used in a single transaction. The split tender option is disabled by default.
            Promise promise) {
        try {
            checkoutParams = this.createCheckoutParamsBuilderFor(
                tipsEnabled,
                customTipFieldVisible,
                tipPercentages,
                separateTipScreenVisible,
                skipReceipt,
                alwaysRequireSignature,
                allowSplitTender,
                additionalPaymentTypes
            ).build();

            promise.resolve("");
        } catch(Exception err) {
            promise.reject(err);
        }
    }




    @ReactMethod
    public void requestPermissions(Promise promise) {
        promise.resolve("");
        // we implemented that just for parity reasons with the iOS SDK
        // looks like permissions are handled internally for the Android SDK
    }




    // UTILS

    private void clearDeauthCallbackListener() {
        if (deauthorizeCallbackRef != null) {
            deauthorizeCallbackRef.clear();
            deauthorizeCallbackRef = null;
        }
    }

    public void clearAuthCallbackListener() {
        if (authorizeCallbackRef != null) {
            authorizeCallbackRef.clear();
            authorizeCallbackRef = null;
        }
    }

    public void clearCheckoutCallbackListener() {
        if (checkoutCallbackRef != null) {
            checkoutCallbackRef.clear();
            checkoutCallbackRef = null;
        }
    }

    public void clearSettingsCallbackListener() {
        if (readerSettingsCallbackRef != null) {
            readerSettingsCallbackRef.clear();
            readerSettingsCallbackRef = null;
        }
    }

    private WritableMap checkoutResultSerializer(CheckoutResult result) {
        WritableNativeMap mapToReturn = new WritableNativeMap();
        if (result == null) {
            return mapToReturn;
        }

        if (result.getTransactionId() != null) {
            mapToReturn.putString("transactionID", result.getTransactionId());
        }

        if (result.getTransactionClientId() != null) {
            mapToReturn.putString("transactionClientId", result.getTransactionClientId());
        }


        if (result.getLocationId() != null) {
            mapToReturn.putString("locationID", result.getLocationId());
        }

        if (result.getCreatedAt() != null) {
            mapToReturn.putString("createdAt", toISO8601Str(result.getCreatedAt()));
        }

        if (result.getTotalMoney() != null) {
            mapToReturn.putDouble("totalMoneyAmount", result.getTotalMoney().getAmount());
            String totalMoneyCurrency = result.getTotalMoney().getCurrencyCode().name();
            if (totalMoneyCurrency != null) {
                mapToReturn.putString("totalMoneyCurrency", totalMoneyCurrency );
            }
        }

        if (result.getTotalTipMoney() != null) {
            mapToReturn.putDouble("totalTipMoneyAmount", result.getTotalTipMoney().getAmount());
            String totalMoneyCurrency = result.getTotalTipMoney().getCurrencyCode().name();
            if (totalMoneyCurrency != null) {
                mapToReturn.putString("totalTipMoneyCurrency", totalMoneyCurrency );
            }
        }

        if (result.getTenders() != null) {
            mapToReturn.putInt("tenderCnt", result.getTenders().size());
        }

        return mapToReturn;
    }

    private String returnErrorIfNotInitializedAndLoggedIn() {
        if (ReaderSdk.authorizationManager().getAuthorizationState().isAuthorized() != true) {
            return "You have not logged in yet. Run authorizeWithCode first.";
        }
        return null;
    }

//    public static int safeLongToInt(long l) {
//        return (int) Math.max(Math.min(Integer.MAX_VALUE, l), Integer.MIN_VALUE);
//    }

    public CheckoutParameters.Builder createCheckoutParamsBuilderFor(CheckoutParameters checkoutParams) {
        CheckoutParameters.Builder builder = CheckoutParameters.newBuilder(new Money(0, CurrencyCode.USD))
                .skipReceipt(checkoutParams.getSkipReceipt())
                .alwaysRequireSignature(checkoutParams.getAlwaysRequireSignature())
                .allowSplitTender(checkoutParams.getAllowSplitTender())
                .additionalPaymentTypes(checkoutParams.getAdditionalPaymentTypes()
                );
        if (checkoutParams.getTipSettings() != null) {
            builder.tipSettings(checkoutParams.getTipSettings());
        } else {
            builder.noTip();
        }
        return builder;
    }

    public CheckoutParameters.Builder createCheckoutParamsBuilderFor(Boolean tipsEnabled,
                                                             Boolean customTipFieldVisible,
                                                             ReadableArray tipPercentages,
                                                             Boolean separateTipScreenVisible,
                                                             Boolean skipReceipt,
                                                             Boolean alwaysRequireSignature,
                                                             Boolean allowSplitTender,
                                                             int additionalPaymentTypes) {

        TipSettings.Builder tipSettingsBuilder;

        CheckoutParameters.Builder tmpCheckoutParamsBuilder =
                CheckoutParameters.newBuilder(new Money(0, CurrencyCode.USD))
                        .skipReceipt(skipReceipt)
                        .alwaysRequireSignature(alwaysRequireSignature)
                        .allowSplitTender(allowSplitTender);

        // TIPS
        if (tipsEnabled) {
            tipSettingsBuilder = TipSettings.newBuilder()
                    .showCustomTipField(customTipFieldVisible)
                    .showSeparateTipScreen(separateTipScreenVisible);

            int[] tipPercentagesIntArr;
            if (tipPercentages != null && tipPercentages.size() > 0) {
                // if we have tip percentages in ReadableArray format
                // convert it to an int array
                tipPercentagesIntArr = new int[tipPercentages.size()];
                for (int i = 0; i < tipPercentages.size(); i++ ) {
                    Number curTip = tipPercentages.getDouble(i);
                    if (curTip != null) {
                        tipPercentagesIntArr[i] = curTip.intValue();
                    }
                }

                // and pass it to the tip settings builder
                tipSettingsBuilder.tipPercentages(tipPercentagesIntArr);
            }

            TipSettings newTipSettngs = tipSettingsBuilder.build();
            if (newTipSettngs != null) {
                // finally pass the newly built tip settings instance to the checkout params builder
                tmpCheckoutParamsBuilder.tipSettings(newTipSettngs);
            }
        } else { // else if tips are disabled
            tmpCheckoutParamsBuilder.noTip();
        }

        // ADDITIONAL payment types (previously tender types)
        if (additionalPaymentTypes > 0) {
            // if we have additional payment types

            Set<AdditionalPaymentType> additionalPaymentTypesSet = new HashSet<AdditionalPaymentType>();

            if ((additionalPaymentTypes & ADDITIONAL_PAYMENT_TYPE_CASH) == ADDITIONAL_PAYMENT_TYPE_CASH) {
                additionalPaymentTypesSet.add(AdditionalPaymentType.CASH);
            }

            if ((additionalPaymentTypes & ADDITIONAL_PAYMENT_TYPE_MANUAL_CARD_ENTRY) == ADDITIONAL_PAYMENT_TYPE_MANUAL_CARD_ENTRY) {
                additionalPaymentTypesSet.add(AdditionalPaymentType.MANUAL_CARD_ENTRY);
            }

            if ((additionalPaymentTypes & ADDITIONAL_PAYMENT_TYPE_OTHER) == ADDITIONAL_PAYMENT_TYPE_OTHER) {
                additionalPaymentTypesSet.add(AdditionalPaymentType.OTHER);
            }

            if (additionalPaymentTypesSet.size() > 0) {
                tmpCheckoutParamsBuilder.additionalPaymentTypes(additionalPaymentTypesSet);
            }
        } else {
            tmpCheckoutParamsBuilder.noAdditionalPaymentTypes();
        }

        // finally build the checkout params instance
        return tmpCheckoutParamsBuilder;
    }


    public static String toISO8601Str(Date date) {
        //"yyyy-MM-dd'T'HH:mm:ssZZ"; 2011-12-03T10:15:30+01:00
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZZ").format(date);
    }
}

