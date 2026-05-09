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
  // Apply multiple links to exact ranges in a given string
  func addHyperLinksToText(originalText: String, hyperLinks: [(range: NSRange, urlString: String)]) {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    let attributedOriginalText = NSMutableAttributedString(string: originalText)
    let fullRange = NSRange(location: 0, length: attributedOriginalText.length)

    attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
    attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 18), range: fullRange)

    var textColor = UIColor()
    if #available(iOS 13.0, *) {
        textColor = UIColor.secondaryLabel
    } else {
        textColor = UIColor.gray
    }

    attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: fullRange)

    for hyperLink in hyperLinks {
        if hyperLink.range.location == NSNotFound || NSMaxRange(hyperLink.range) > attributedOriginalText.length {
            continue
        }

        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: hyperLink.urlString, range: hyperLink.range)
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

        let licenseLink = NSLocalizedString("Apache 2.0", comment: "Link text for the Apache 2.0 license")
        let websiteLink = NSLocalizedString("website", comment: "Link text for the FreeOTP project website")
        let reportProblemLink = NSLocalizedString("Report a Problem", comment: "Link text for reporting a problem")
        let askForHelpLink = NSLocalizedString("Ask for Help", comment: "Link text for asking for help")

        let licenseText = textWithLinkRange(
            format: NSLocalizedString("FreeOTP is licensed under %@", comment: "Sentence on the About screen; placeholder is the license link text"),
            linkText: licenseLink
        )
        let websiteText = textWithLinkRange(
            format: NSLocalizedString("For more information, see our %@", comment: "Sentence on the About screen; placeholder is the website link text"),
            linkText: websiteLink
        )

        var aboutText = ""
        var hyperLinks = [(range: NSRange, urlString: String)]()

        func appendText(_ text: String) {
            aboutText += text
        }

        func appendLinkedText(_ linkedText: (text: String, range: NSRange), urlString: String) {
            let offset = aboutText.utf16.count
            aboutText += linkedText.text
            hyperLinks.append((offsetRange(linkedText.range, by: offset), urlString))
        }

        func appendLink(_ linkText: String, urlString: String) {
            let range = NSRange(location: aboutText.utf16.count, length: linkText.utf16.count)
            aboutText += linkText
            hyperLinks.append((range, urlString))
        }

        appendText(NSLocalizedString("2013-2020 - Red Hat, Inc., et al.", comment: "Copyright notice on the About screen"))
        appendText("\n\n")

        appendLinkedText(licenseText, urlString: "https://www.apache.org/licenses/LICENSE-2.0.html")
        appendText("\n\n")

        appendLinkedText(websiteText, urlString: "https://freeotp.github.io")
        appendText("\n\n")

        appendText(NSLocalizedString("We welcome your feedback", comment: "Introductory text before feedback links on the About screen"))
        appendText("\n- ")

        appendLink(reportProblemLink, urlString: "https://github.com/freeotp/freeotp-ios/issues")
        appendText("\n- ")

        appendLink(askForHelpLink, urlString: "https://lists.fedorahosted.org/mailman/listinfo/freeotp-devel")

        aboutTextView.text = aboutText
        aboutTextView.addHyperLinksToText(originalText: aboutText, hyperLinks: hyperLinks)
    }

    private func textWithLinkRange(format: String, linkText: String) -> (text: String, range: NSRange) {
        let placeholder = "\u{E000}"
        let formattedText = String(format: format, placeholder)
        let placeholderRange = (formattedText as NSString).range(of: placeholder)
        if placeholderRange.location == NSNotFound {
            return (formattedText, placeholderRange)
        }

        let text = (formattedText as NSString).replacingCharacters(in: placeholderRange, with: linkText)
        let range = NSRange(location: placeholderRange.location, length: linkText.utf16.count)
        return (text, range)
    }

    private func offsetRange(_ range: NSRange, by offset: Int) -> NSRange {
        if range.location == NSNotFound {
            return range
        }

        return NSRange(location: range.location + offset, length: range.length)
    }
}
