//
//  ManualAddViewController.swift
//  FreeOTP
//
//  Created by Игорь Андрианов on 09.04.2022.
//  Copyright © 2022 Fedora Project. All rights reserved.
//

import UIKit

class ManualAddViewController: UIViewController {
    
    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var secretField: UITextField!
    @IBOutlet weak var settings: UIPickerView!
    
    let otpKinds: [String] = ["TOTP","HOTP"]
    let algorithms: [String] = ["sha1", "sha224", "sha256", "sha384", "sha512", "md5"]
    let digits: [String] = (6...9).map {String($0)}
    var pickerComponents: [[String]] {
        return [otpKinds, algorithms, digits]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settings.delegate = self
        settings.dataSource = self
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        //        guard let viewController = UIStoryboard(name: "Main", bundle: nil)
        //            .instantiateViewController(withIdentifier: "URILockViewController") as? URILockViewController
        //        else { return }
        //        viewController.inputUrlc = urlc
        //        if let navigator = navigationController {
        //            navigator.pushViewController(viewController, animated: true)
        //        }
        guard let issuer = issuerField.text,
              let description = descriptionField.text,
              let secret = secretField.text,
              let digits = Int(pickerComponents[2][settings.selectedRow(inComponent: 2)])
        else {
            showOkAlert(title: "Error", message: "Some problems")
            return
        }
        guard let _ = secret.base32DecodedData else {
            showOkAlert(title: "Error", message: "Some problems with your secret code")
            secretField.text = ""
            return
        }
        let kind: Token.Kind = "TOTP" == pickerComponents[0][settings.selectedRow(inComponent: 0)] ? .totp : .hotp
        let algorithm = pickerComponents[1][settings.selectedRow(inComponent: 1)]
        let manualData = ManualInputTokenData(algorithm: algorithm, secret: secret, digits: digits, kind: kind, issuer: issuer, label: description, locked: false)
        
        TokenStore().add(manualData: manualData)
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            dismiss(animated: true, completion: nil)
            popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
        default:
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func showOkAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
}

extension ManualAddViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerComponents.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerComponents[component].count
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 2 {
            return 50.0
        } else {
            return 120.0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerComponents[component][row]
    }
    
}
