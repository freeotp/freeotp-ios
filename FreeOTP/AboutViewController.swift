//
//  AboutViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 6/23/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
  // Perform multiple link text replacements in a given string
  func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    let attributedOriginalText = NSMutableAttributedString(string: originalText)
    for (hyperLink, urlString) in hyperLinks {
        let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 18), range: fullRange)

        var textColor = UIColor()
        if #available(iOS 13.0, *) {
            textColor = UIColor.secondaryLabel
        } else {
            textColor = UIColor.gray
        }

        attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: fullRange)
    }

    self.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    self.attributedText = attributedOriginalText
  }
}

class AboutViewController : UIViewController, UITextViewDelegate {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var aboutTextView: UITextView!

    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        versionLabel.text = "FreeOTP \(appVersion)"
        versionLabel.font = UIFont.boldSystemFont(ofSize: 28.0)

        aboutTextView.delegate = self
        aboutTextView.text = """
        2013-2020 - Red Hat, Inc., et al.

        FreeOTP is licensed under Apache 2.0

        For more information, see our website

        We welcome your feedback
        - Report a Problem
        - Ask for Help
        """

        aboutTextView.addHyperLinksToText(originalText: aboutTextView.text,
                                          hyperLinks:
            ["Apache 2.0": "https://www.apache.org/licenses/LICENSE-2.0.html",
             "website": "https://freeotp.github.io",
             "Report a Problem": "https://github.com/freeotp/freeotp-ios/issues",
             "Ask for Help": "https://lists.fedorahosted.org/mailman/listinfo/freeotp-devel"])
    }
}
