//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

enum AppColors {
    static let background = UIColor.theme(darkHex: "#000000", lightHex: "#F2F2F6")
    static let cardBackground = UIColor.theme(darkHex: "#1C1C1E", lightHex: "#FFFFFF")
    static let navigationBackground = UIColor.theme(darkHex: "#171717", lightHex: "#FEFEFE")
    static let navigationHairline = UIColor.theme(darkHex: "#262626", lightHex: "#BEBEC1")
    static let accent = UIColor.theme(darkHex: "#2D8FFF", lightHex: "#007AFF")
    static let primaryText = UIColor.theme(darkHex: "#FFFFFF", lightHex: "#1A1A1A")
    static let secondaryText = UIColor.theme(darkHex: "#8E8E92", lightHex: "#8E8E92")
}

extension UIColor {
    static var app = AppColors.self

    fileprivate static func theme(darkHex: String, lightHex: String) -> UIColor {
        let darkColor = UIColor(hexString: darkHex)
        let lightColor = UIColor(hexString: lightHex)

        if #available(iOS 13.0, *) {
            return UIColor { $0.userInterfaceStyle == .dark ? darkColor : lightColor }
        } else {
            return lightColor
        }
    }
}

extension UIFont {
    static func dynamicSystemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        if Device.size == .large {
            return .systemFont(ofSize: fontSize + 4, weight: weight)
        } else if Device.size == .medium {
            return .systemFont(ofSize: fontSize + 2, weight: weight)
        }
        return .systemFont(ofSize: fontSize, weight: weight)
    }
}

