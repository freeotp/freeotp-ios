//
//  MainNavigationController.swift
//  FreeOTP
//
//  Created by Vinícius Soares on 12/06/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barTintColor = UIColor.app.navigationBackground
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.app.accent
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.app.primaryText]

        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIColor.app.navigationHairline.asHalfPointImage
    }
}

private extension UIColor {
    var asHalfPointImage: UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 0.5, height: 0.5))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
