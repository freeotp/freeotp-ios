//
//  ManualAddViewController.swift
//  FreeOTP
//
//  Created by Игорь Андрианов on 09.04.2022.
//  Copyright © 2022 Fedora Project. All rights reserved.
//

import UIKit

class ManualAddViewController: UIViewController {
    
    struct Intervals {
        var title: String
        var interval: Int
    }
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var secretField: UITextField!
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var digitsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var algorithmButton: UIButton!
    @IBOutlet weak var intervalButton: UIButton!
    
    let type: [String] = ["TOTP","HOTP"]
    let digits: [Int] = [6, 7, 8, 9]
    let algorithms: [String] = ["SHA1", "SHA224", "SHA256", "SHA384", "SHA512", "MD5"]
    
    let intervals: [Intervals] = [
        Intervals(title: "15s", interval: 15),
        Intervals(title: "30s", interval: 30),
        Intervals(title: "1m", interval: 60),
        Intervals(title: "2m", interval: 120),
        Intervals(title: "5m", interval: 300),
        Intervals(title: "10m", interval: 600),
    ]
    
    var URI = URIParameters()
    var icon = TokenIcon()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "manualAddView"
        configureSubviews()
    }
    
    private func configureSubviews() {
        nextButton.accessibilityIdentifier = "nextButton"
        issuerField.accessibilityIdentifier = "issuerField"
        descriptionField.accessibilityIdentifier = "descriptionField"
        secretField.accessibilityIdentifier = "secretField"
        
        typeSegmentedControl.removeAllSegments()
        type.enumerated().forEach { (index, element) in
            typeSegmentedControl.insertSegment(withTitle: String(element), at: index, animated: false)
        }
        typeSegmentedControl.selectedSegmentIndex = 0
        typeSegmentedControl.accessibilityIdentifier = "typeControl"
        
        digitsSegmentedControl.removeAllSegments()
        digits.enumerated().forEach { (index, element) in
            digitsSegmentedControl.insertSegment(withTitle: String(element), at: index, animated: false)
        }
        digitsSegmentedControl.selectedSegmentIndex = 0
        digitsSegmentedControl.accessibilityIdentifier = "digitsControl"
        
        algorithmButton.setTitle(algorithms[2], for: [])
        algorithmButton.accessibilityIdentifier = "algorithmControl"
        
        intervalButton.setTitle(intervals[1].title, for: [])
        intervalButton.accessibilityIdentifier = "intervalControl"
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        guard let issuer = issuerField.text,
              issuer.count > 0,
              let description = descriptionField.text,
              description.count > 0,
              let secret = secretField.text,
              secret.count > 0
        else {
            showOkAlert(title: "有些欄位尚未填寫！", message: "請填寫所有欄位")
            return
        }
        guard let _ = secret.base32DecodedData else {
            showOkAlert(
                title: "動態密碼無效！",
                message: "您嘗試新增的動態密碼無效。請檢查每個欄位是否符合 OTP 金鑰 URI 格式")
            secretField.text = ""
            return
        }
        
        guard let kind: Token.Kind = "TOTP" == type[typeSegmentedControl.selectedSegmentIndex] ? .totp : .hotp,
              let algorithm = algorithmButton.title(for: [])?.lowercased(),
              let interval = intervals.first(where: { $0.title == intervalButton.title(for: []) })?.interval
        else { return }
        let digits = digits[digitsSegmentedControl.selectedSegmentIndex]
        
        let manualData = ManualInputTokenData(algorithm: algorithm, secret: secret, digits: digits, period: interval, kind: kind, issuer: issuer, label: description, locked: nil)
        let urlc = ManualToUrlcModule().makeUrlc(from: manualData)
        
        if !pushNextViewController(urlc) {
            TokenStore().add(urlc)

            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                dismiss(animated: true, completion: nil)
                popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
            default:
                navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    private func pushNextViewController(_ urlc: URLComponents) -> Bool {
        
        if URI.paramUnset(urlc, "image", ""),
           let issuer = issuerField.text,
           icon.issuerBrandMapping[issuer] == nil {
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
        } else { return false }
        
        return true
    }
    
    @IBAction func algorithmTapped(_ sender: Any) {
        showPopupMenu(button: algorithmButton, with: algorithms)
    }
    
    @IBAction func intervalTapped(_ sender: Any) {
        showPopupMenu(button: intervalButton, with: intervals.map { $0.title })
    }
    
    private func showPopupMenu(button: UIButton, with actions: [String]) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        actions.forEach { title in
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                button.setTitle(title, for: [])
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in })
        present(alert, animated: true, completion: nil)
    }
    
    private func showOkAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "確定", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
}
