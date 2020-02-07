//
//  URIMainIconViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 4/28/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class URIMainIconViewController: UIViewController {
    var inputUrlc = URLComponents()
    var outputUrlc = URLComponents()
    var URI = URIParameters()
    var suggestedIcons = [IconMatch]()
    var icon = TokenIcon()
    var uriColor = ""
    let levDistMax = 5
    let highMatchlevDist = 1
    var foundGoodMatch = false
    var iconChoice = String()

    // MARK: - Actions
    @IBAction func nextClicked(_ sender: UIBarButtonItem) {
        if let label = URI.getLabel(from: outputUrlc) {

            var color: String!

            if iconChoice != "" {
                color = icon.getBrandColorHex(iconChoice)
            }
            icon.saveMapping(issuer: label.issuer, iconName: iconChoice, iconColor: color ?? "")
        }

        if !pushNextViewController(outputUrlc) {
            TokenStore().add(outputUrlc)
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                dismiss(animated: true, completion: nil)
                popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
            default:
                navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    @IBAction func unwindToMainIcon(segue: UIStoryboardSegue) {
        let source = segue.source as? URIIconViewController
        if let selection = source?.selection {
            let size = CGSize(width: 96, height: 96)

            switch selection.type {
            case .recommended: fallthrough
            case .brands:
                let image = icon.getFontAwesomeIcon(faName: selection.faName, faType: .brands, size: size)
                bestIcon.image = image?.addImagePadding(x: 30, y: 30)
                bestIcon.backgroundColor = icon.getBackgroundColor(name: selection.faName, uriColor: uriColor)

            case .solid:
                let image = icon.getFontAwesomeIcon(faName: selection.faName, faType: .solid, size: size)
                bestIcon.image = image?.addImagePadding(x: 30, y: 30)
                bestIcon.backgroundColor = icon.getBackgroundColor(name: selection.faName, uriColor: uriColor)
            }

            iconChoice = selection.faName
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var bestIcon: UIImageView!
    @IBOutlet weak var foundIconLabel: UILabel!
    @IBOutlet weak var moreIconsButton: UIButton!

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Create a new variable to store the instance of PlayerTableViewController
        if let destinationVC = segue.destination as? URIIconViewController {
            destinationVC.inputUrlc = outputUrlc
            destinationVC.uriColor = uriColor
            destinationVC.suggestedIcons = suggestedIcons
         }
    }

    func pushNextViewController(_ urlc: URLComponents) -> Bool {
        if URI.paramUnset(urlc, "lock", false) {
            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "URILockViewController") as? URILockViewController {
                viewController.inputUrlc = urlc
                if let navigator = navigationController {
                    navigator.pushViewController(viewController, animated: true)
                }
            }
        } else {
            return false
        }

        return true
    }

    // MARK: - Methods
    func saveBestMatch(iconName: String) {
        if foundGoodMatch {
            return
        }

        iconChoice = iconName
        foundGoodMatch = true
        foundIconLabel.isHidden = false
        moreIconsButton.isHidden = false
        let size = CGSize(width: 96, height: 96)
        let image = icon.getFontAwesomeIcon(faName: iconChoice, faType: .brands, size: size)
        bestIcon.image = image?.addImagePadding(x: 30, y: 30)

        bestIcon.backgroundColor = icon.getBackgroundColor(name: iconChoice, uriColor: uriColor)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        moreIconsButton.layer.cornerRadius = 4
        outputUrlc = inputUrlc

        foundIconLabel.isHidden = true

        if let color = URI.getQueryItem(outputUrlc, "color") {
            uriColor = color
        }

        suggestedIcons = icon.getSuggestions(urlc: outputUrlc)

        for icons in suggestedIcons {
            if icons.levDist == highMatchlevDist {
                saveBestMatch(iconName: icons.name)
            }
        }

        if !foundGoodMatch {
            performSegue(withIdentifier: "moreIconsSegue", sender: self)
            moreIconsButton.isHidden = false
        }
    }
}
