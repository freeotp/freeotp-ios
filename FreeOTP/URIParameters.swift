//
//  URIParameters.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 2/7/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import Foundation

public struct Label {
    public var issuer = ""
    public var account = ""
}

public class URIParameters {
    // MARK: - Methods
    public init() {}

    public func accountUnset(_ uri: URLComponents) -> Bool! {
        if let label = getLabel(from: uri) {
            return label.issuer == "" ? true : false
        } else {
            return nil
        }
    }

    public func paramUnset<T>(_ uri: URLComponents, _ name: String, _ type: T) -> Bool {
        let value = getQueryItem(uri, name)

        if value == nil {
            return true
        }

        switch(T.self) {
        case is String.Type:
            return value != "" ? false : true
        case is Bool.Type:
            return value == "true" || value == "false" ? false : true
        default:
            return true
        }
    }

    public func getLabel(from uri: URLComponents) -> Label! {
         var label = Label()

         var path = uri.path
         while path.hasPrefix("/") {
             path = String(path[path.index(path.startIndex, offsetBy: 1)...])
         }
         if path == "" {
             return nil
         }

         let components = path.components(separatedBy: ":")
         if components.count == 1 {
             label.account = components[0]
         } else if components.count > 1 {
             label.issuer = components[0]
             label.account = components[1]
         } else {
             return nil
         }

         return label
     }

    public func getQueryItem(_ uri: URLComponents, _ keyItem: String) -> String! {
        return uri.queryItems?.first(where: { $0.name == keyItem })?.value
    }

    public func validateURI(uri: URLComponents) -> Bool {
        if uri.scheme != "otpauth" || uri.host == nil {
            return false
        }

        if uri.host!.lowercased() != "totp" && uri.host!.lowercased() != "hotp" {
            return false
        }

        var path = uri.path
        while path.hasPrefix("/") {
            path = String(path[path.index(path.startIndex, offsetBy: 1)...])
        }

        if path == "" {
            return false
        }

        let query = uri.queryItems
        if (query == nil) { return false }

        if let secret = query?.first(where: { $0.name == "secret" })?.value {
            if (secret.isEmpty) { return false}
        } else {
            return false
        }

        return true
    }
}
