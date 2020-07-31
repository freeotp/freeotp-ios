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
    var urlc = URLComponents()
    var URI = URIParameters()
    var icon = TokenIcon()
    var urlSent = false

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var error: UILabel!

    fileprivate func orient(_ toInterfaceOrientation: UIInterfaceOrientation) {
        preview.frame = view.bounds

        switch toInterfaceOrientation {
        case .portrait:
            preview.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            preview.connection?.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            preview.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            preview.connection?.videoOrientation = .landscapeRight
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: { self.orient(toInterfaceOrientation) })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)
        view.layer.addSublayer(preview)

        image.layer.borderColor = UIColor.white.cgColor
        image.layer.borderWidth = 6
        view.addSubview(image)
        view.addSubview(error)

        activity.startAnimating()
        view.addSubview(activity)

        do {
            if let device = AVCaptureDevice.default(for: AVMediaType.video) {
                let input = try AVCaptureDeviceInput(device: device)
                preview.session!.addInput(input)
            }
        } catch {
            dismiss(animated: true, completion: nil)
            return
        }

        let output = AVCaptureMetadataOutput()
        preview.session!.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if output.availableMetadataObjectTypes.contains(.qr) {
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        } else {
            showError("Device does not support scanning")
            dismiss(animated: true, completion: nil)
            return
        }

        orient(UIApplication.shared.statusBarOrientation)
    }

    override func viewDidAppear(_ animated: Bool) {
        enabled = true
        if urlSent {
            urlSent = false
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
        } else {
            preview.session!.startRunning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        enabled = false
    }

    // Due to conditional navigation logic, we manage the navigation stack ourselves to avoid
    // a storyboard with too many segues
    func pushNextViewController(_ urlc: URLComponents) -> Bool {
        var issuer = ""

        if let label = URI.getLabel(from: urlc) {
            issuer = label.issuer
        }

        if URI.accountUnset(urlc) {
            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "URILabelViewController") as? URILabelViewController {
                viewController.inputUrlc = urlc
                if let navigator = navigationController {
                    navigator.pushViewController(viewController, animated: true)
                }
            }
        } else if URI.paramUnset(urlc, "image", "") &&
            icon.getFontAwesomeIcon(issuer: issuer) == nil && icon.issuerBrandMapping[issuer] == nil {
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
        } else {
            return false
        }

        return true
    }

    fileprivate func showError(_ err: String) {
        enabled = false
        error.text = err
        UIView.animate(withDuration: 2, animations: {
                self.error.alpha = 1.0
                self.activity.alpha = 0.0
            }, completion: {
                (_: Bool) -> Void in
                UIView.animate(withDuration: 2, animations: {
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

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if (!enabled) {
            return
        }
        for metadata in metadataObjects {
            if metadata.type != AVMetadataObject.ObjectType.qr {
                continue
            }

            let obj = metadata as! AVMetadataMachineReadableCodeObject
            let code = preview.transformedMetadataObject(for: obj)
            if (!image.frame.contains((code?.bounds)!)) {
                continue
            }

            if let urlc = URLComponents(string: obj.stringValue!) {
                if URI.validateURI(uri: urlc) {
                    self.urlc = urlc

                    preview.session?.stopRunning()

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
                } else {
                    showError("Invalid URI!")
                }
            } else {
                showError("Invalid URI!")
            }

            break
        }
    }
}
