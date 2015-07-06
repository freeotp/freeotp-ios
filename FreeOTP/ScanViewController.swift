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
import AVFoundation

class ScanViewController : UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var preview: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())
    var enabled: Bool = false

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var cancel: UIBarButtonItem!
    @IBOutlet weak var error: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        preview.frame = UIScreen.mainScreen().bounds
        preview.position = CGPointMake(CGRectGetMidX(view.layer.bounds), CGRectGetMidY(view.layer.bounds))
        view.layer.addSublayer(preview)

        do {
            let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            let input = try AVCaptureDeviceInput(device: device)
            preview.session.addInput(input)
        } catch {
            dismissViewControllerAnimated(true, completion: nil)
            return
        }

        let output = AVCaptureMetadataOutput()
        preview.session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

        preview.session.startRunning()

        image.layer.borderColor = UIColor.whiteColor().CGColor
        image.layer.borderWidth = 6
        view.addSubview(image)
        view.addSubview(error)

        activity.startAnimating()
        view.addSubview(activity)
    }

    override func viewDidAppear(animated: Bool) {
        enabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        enabled = false
    }

    private func showError(err: String) {
        enabled = false
        error.text = err
        UIView.animateWithDuration(2, animations: {
                self.error.alpha = 1.0
                self.activity.alpha = 0.0
            }, completion: {
                (_: Bool) -> Void in
                UIView.animateWithDuration(2, animations: {
                        self.error.alpha = 0.0
                        self.activity.alpha = 1.0
                    }, completion: {
                        (_: Bool) -> Void in
                        self.enabled = true
                    }
                )
            }
        )
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if (!enabled) {
            return
        }

        for metadata in metadataObjects as! [AVMetadataObject] {
            if metadata.type != AVMetadataObjectTypeQRCode {
                continue
            }

            let obj = metadata as! AVMetadataMachineReadableCodeObject
            let code = preview.transformedMetadataObjectForMetadataObject(obj)
            if (!image.frame.contains(code.bounds)) {
                continue
            }

            if let urlc = NSURLComponents(string: obj.stringValue) {
                if let token = Token(urlc: urlc) {
                    if TokenStore().add(token) {
                        preview.session.stopRunning()
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        showError("Token already exists!")
                    }
                } else {
                    showError("Invalid token URI!")
                }
            } else {
                showError("Invalid URI!")
            }

            break
        }
    }
}
