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

    @IBOutlet weak var counterTitle: UILabel!
    @IBOutlet weak var counterStepper: UIStepper!
    
    @IBAction func typeChanged(sender: UISegmentedControl) {
        self.counter.enabled = sender.selectedSegmentIndex == 0
        self.counterTitle.enabled = sender.selectedSegmentIndex == 0
        self.counterStepper.enabled = sender.selectedSegmentIndex == 0
    }

    @IBAction func intervalChanged(sender: UIStepper) {
        interval.text = String(UInt(sender.value))
    }

    @IBAction func counterChanged(sender: UIStepper) {
        counter.text = String(UInt(sender.value))
    }

    func enable(issuer: String, label: String, secret: String) {
        let s = secret.characters.count
        self.navigationItem.rightBarButtonItem!.enabled = issuer != "" && label != "" && s > 0 && s % 8 == 0
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let str: String = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)

        if textField === secret {
            var unpadded = false
            for chr in str.characters.reverse() {
                if !unpadded {
                    if chr == "=" {
                        continue
                    } else {
                        unpadded = true
                    }
                }

                if !"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ234567".characters.contains(chr) {
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

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 8 : 32
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (sender !== self.navigationItem.rightBarButtonItem) {
            return
        }
        
        // Built URI
        let urlc = NSURLComponents()
        urlc.scheme = "otpauth"
        urlc.path = String(format: "/%@:%@", issuer.text!, label.text!)
        urlc.query = String(format: "algorithm=%@&digits=%@&secret=%@&period=%u",
            algo.titleForSegmentAtIndex(algo.selectedSegmentIndex)!,
            digits.titleForSegmentAtIndex(digits.selectedSegmentIndex)!,
            secret.text!, UInt(interval.text!)!)

        if (type.selectedSegmentIndex == 0) {
            urlc.query = urlc.query! + String(format: "&counter=%u", UInt(counter.text!)!)
            urlc.host = "hotp"
        } else {
            urlc.host = "totp"
        }

        // Make token
        TokenStore().add(Token(URL: urlc.URL!))
    }
}