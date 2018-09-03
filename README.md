
# react-native-sp-reader-sdk


## Dependencies

`react-native` version `>0.40`

## Installation

`npm i react-native-sp-reader-sdk --save`



#### iOS installation

1. Add the following line to your "Podfile": `pod 'react-native-sp-reader-sdk', path: '../node_modules/react-native-sp-reader-sdk'`
2. run `pod install`
3. Follow all the instructions needed to install ReaderSDK both for [iOS](https://docs.connect.squareup.com/payments/readersdk/setup-ios)




#### Android Manual installation

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add 

    ```java
    import com.sudoplz.rnsquarepaysdk.RCTACSquareSDKPackage;
    ```

   to the imports at the top of the file.
   
  - Add 

    ```java
    new RCTACSquareSDKPackage(),
    ``` 

  to the list returned by the `getPackages()` method
  
2. Append the following lines to `android/settings.gradle`:

    ```gradle
    include ':react-native-sp-reader-sdk'
    project(':react-native-sp-reader-sdk').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-sp-reader-sdk/android')
    ```

3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:

    ```gradle
    compile 'com.square:pay-sdk:latest' // native sdk of readerSDK (once it goes live)
    compile project(':react-native-sp-reader-sdk') // our react-native module
    ```

...

4. Follow all the instructions needed to install ReaderSDK for [Android](https://docs.connect.squareup.com/payments/readersdk/setup-android)

5. Go in `~/.gradle/gradle.properties` (or `C:\Users\username\.gradle\gradle.properties
` if on Windows) and create 2 values:

```
SQUARE_REPO_USERNAME=WHATEVER_YOUR_SQUARE_USERNAME_IS
SQUARE_REPO_PASSWORD=WHATEVER_YOUR_SQUARE_PASSWORD_IS
```

That way Android will know how to pull the ReaderSDK dependency


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

