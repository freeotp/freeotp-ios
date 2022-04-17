//
//  ManualInputTokenData.swift
//  FreeOTP
//
//  Created by Игорь Андрианов on 17.04.2022.
//  Copyright © 2022 Fedora Project. All rights reserved.
//

import Foundation

public struct ManualInputTokenData {
    let algorithm: String
    let secret: String
    let digits: Int
    let kind: Token.Kind
    let issuer: String
    let label: String
    let locked: Bool
}
