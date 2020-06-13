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
    let defaultIcon = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)
    fileprivate var lastPath: IndexPath? = nil
    fileprivate var store = TokenStore()
    var icon = TokenIcon()

    @IBOutlet weak var aboutButton: UIBarButtonItem!

    private lazy var emptyStateView = EmptyStateView()

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TokenCell.identifier, for: indexPath) as! TokenCell

        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        let imageSize = CGSize(width: size.height, height: size.height)

        if let token = store.load(indexPath.row) {
            cell.state = nil
            var iconName = ""

            if let image = token.image {
                if image.hasSuffix("/FreeOTP.app/default.png") {
                    cell.imageView.image = defaultIcon
                } else {
                    ImageDownloader(imageSize).fromURI(token.image, completion: {
                        (image: UIImage) -> Void in
                        UIView.animate(withDuration: 0.3, animations: {
                            cell.imageView.image = image.addImagePadding(x: 30, y: 30)
                        })
                    })
                }
            } else {
                // Retrieve and use saved issuer -> icon mapping in User Defaults
                if let custIcon = icon.getCustomIcon(issuer: token.issuer, size: imageSize) {
                    cell.imageView.image = custIcon.iconImg.addImagePadding(x: 30, y: 30)
                    iconName = custIcon.name
                    // Issuer matches an icon name brand
                } else if let faIcon = icon.getfaIconName(for: token.issuer) {
                    let image = icon.getFontAwesomeIcon(faName: faIcon, faType: .brands, size: imageSize)
                    cell.imageView.image = image?.addImagePadding(x: 30, y: 30)
                    iconName = faIcon
                }
            }

            cell.imageView.backgroundColor = icon.getBackgroundColor(name: iconName)

            cell.token = token
            cell.delegate = self
        }

        return cell
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        reloadData()
    }

    fileprivate func next<T: UIViewController>(_ name: String, sender: AnyObject?, dir: UIPopoverArrowDirection) -> T {
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
        showScanScreen(sender)
    }

    private func showScanScreen(_ sender: AnyObject) {
        let vc: UIViewController = self.next("scan", sender: sender, dir: [.up, .down])
        vc.preferredContentSize = CGSize(
            width: UIScreen.main.bounds.width / 2,
            height: vc.preferredContentSize.height
        )
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

    @objc func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let p = gestureRecognizer.location(in: collectionView)
            if let currPath = collectionView?.indexPathForItem(at: p) {
                if let cell = collectionView?.cellForItem(at: currPath) {
                    if let token = store.load(currPath.row) {
                        UIView.animate(withDuration: 0.5, animations: {
                            cell.transform = CGAffineTransform(translationX: 1200, y: 0)
                        }, completion: { (Bool) -> Void in
                            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                            let removeAction: UIAlertAction = UIAlertAction(title: "Remove token", style: .destructive) { action -> Void in
                                TokenStore().erase(token: token)
                                var array = [IndexPath]()
                                array.append(currPath)
                                self.collectionView.deleteItems(at: array)
                            }

                            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                                UIView.animate(withDuration: 0.3, animations: {
                                    cell.transform = .identity
                                })
                                self.reloadData()
                            }

                            actionSheetController.addAction(removeAction)
                            actionSheetController.addAction(cancelAction)

                            /* Handle iPad popover */
                            if let popoverController = actionSheetController.popoverPresentationController {
                                popoverController.sourceView = self.view
                                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)

                            }

                            self.present(actionSheetController, animated: true)
                        })
                    }
                }
            }
        }
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
                    self.collectionView?.bringSubviewToFront(cell)
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
                collectionView?.bringSubviewToFront(cell!) // ... and Z index.
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

            reloadData()

        default:
            reloadData()
        }
    }

    @IBAction func unwindToTokens(_ sender: UIStoryboardSegue) {
        reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            aboutButton.image = UIImage(systemName: "info.circle")
        } else {
            aboutButton.image = icon.getFontAwesomeIcon(faName: "fa-info-circle", faType: .solid)
        }

        // Setup collection view.
        collectionView?.backgroundColor = UIColor.app.background
        collectionView?.alwaysBounceVertical = true
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = false
        collectionView?.register(TokenCell.self, forCellWithReuseIdentifier: TokenCell.identifier)

        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .always
        }

        // EmptyState
        emptyStateView.alpha = 0
        emptyStateView.addToken = { self.showScanScreen(self.emptyStateView.addTokenButton) }
        view.addSubview(emptyStateView)
        emptyStateView.topToSuperview()
        emptyStateView.rtlLeftToSuperview()
        emptyStateView.rtlRightToSuperview()
        emptyStateView.bottomToSuperview()

        let lpg = UILongPressGestureRecognizer(target: self, action: #selector(TokensViewController.handleLongPress(_:)))
        lpg.minimumPressDuration = 0.5
        collectionView?.addGestureRecognizer(lpg)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe))
        collectionView?.addGestureRecognizer(swipeGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    func reloadData() {
        collectionView?.reloadData()

        UIView.animate(withDuration: 0.25) {
            self.emptyStateView.alpha = self.store.count == 0 ? 1 : 0
        }
    }
}

extension TokensViewController: TokenCellDelegate {
    func share(token: Token, sender: UIView?) {
        let svc: ShareViewController = self.next("share", sender: sender, dir: [.left, .right])
        svc.token = token
    }
}
