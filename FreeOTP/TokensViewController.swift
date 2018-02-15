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

class TokensViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate {
    fileprivate var lastPath: IndexPath? = nil
    fileprivate var store = TokenStore()

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "token", for: indexPath) as! TokenCell

        if let token = store.load(indexPath.row) {
            cell.state = nil

            ImageDownloader(cell.image.bounds.size).fromURI(token.image, completion: {
                (image: UIImage) -> Void in
                UIView.animate(withDuration: 0.3, animations: {
                    cell.image.image = image
                })
            })

            cell.lock.isHidden = !token.locked
            cell.outer.isHidden = token.kind != .totp
            cell.issuer.text = token.issuer
            cell.label.text = token.label
            cell.edit.token = token
            cell.share.token = token
        }

        return cell
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        collectionView?.reloadData()
    }

    fileprivate func next<T: UIViewController>(_ name: String, sender: AnyObject, dir: UIPopoverArrowDirection) -> T {
        switch UI_USER_INTERFACE_IDIOM() {
        case .pad:
            let vc = storyboard!.instantiateViewController(withIdentifier: name + "Nav") as! UINavigationController

            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.delegate = self
            vc.popoverPresentationController?.permittedArrowDirections = dir

            switch sender {
            case let b as UIBarButtonItem:
                vc.popoverPresentationController?.barButtonItem = b
            case let v as UIView:
                vc.popoverPresentationController?.sourceView = v
                vc.popoverPresentationController?.sourceRect = v.bounds
            default:
                break
            }

            presentedViewController?.dismiss(animated: true, completion: nil)
            present(vc, animated: true, completion: nil)
            return vc.topViewController! as! T

        default:
            let ret = storyboard?.instantiateViewController(withIdentifier: name) as! T
            navigationController?.pushViewController(ret, animated: true)
            return ret
        }
    }

    @IBAction func scanClicked(_ sender: UIBarButtonItem) {
        let vc: UIViewController = self.next("scan", sender: sender, dir: [.up, .down])
        vc.preferredContentSize = CGSize(
            width: UIScreen.main.bounds.width / 2,
            height: vc.preferredContentSize.height
        )
    }

    @IBAction func editClicked(_ sender: TokenButton) {
        let evc: EditViewController = self.next("edit", sender: sender, dir: [.left, .right])
        evc.token = sender.token
    }

    @IBAction func shareClicked(_ sender: TokenButton) {
        let svc: ShareViewController = self.next("share", sender: sender, dir: [.left, .right])
        svc.token = sender.token
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        if let cell = collectionView.cellForItem(at: indexPath) as! TokenCell? {
            if let token = store.load(indexPath.row) {
                cell.state = token.codes
            }
        }
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numCols: CGFloat = 1

        let o = UIApplication.shared.statusBarOrientation
        if o == .landscapeLeft || o == .landscapeRight {
            numCols += 1
        }

        if UI_USER_INTERFACE_IDIOM() == .pad {
            numCols += 1
        }

        let width = (collectionViewLayout as! UICollectionViewFlowLayout).columnWidth(collectionView, numCols: numCols)
        return CGSize(width: width, height: width / 3.25);
    }

    @objc func handleLongPress(_ gestureRecognizer:UIGestureRecognizer) {
        // Get the current index path.
        let p = gestureRecognizer.location(in: collectionView)
        let currPath = collectionView?.indexPathForItem(at: p)

        switch gestureRecognizer.state {
        case .began:
            if currPath == nil { return }

            lastPath = currPath
            if let cell = collectionView?.cellForItem(at: currPath!) {
                // Animate to the "lifted" state.
                UIView.animate(withDuration: 0.3, animations: {
                    cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self.collectionView?.bringSubview(toFront: cell)
                })
            }

            return

        case .changed:
            if currPath == nil { return }
            if lastPath == nil { return }

            let cell = collectionView?.cellForItem(at: lastPath!)
            if cell == nil { return }

            if lastPath!.row != currPath!.row {
                // Move the display.
                collectionView?.moveItem(at: lastPath!, to: currPath!)

                // Scroll the display to handle moving tokens up or down.
                if lastPath!.row < currPath!.row {
                    collectionView?.scrollToItem(at: currPath!, at: .top, animated: true)
                } else {
                    collectionView?.scrollToItem(at: currPath!, at: .bottom, animated: true)
                }

                // Write changes.
                store.move(lastPath!.row, to: currPath!.row)

                // Reset state.
                cell!.transform = CGAffineTransform(scaleX: 1.1, y: 1.1); // Moving the token resets the size...
                collectionView?.bringSubview(toFront: cell!) // ... and Z index.
                lastPath = currPath!;
            }

            cell!.center = gestureRecognizer.location(in: collectionView)
            return

        case .ended:
            if lastPath == nil { break }

            // Animate back to the original state, but in the new location.
            if let cell = collectionView?.cellForItem(at: lastPath!) {
                UIView.animate(withDuration: 0.3, animations: {
                    let l = self.collectionView?.collectionViewLayout
                    cell.center = l!.layoutAttributesForItem(at: self.lastPath!)!.center
                    cell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0);
                }, completion: { (Bool) -> Void in
                    self.lastPath = nil
                })
            }

            collectionView?.reloadData()

        default:
            collectionView?.reloadData()
        }
    }

    @IBAction func unwindToTokens(_ sender: UIStoryboardSegue) {
        collectionView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup collection view.
        collectionView?.allowsSelection = true;
        collectionView?.allowsMultipleSelection = false;

        // Setup gesture.
        let lpg = UILongPressGestureRecognizer(target: self, action: #selector(TokensViewController.handleLongPress(_:)))
        lpg.minimumPressDuration = 0.5
        collectionView?.addGestureRecognizer(lpg)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
    }
}
