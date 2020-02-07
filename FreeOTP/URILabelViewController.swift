//
//  URILabelViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 2/7/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class URILabelViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Properties
    var inputUrlc = URLComponents()
    var outputUrlc = URLComponents()
    var URI = URIParameters()
    var icon = TokenIcon()
    var account = ""

    // MARK: - Outlets
    @IBOutlet weak var issuerTextField: UITextField!

    // MARK: - Actions
    @IBAction func nextClicked(_ sender: UIBarButtonItem) {
        if issuerTextField.text == "" {
            presentAlert(title: "Issuer missing", message: "It is recommended to provide a value for the Issuer field to take advantage of FreeOTP Icon features. Do you really want to use an empty issuer value?", actionTitleAccept: "Use empty issuer", actionTitleCancel: "Cancel")
        }

        submitForm()
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Navigation
    func pushNextViewController(_ urlc: URLComponents) -> Bool {
        var issuer = ""

        if let label = URI.getLabel(from: urlc) {
            issuer = label.issuer
        }

        if URI.paramUnset(urlc, "image", "") &&
            icon.getFontAwesomeIcon(issuer: issuer) == nil && icon.issuerBrandMapping[issuer] == nil {
            // Icon feature will not work, just save token
            if issuer == "" {
                return false
            }
            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "URIMainIconViewController") as? URIMainIconViewController {
                viewController.inputUrlc = urlc
                if let navigator = navigationController {
                    navigator.pushViewController(viewController, animated: true)
                }
            }
        } else if URI.paramUnset(urlc, "lock", false) {
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
    func submitForm() {
        // Update URI with new label
        let issuer = issuerTextField.text!
        outputUrlc.path = "/" + issuer + ":" + account

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

    func presentAlert(title: String, message: String, actionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func presentAlert(title: String, message: String, actionTitleAccept: String, actionTitleCancel: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitleAccept, style: UIAlertAction.Style.default, handler: {
            _ in self.submitForm()
        }))
        alert.addAction(UIAlertAction(title: actionTitleCancel, style: UIAlertAction.Style.cancel, handler: {
            _ in return
        }))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        issuerTextField.delegate = self

        outputUrlc = inputUrlc
        if let inputParams = URI.getLabel(from: inputUrlc) {
            account = inputParams.account
        }
    }
}
