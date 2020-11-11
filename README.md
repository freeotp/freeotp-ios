[![Build Status](https://travis-ci.org/freeotp/freeotp-ios.svg?branch=master)](https://travis-ci.org/freeotp/freeotp-ios)

# FreeOTP

[FreeOTP](https://freeotp.github.io/) is a two-factor authentication application for systems
utilizing one-time password protocols. Tokens can be added easily by scanning a QR code.

FreeOTP implements open standards:

* HOTP (HMAC-Based One-Time Password Algorithm) [RFC 4226](http://www.ietf.org/rfc/rfc4226.txt)
* TOTP (Time-Based One-Time Password Algorithm) [RFC 6238](http://www.ietf.org/rfc/rfc6238.txt)

This means that no proprietary server-side component is necessary: use any server-side component
that implements these standards.

## Download FreeOTP for iOS

* [App Store](https://itunes.apple.com/us/app/freeotp-authenticator/id872559395?mt=8)

## Contributing

Pull requests on GitHub are welcome under the Apache 2.0 license, see [COPYING](COPYING).

### Setup local dev env

You need to have [Carthage](https://github.com/Carthage/Carthage) installed for managing dependencies. In simple steps

    brew install carthage
    carthage update

A shell script workaround is needed to build Base32 framework for Xcode 12+
[Carthage failure workaround](https://github.com/Carthage/Carthage/issues/3019#issuecomment-665136323)
