//
//  Device.swift
//  FreeOTP
//
//  Created by Vinícius Soares on 10/06/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

final class Device {
    enum Size { case small, medium, large }

    static var size: Size {
        switch UIScreen.main.bounds.width {
        case 1...320: return .small
        case 321...375: return .medium
        default: return .large
        }
    }
}
