//
//  ManualToUrlcModule.swift
//  FreeOTP
//
//  Created by Игорь Андрианов on 01.05.2022.
//  Copyright © 2022 Fedora Project. All rights reserved.
//

import Foundation

class ManualToUrlcModule {
    
    func makeUrlc(from data: ManualInputTokenData) -> URLComponents {
        var urlc = URLComponents()
        urlc.scheme = "otpauth"
        urlc.host = data.kind == .totp ? "totp" : "hotp"
        urlc.path = data.issuer + ":" + data.label
        urlc.queryItems = [
            URLQueryItem(name: "algorithm", value: data.algorithm),
            URLQueryItem(name: "secret", value: data.secret),
            URLQueryItem(name: "digits", value: String(data.digits)),
            URLQueryItem(name: "period", value: String(data.period)),
        ]
        if let locked = data.locked {
            urlc.queryItems?.append(URLQueryItem(name: "lock", value: locked.description))
        }
        return urlc
    }
}
