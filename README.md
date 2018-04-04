
# react-native-square-paysdk

## This native module won't work until square releases their sdk to the public


## Dependencies

`react-native` version `>0.40`

## Installation

`npm i react-native-square-paysdk --save`

#### iOS installation

1. Add the following line to your "Podfile": `pod 'react-native-square-paysdk', path: '../node_modules/react-native-square-paysdk'`
2. run `pod install`
3. Run your project (`Cmd+R`)



#### Android Manual installation

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add 

    ```java
    import com.sudoplz.rnsquarepaysdk.RNReactNativeSquarePaysdkPackage;
    ```

   to the imports at the top of the file.
   
  - Add 

    ```java
    new RNReactNativeSquarePaysdkPackage(),
    ``` 

  to the list returned by the `getPackages()` method
  
2. Append the following lines to `android/settings.gradle`:

    ```gradle
    include ':react-native-square-paysdk'
    project(':react-native-square-paysdk').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-square-paysdk/android')
    ```

3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:

    ```gradle
    compile 'com.square:pay-sdk:latest' // native sdk of paySDK (once it goes live)
    compile project(':react-native-square-paysdk') // our react-native module
    ```

...

## Usage 

  ```javascript

  import PaySDK from 'react-native-square-paysdk';

  ```


### Example 

```javascript
class testApp extends Component {
  constructor() {
    super();
   const paySdk = new PaySDK();
   
   paySdk.initWithKey("YOUR-AMPLITUDE-KEY").then();

   // figure if the sdk has been initialised
   paySdk.hasInit().then((hasInit) => {

   });

   // login with device code
   paySdk.loginWithDeviceCode("1234567").then(() => {
      // success
   }).catch((err) => {
      // failure
   })

   // find out if logged in
   paySdk.isLoggedIn().then();
   

   // set the tender type
   paySdk.setTenderType(
      PaySDK.TenderTypes.READER_ONLY + PaySDK.TenderTypes.KEYED_IN_CARD,
   );

   // set other settings
   paySdk.setFlowConfig(
      null, // tip percentages arr
      false, // tips enabled
      false, // custom tip field visible
      false, // separate tip screen visible
      true, // skip receipt
      true, // skip signature
      false, // allow split tender
    );

    // present the settings screen
    paySdk.presentNewReaderScreenWithAnimation(
      true, // animate modal window
    );

    // find out if logged in
    const isLoggedIn = paySdk.isLoggedIn().then();

    paySdk.requestPermissions() // so try asking for permissions (needed for iOS)
      .then((permissions) => {
        if (permissions != null) {
          let permissionsGranted;
          if (notAndroid) {
            const {
              appLocationPermission,
              deviceLocationEnabled,
              appRecordingPermission,
            } = permissions;
          }
        }
      });

     paySdk.transactionRequestWithCentsAmount(
        100, // amount to pay (in cents)
        'This is a transaction',
        12345, // customer ID
      ).then((result) => { // transactionRequestWithCentsAmount success
        /*
        {
            "transaction": {
                "serverID": "yada yada yada",
                "locationID": "18K68ZJ8PZF1T",
                "order": {
                    "totalMoneyAmount": 100,
                    "totalTaxMoneyCurrency": "USD",
                    "totalTaxMoneyAmount": 0,
                    "totalTipMoneyCurrency": "USD",
                    "totalMoneyCurrency": "USD",
                    "totalTipMoneyAmount": 0
                },
                "tenderCnt": 1,
                "clientID": "95B801E7-522A-44D9-BD1C-6B975316F9AB",
                "createdAt": "2018-03-21T17:35:13-04:00"
            }
        }
        */

        // Do something with the result
      });
  }
  ...
}
```

