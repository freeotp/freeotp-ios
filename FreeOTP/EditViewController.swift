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
import Photos
import UIKit

class EditViewController : UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var image: UIButton!
    @IBOutlet weak var issuer: UITextField!
    @IBOutlet weak var label: UITextField!

    @IBOutlet var reset: UIBarButtonItem!
    @IBOutlet var trash: UIBarButtonItem!
    @IBOutlet var yes: UIBarButtonItem!
    @IBOutlet var no: UIBarButtonItem!

    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var lockSwitch: UISwitch!

    @IBAction func lockClicked(_ sender: UISwitch) {
        token.locked = sender.isOn
        sender.isOn = token.locked
    }

    var token: Token!
    fileprivate var titleBackup: String?

    @IBAction func trashClicked(_ sender: UIBarButtonItem) {
        titleBackup = self.navigationItem.title
        navigationItem.title = ""

        UIView.animate(withDuration: 0.3, animations: {
            self.navigationItem.rightBarButtonItems = [self.yes, self.no]

            self.issuer.isEnabled = false
            self.label.isEnabled = false
            self.image.isEnabled = false
        }, completion: {
            (animated: Bool) -> Void in
            self.navigationItem.title = "Delete?"
        })
    }

    @IBAction func noClicked(_ sender: UIBarButtonItem) {
        navigationItem.title = ""
        issuer.isEnabled = true
        label.isEnabled = true
        image.isEnabled = PHPhotoLibrary.authorizationStatus() == .authorized

        UIView.animate(withDuration: 0.3, animations: {
            self.navigationItem.rightBarButtonItems = [self.reset, self.trash]
        }, completion: {
            (animated: Bool) -> Void in
            self.navigationItem.title = self.titleBackup
            self.textField(self.issuer, shouldChangeCharactersIn: NSRange(), replacementString: "")
        })
    }

    @IBAction func resetClicked(_ sender: UIBarButtonItem) {
        token.issuer = nil
        token.label = nil
        token.image = nil
        token2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let locking: Bool = Token.store.lockingSupported
        lockLabel.isEnabled = locking
        lockSwitch.isEnabled = locking
        lockSwitch.isOn = token.locked

        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (status: PHAuthorizationStatus) -> Void in
                // For some reason this callback doesn't appear to fire on the main thread.
                // So we will dispatch our updates to the main thread instead.
                DispatchQueue.main.async(execute: {
                    self.image.isEnabled = self.issuer.isEnabled && status == .authorized
                })
            })

        case .authorized:
            image.isEnabled = true

        default:
            break
        }

        self.navigationItem.rightBarButtonItems = [self.reset, self.trash]
        token2UI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let t = token {
            Token.store.save(t)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, sender === yes {
            TokenStore().erase(token: token)
            token = nil
        } else if let sender = sender as? UIButton, sender === image {
            (segue.destination as! ImageViewController).token = token
        }
    }

    @discardableResult func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        let diss = def("issuer") as! String!
        let dlab = def("label") as! String!
        let dimg = def("image") as! String?

        switch textField {
        case self.issuer:
            token.issuer = str
            reset.isEnabled = diss != str || dlab != label.text || dimg != token.image
        case self.label:
            token.label = str
            reset.isEnabled = diss != issuer.text || dlab != str || dimg != token.image
        default:
            return false
        }

        return true
    }

    fileprivate func token2UI() {
        issuer.text = token?.issuer
        label.text = token?.label

        ImageDownloader(image.bounds.size).fromURI(token?.image, completion: {
            (image: UIImage) -> Void in
            UIView.animate(withDuration: 0.3, animations: {
                self.image.setImage(image, for: UIControlState())
            })
        })

        textField(issuer, shouldChangeCharactersIn: NSRange(), replacementString: "")
    }

    fileprivate func def(_ name: String) -> AnyObject? {
        let prop = token.value(forKey: name)
        token.setValue(nil, forKey: name)
        let dflt = token.value(forKey: name)
        token.setValue(prop, forKey: name)
        return dflt as AnyObject?
    }
}
