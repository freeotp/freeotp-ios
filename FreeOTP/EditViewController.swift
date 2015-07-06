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

    var token: Token!
    private var titleBackup: String?

    @IBAction func trashClicked(sender: UIBarButtonItem) {
        titleBackup = self.navigationItem.title
        navigationItem.title = ""

        UIView.animateWithDuration(0.3, animations: {
            self.navigationItem.rightBarButtonItems = [self.yes, self.no]

            self.issuer.enabled = false
            self.label.enabled = false
            self.image.enabled = false
        }, completion: {
            (animated: Bool) -> Void in
            self.navigationItem.title = "Delete?"
        })
    }

    @IBAction func noClicked(sender: UIBarButtonItem) {
        navigationItem.title = ""
        issuer.enabled = true
        label.enabled = true
        image.enabled = PHPhotoLibrary.authorizationStatus() == .Authorized

        UIView.animateWithDuration(0.3, animations: {
            self.navigationItem.rightBarButtonItems = [self.reset, self.trash]
        }, completion: {
            (animated: Bool) -> Void in
            self.navigationItem.title = self.titleBackup
            self.textField(self.issuer, shouldChangeCharactersInRange: NSRange(), replacementString: "")
        })
    }

    @IBAction func resetClicked(sender: UIBarButtonItem) {
        token.issuer = nil
        token.label = nil
        token.image = nil
        token2UI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        switch PHPhotoLibrary.authorizationStatus() {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization({
                (status: PHAuthorizationStatus) -> Void in
                // For some reason this callback doesn't appear to fire on the main thread.
                // So we will dispatch our updates to the main thread instead.
                dispatch_async(dispatch_get_main_queue(), {
                    self.image.enabled = self.issuer.enabled && status == .Authorized
                })
            })

        case .Authorized:
            image.enabled = true

        default:
            break
        }

        self.navigationItem.rightBarButtonItems = [self.reset, self.trash]
        token2UI()
    }

    override func viewWillDisappear(animated: Bool) {
        if let t = token {
            TokenStore().save(t)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if sender === yes {
            TokenStore().del(token)
            token = nil
        } else if sender === image {
            (segue.destinationViewController as! ImageViewController).token = token
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)

        let diss = def("issuer") as! String!
        let dlab = def("label") as! String!
        let dimg = def("image") as! String?

        switch textField {
        case self.issuer:
            token.issuer = str
            reset.enabled = diss != str || dlab != label.text || dimg != token.image
        case self.label:
            token.label = str
            reset.enabled = diss != issuer.text || dlab != str || dimg != token.image
        default:
            return false
        }

        return true
    }

    private func token2UI() {
        issuer.text = token?.issuer
        label.text = token?.label
        image.setImage(UIImage.fromURI(token?.image, size: image.bounds.size), forState: .Normal)
        textField(issuer, shouldChangeCharactersInRange: NSRange(), replacementString: "")
    }

    private func def(name: String) -> AnyObject? {
        let prop = token.valueForKey(name)
        token.setValue(nil, forKey: name)
        let dflt = token.valueForKey(name)
        token.setValue(prop, forKey: name)
        return dflt
    }
}
