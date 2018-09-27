
# react-native-sp-reader-sdk

## This is a 3rd party module, but square just released their own implementation of an RN module

So:
- we will now be joining forces on that repo
- You can now use the official Square RN module here --> https://github.com/square/react-native-square-reader-sdk


## Dependencies

`react-native` version `>0.40`

## Installation

Check the [wiki](https://github.com/SudoPlz/react-native-sp-reader-sdk/wiki) for instructions.

## Usage 

  ```javascript

  import ReaderSDK from 'react-native-sp-reader-sdk';

  ```


### Example 

```javascript
class testApp extends Component {
  constructor() {
    super();
    const readerSdk = new ReaderSDK();


    // initialize the sdk
    readerSdk.initSdk();


    // login with an auth code
    readerSDK.authorizeWithCode("1234567").then(() => {
      // success
    }).catch((err) => {
      // failure
    })

    // find out if already logged into readerSDK
    const isLoggedIn = await readerSdk.isLoggedIn();


    // set other settings
    readerSDK.setCheckoutParameters(
      ReaderSDK
        .AdditionalPaymentTypes
        .MANUAL_CARD_ENTRY, // additional payment types
      null, // tip percentages arr
      tipsEnabled, // tips enabled
      false, // custom tip field visible
      false, // separate tip screen visible
      true, // skip receipt
      false, // always require signature
      false, // allow split tender
    );

    // present the settings screen
    readerSDK.presentReaderSettingsScreen(
      true, // animate modal window
    );

    // find out if logged in
    const isLoggedIn = readerSDK.isLoggedIn()
      .then(isLoggedIn => {
        // isLoggedIn is either true or false
      });

    readerSDK.requestPermissions() // so try asking for permissions (needed for iOS)
      .then((permissions) => {
        if (permissions != null) {
          let permissionsGranted;
          if (notAndroid) {
            const {
              appLocationPermission,
              deviceLocationEnabled,
              appRecordingPermission,
            } = permissions;
            // do sth?
          }
        }
      });

     readerSDK.checkoutWithAmount(
        100, // amount to pay (in cents)
        'This is a transaction', // transaction notes
      ).then((result) => { // transactionRequestWithCentsAmount success
         /*
          {
              "transaction": {
                createdAt:"2018-07-25T18:13:02+03:00"
                locationID:"18K28ZA1PZF1T"
                tenderCnt:1
                totalMoneyAmount:115 (in cents, aka 1,15$)
                totalMoneyCurrency:"USD"
                totalTipMoneyAmount:15 (in cents, aka 0,15$)
                totalTipMoneyCurrency:"USD"
                transactionClientID:"EE8E7FF7-D16E-4350-91AD-47F2S6C7B447"
                transactionID:"Wo5JKw2fOp7dfwai7Gv3FlO14D9eV"
              }
          }
          */

        // Do something with the result
      })
      .catch((e) => { // checkoutWithAmount error
      });

      readerSDK.deauthorize(); // logout
    }
  ...
}
```

