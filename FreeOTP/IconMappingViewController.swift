//
//  IconMappingViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 11/12/19.
//  Copyright © 2019 Fedora Project. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome

class IconMappingViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var faPicker: UIPickerView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var issuerTextField: UITextField!
    @IBOutlet weak var colorTextField: UITextField!

    var iconsBrands: [(name: String, value: String)] = []
    var iconsSolid: [(name: String, value: String)] = []
    var selectedIconType = String()
    var tokenIcon = TokenIcon()
    var selectedIconName = String()
    var tokenIssuer = String()

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        faPicker.reloadAllComponents()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, sender === saveButton {
            let issuerText = issuerTextField.text ?? ""
            let colorVal = colorTextField.text ?? ""

            tokenIcon.saveMapping(issuer: issuerText.lowercased(), iconName: selectedIconName, iconColor: colorVal)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == colorTextField {
            if let colorText = textField.text {
                let myColor = UIColor(hexString: colorText)
                iconImage.backgroundColor = myColor
            }
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return iconsBrands.count
        } else {
            return iconsSolid.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if segmentedControl.selectedSegmentIndex == 0 {
            let value = NSAttributedString(string: iconsBrands[row].name, attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])

            return value
        } else {
            let value = NSAttributedString(string: iconsSolid[row].name, attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])

            return value
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if segmentedControl.selectedSegmentIndex == 0 {
            if let iconName = FontAwesome(rawValue: iconsBrands[row].value) {
                selectedIconName = iconsBrands[row].value

                let icon = UIImage.fontAwesomeIcon(name: iconName, style: .brands, textColor: .white, size: CGSize(width: 96, height: 96))
                iconImage.image = icon
            }
        } else {
            if let iconName = FontAwesome(rawValue: iconsSolid[row].value) {
                selectedIconName = iconsSolid[row].value

                let icon = UIImage.fontAwesomeIcon(name: iconName, style: .solid, textColor: .white, size: CGSize(width: 96, height: 96))
                iconImage.image = icon
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        colorTextField.delegate = self
        issuerTextField.delegate = self
        faPicker.dataSource = self
        faPicker.delegate = self

        for (key, value) in tokenIcon.faIconsBrands {
            iconsBrands += [(name: "\(key)", value: "\(value)")]
        }

        for (key, value) in tokenIcon.faIconsSolid {
            iconsSolid += [(name: "\(key)", value: "\(value)")]
        }

        iconsBrands.sort(by: <)
        iconsSolid.sort(by: <)

        issuerTextField.text = tokenIssuer
    }
}
