//
//  URILockViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 2/7/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class URILockViewController: UIViewController {
    // MARK: - Properties
    var inputUrlc = URLComponents()
    var outputUrlc = URLComponents()
    var URI = URIParameters()
    var icon = TokenIcon()

    // MARK: - Outlets
    @IBOutlet weak var lockSwitch: UISwitch!

    // MARK: - Actions
    @IBAction func backClicked(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func helpClicked(_ sender: UIButton) {
        presentAlert(title: "鎖定", message: "鎖定參數是一個布林值，確保動態密碼金鑰只能透過最近的裝置驗證來存取。",
        actionTitle: "確定")
    }

    @IBAction func doneClicked(_ sender: UIBarButtonItem) {
        let newVal = lockSwitch.isOn ? "true" : "false"

        var queryItems: [URLQueryItem] = outputUrlc.queryItems!

        let newItem = URLQueryItem(name: "lock", value: newVal)

        if let lockVal = URI.getQueryItem(outputUrlc, "lock") {
            let prev = URLQueryItem(name: "lock", value: lockVal)
            if let index = outputUrlc.queryItems?.firstIndex(of: prev) {
                queryItems.remove(at: index)
                queryItems.append(newItem)
            }
        } else {
            queryItems.append(newItem)
        }

        outputUrlc.queryItems = queryItems

        TokenStore().add(outputUrlc)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            dismiss(animated: true, completion: nil)
            popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
        default:
            navigationController?.popToRootViewController(animated: true)
        }
    }

    // MARK: - Methods
    func presentAlert(title: String, message: String, actionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        outputUrlc = inputUrlc
    }
}
