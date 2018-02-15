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

import Foundation
import UIKit

class AddTokenViewController : UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var type: UISegmentedControl!
    @IBOutlet weak var digits: UISegmentedControl!
    @IBOutlet weak var issuer: UITextField!
    @IBOutlet weak var label: UITextField!
    @IBOutlet weak var secret: UITextField!

    @IBOutlet weak var algo: UISegmentedControl!
    @IBOutlet weak var interval: UILabel!
    @IBOutlet weak var counter: UILabel!

    @IBOutlet var lockedTitle: UILabel!
    @IBOutlet var lockedSwitch: UISwitch!

    @IBOutlet weak var counterTitle: UILabel!
    @IBOutlet weak var counterStepper: UIStepper!

    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        self.counter.isEnabled = sender.selectedSegmentIndex == 0
        self.counterTitle.isEnabled = sender.selectedSegmentIndex == 0
        self.counterStepper.isEnabled = sender.selectedSegmentIndex == 0
    }

    @IBAction func intervalChanged(_ sender: UIStepper) {
        interval.text = String(UInt(sender.value))
    }

    @IBAction func counterChanged(_ sender: UIStepper) {
        counter.text = String(UInt(sender.value))
    }

    func enable(_ issuer: String, label: String, secret: String) {
        let s = secret.count
        self.navigationItem.rightBarButtonItem!.isEnabled = issuer != "" && label != "" && s > 0 && s % 8 == 0
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str: String = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        if textField === secret {
            var unpadded = false
            for chr in str.reversed() {
                if !unpadded {
                    if chr == "=" {
                        continue
                    } else {
                        unpadded = true
                    }
                }

                if !"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ234567".contains(chr) {
                    return false
                }
            }

            enable(issuer.text!, label: label.text!, secret: str)
        } else if textField === issuer {
            enable(str, label: label.text!, secret: secret.text!)
        } else if textField === label {
            enable(issuer.text!, label: str, secret: secret.text!)
        }

        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        let supported = Token.store.lockingSupported
        lockedTitle.isEnabled = supported
        lockedSwitch.isEnabled = supported
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, (sender !== self.navigationItem.rightBarButtonItem) {
            return
        }

        // Built URI
        var urlc = URLComponents()
        urlc.scheme = "otpauth"
        urlc.path = String(format: "/%@:%@", issuer.text!, label.text!)
        urlc.query = String(format: "algorithm=%@&digits=%@&secret=%@&period=%u&lock=%d",
            "SHA" + algo.titleForSegment(at: algo.selectedSegmentIndex)!,
            digits.titleForSegment(at: digits.selectedSegmentIndex)!,
            secret.text!, UInt(interval.text!)!, lockedSwitch.isOn ? 1 : 0)

        if (type.selectedSegmentIndex == 0) {
            urlc.query = urlc.query! + String(format: "&counter=%u", UInt(counter.text!)!)
            urlc.host = "hotp"
        } else {
            urlc.host = "totp"
        }

        // Make token
        TokenStore().add(urlc)
    }
}
