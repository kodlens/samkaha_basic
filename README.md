# sales_management

SamKaha Basic.

## Getting Started

    This project is a starting point for a Flutter application.

## Thermal printer

    width: 280 // typical 58mm printer
    width: 384 // typical 80mm printer
    


## Change pass

    & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -keypasswd -alias upload -keystore $env:USERPROFILE\upload-keystore.jks

## Create Signed Key

    & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

## Create Properties

Add new file under android/key.properties and name it key.properties, add this values

    storePassword=<your-new-password>
    keyPassword=<your-new-password>
    keyAlias=upload
    storeFile=C:/Users/<YourWindowsUsername>/upload-keystore.jks

## Stop and Clean 

    cd D:\Flutter\samkaha_basic\android
    .\gradlew --stop