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

class TokensViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate,
                             UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    let defaultIcon = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)
    fileprivate var lastPath: IndexPath? = nil
    fileprivate var store = TokenStore()
    var icon = TokenIcon()

    @IBOutlet weak var aboutButton: UIBarButtonItem!
    @IBOutlet weak var scanButton: UIBarButtonItem!

    private lazy var emptyStateView = EmptyStateView()
    
    // the search bar
    let searchBar = UISearchBar()
    
    // bar buttons
    private var scanQrCodeButton = UIBarButtonItem()
    private var appInfoButton = UIBarButtonItem()
    
    // the tokens array
    private var tokensArray: [Token]! = [] // contains all the tokens as loaded from the store
    private var searchedTokensArray: [Token]! = [] // contains the filtered tokens
    
    // search params
    private var searchingTokens = false
    

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return searchingTokens ? searchedTokensArray.count : store.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TokenCell.identifier, for: indexPath) as! TokenCell

        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        let imageSize = CGSize(width: size.height, height: size.height)
        
        if let token = getTokenAtIndex(tokenIndex: indexPath.row) {
        
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
            if let token = getTokenAtIndex(tokenIndex: indexPath.row)  {
                cell.state = token.codes
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
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

    // Drag and drop delegate methods
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // no need for drag and drop when searching
        if searchingTokens == false {
            if let token = store.load(indexPath.row) {
                let itemProvider = NSItemProvider(object: token)

                let dragItem = UIDragItem(itemProvider: itemProvider)
                return [dragItem]
            } else {
                return []
            }
        } else {
            return []
        }
      
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let dstIndex = coordinator.destinationIndexPath else { return }

        for item in coordinator.items {
            // Drag item originated in the collection view
            if let srcIndex = item.sourceIndexPath {
                store.move(srcIndex.row, to: dstIndex.row)
                collectionView.moveItem(at: srcIndex, to: dstIndex)
                coordinator.drop(item.dragItem, toItemAt: dstIndex)
            } else {
                // Drag and drop from other apps not implemented
            }
        }
    }
    

    @objc func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let p = gestureRecognizer.location(in: collectionView)
            if let currPath = collectionView?.indexPathForItem(at: p) {
                if let cell = collectionView?.cellForItem(at: currPath) {
                    if let token = getTokenAtIndex(tokenIndex: currPath.row) {
                        UIView.animate(withDuration: 0.5, animations: {
                            cell.transform = CGAffineTransform(translationX: 1200, y: 0)
                        }, completion: { (Bool) -> Void in
                            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                            let removeAction: UIAlertAction = UIAlertAction(title: "Remove token", style: .destructive) { action -> Void in
                                TokenStore().erase(token: token)
                                var array = [IndexPath]()
                                array.append(currPath)
                                
                                if self.searchingTokens {
                                    self.searchedTokensArray.remove(at: currPath.row)
                                    self.collectionView.deleteItems(at: array)
                                   
                                } else {
                                    self.collectionView.deleteItems(at: array)
                                }
                                
                                // reload the search button
                                self.showSearchButton()
                                
                                // also reload the tokens array
                                self.tokensArray = self.store.getAllTokens()
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
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        collectionView.dragInteractionEnabled = true

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

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe))
        collectionView?.addGestureRecognizer(swipeGesture)
        
        // show the search bar only if there are items to be searched
        showSearchButton()
        
    }
    
    func showSearchButton() {
        
        let tokenCount = searchingTokens ? searchedTokensArray.count : store.count
        
        if  tokenCount > 0 {
            configureSearchBar()
        } else {
            navigationItem.leftBarButtonItem = nil
        }
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
    
    func configureSearchBar() {
        // init search bar
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.tintColor = UIColor.app.accent
        searchBar.isAccessibilityElement = false
        searchBar.accessibilityIdentifier = "search-bar"
        searchBar.placeholder = "Search Tokens"
        
        // style the search bar
        navigationController?.navigationBar.isTranslucent = false
        //navigationController?.navigationBar.barStyle = .black
        
        // set the button refs for later
        self.scanQrCodeButton = self.scanButton
        self.appInfoButton = self.aboutButton
        
        // add the search button
        setSearchButton()
        
    }
    
    private func setSearchButton(){
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(handleShowSearchBar))
        barButtonItem.accessibilityIdentifier = "navbarSearchItem"
        navigationItem.leftBarButtonItem = barButtonItem
    }
    
    // helper func to return token at a certain position depending on the state of the UICollectionView
    private func getTokenAtIndex(tokenIndex: Int) -> Token? {
        return searchingTokens ? searchedTokensArray[tokenIndex] : store.load(tokenIndex)
    }
    
    @objc func handleShowSearchBar() {
        search(shouldShow: true)
        searchBar.becomeFirstResponder()
    }
    
    func showBarButtons(shouldShow: Bool){
        
        if shouldShow {
            setSearchButton()
            navigationItem.rightBarButtonItems = [self.appInfoButton, self.scanQrCodeButton]
        } else {
            navigationItem.rightBarButtonItems = nil
            navigationItem.leftBarButtonItem = nil
        }
        
    }
    func search(shouldShow: Bool){
        showBarButtons(shouldShow: !shouldShow)
        searchBar.showsCancelButton = shouldShow
        navigationItem.titleView = shouldShow ? searchBar : nil
    }

}

extension TokensViewController: TokenCellDelegate {
    func share(token: Token, sender: UIView?) {
        let svc: ShareViewController = self.next("share", sender: sender, dir: [.left, .right])
        svc.token = token
    }
}

extension TokensViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tokensArray = store.getAllTokens()
    }
    
   
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        search(shouldShow: false)
        searchingTokens = false
        tokensArray.removeAll()
        searchedTokensArray.removeAll()
        reloadData()
        
        searchBar.text = ""
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty {
            searchedTokensArray = tokensArray
        } else {
            searchingTokens = true
            searchedTokensArray = tokensArray.filter {
                $0.issuer.lowercased().contains(searchText.lowercased()) == true
                    || $0.label.lowercased().contains(searchText.lowercased()) == true
                        || $0.account.lowercased().contains(searchText.lowercased()) == true
            }
        }

        reloadData()
    }
    
}
