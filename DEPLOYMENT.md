# App Store Deployment

This project uses XcodeGen for the Xcode project and fastlane for App Store packaging.

## Prerequisites

- Xcode 26 or newer
- XcodeGen
- Ruby Bundler
- App Store Connect API key with access to `com.speedy.speedtest`
- Apple Distribution certificate and App Store provisioning profile for team `95W8G892Z4`

The fastlane defaults expect these identifiers:

- Bundle ID: `com.speedy.speedtest`
- App Store app ID: `6772637733`
- App Store Connect Apple ID: `aloewright@gmail.com`
- App Store Connect team ID: `93438877`
- Distribution team ID: `95W8G892Z4`

## Setup

```sh
bundle install
xcodegen generate
```

By default, fastlane looks for `fastlane/AuthKey_N3S3GACBN2.p8`. To keep credentials outside the repo, set:

```sh
export APP_STORE_CONNECT_API_KEY_ID=N3S3GACBN2
export APP_STORE_CONNECT_ISSUER_ID=19f6fa40-e859-4234-a509-cb794faa464a
export APP_STORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_N3S3GACBN2.p8
```

## Local validation

```sh
bundle exec fastlane ios prepare
```

This regenerates the Xcode project and performs a signing-disabled Release build for a generic iOS device.

## TestFlight

```sh
bundle exec fastlane ios beta
```

## App Store release submission

```sh
bundle exec fastlane ios release
```

The release lane uploads metadata from `fastlane/metadata` and screenshots from `fastlane/screenshots`, submits for review, and uses manual release after approval.
