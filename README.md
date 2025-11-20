# FreeOTP

[FreeOTP](https://freeotp.github.io/) is a two-factor authentication application for systems
utilizing one-time password protocols. Tokens can be added easily by scanning a QR code.

FreeOTP implements open standards:

* HOTP (HMAC-Based One-Time Password Algorithm) [RFC 4226](https://www.ietf.org/rfc/rfc4226.txt)
* TOTP (Time-Based One-Time Password Algorithm) [RFC 6238](https://www.ietf.org/rfc/rfc6238.txt)

This means that no proprietary server-side component is necessary: use any server-side component
that implements these standards.

## Download FreeOTP for iOS

* [App Store](https://apps.apple.com/app/freeotp-authenticator/id872559395)

## Contributing

Pull requests on GitHub are welcome under the Apache 2.0 license, see
[CONTRIBUTING](CONTRIBUTING.md) for more details.

### Install Build dependencies

You need to have [Carthage](https://github.com/Carthage/Carthage) installed for managing dependencies. In simple steps:

    brew install carthage
    carthage update --use-xcframeworks --platform iOS

### Additional information

* FreeOTP Backup and Restore requires enabling [encrypted backups](https://support.apple.com/en-us/108353#encrypt).

FreeOTP Backup and Restore relies on Apple native backup functionality. For enhanced security, FreeOTP stores token secrets in the device keystore
using the [Apple Keychain interface](https://support.apple.com/guide/security/keychain-data-protection-secb0694df1a/web). Items are stored with
Keychain data protection attribute [kSecAttrAccessibleWhenUnlocked](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlocked).
Items with this attribute migrate to a new device when using encrypted backups.

* FreeOTP Locked tokens :lock: are **NOT** included in device backups. This is enforced by Apple Security, it is not a FreeOTP decision.

Token providers may add `lock=true` OTP Token URI parameter. FreeOTP tokens added this way require Biometrics data stored in the Apple Keychain and appear in the
FreeOTP tokens list with a :lock: icon image. Biometrics data in the Apple Keychain is excluded from encrypted Backup data intentionally.
This is a security measure by Apple to keep Biometrics data like FaceID from leaving the device.
Refer to [Apple Platform Security](https://support.apple.com/guide/security/welcome/web) documentation for more information.