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

    private func orient(toInterfaceOrientation: UIInterfaceOrientation) {
        preview.frame = view.bounds

        switch toInterfaceOrientation {
        case .Portrait:
            preview.connection.videoOrientation = .Portrait
        case .PortraitUpsideDown:
            preview.connection.videoOrientation = .PortraitUpsideDown
        case .LandscapeLeft:
            preview.connection.videoOrientation = .LandscapeLeft
        case .LandscapeRight:
            preview.connection.videoOrientation = .LandscapeRight
        case .Unknown:
            break
        }
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        UIView.animateWithDuration(duration, animations: { self.orient(toInterfaceOrientation) })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.position = CGPointMake(CGRectGetMidX(view.layer.bounds), CGRectGetMidY(view.layer.bounds))
        view.layer.addSublayer(preview)

        image.layer.borderColor = UIColor.whiteColor().CGColor
        image.layer.borderWidth = 6
        view.addSubview(image)
        view.addSubview(error)

        activity.startAnimating()
        view.addSubview(activity)

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
        orient(UIApplication.sharedApplication().statusBarOrientation)
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
                if let token = TokenStore().add(urlc) {
                    preview.session.stopRunning()

                    ImageDownloader(image.bounds.size).fromURI(token.image, completion: {
                        (image: UIImage) -> Void in

                        UIView.transitionWithView(
                            self.image,
                            duration: 2,
                            options: .TransitionCrossDissolve,
                            animations: {
                                self.image.image = image
                                self.activity.alpha = 0.0
                                self.activity.stopAnimating()
                            }, completion: {
                                (_: Bool) -> Void in
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        )
                    })
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
