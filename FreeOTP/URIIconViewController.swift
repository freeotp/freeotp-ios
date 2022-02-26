//
//  URIIconViewController.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 2/10/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class URIIconViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {
    // MARK: - Properties
    struct selectedIcon {
        var name: String = ""
        var faName: String = ""
        var type: faIconType = .brands
    }

    var inputUrlc = URLComponents()
    var outputUrlc = URLComponents()
    var URI = URIParameters()
    var icon = TokenIcon()
    var selectedIndexPath = IndexPath()
    var selectedIconfaName = ""
    var suggestedIcons = [IconMatch]()
    var selection = selectedIcon()
    var uriColor = ""
    var brandIcons = [(name: String, value: String)]()
    var solidIcons = [(name: String, value: String)]()

    // MARK: - Outlets
    @IBOutlet weak var iconCollectionView: UICollectionView! {
        didSet {
            iconCollectionView.delegate = self
            iconCollectionView.dataSource = self
        }
    }

    @IBOutlet weak var recommendedIconCollectionView: UICollectionView! {
        didSet {
            recommendedIconCollectionView.delegate = self
            recommendedIconCollectionView.dataSource = self
        }
    }
    @IBOutlet weak var iconSearchBar: UISearchBar!
    @IBOutlet weak var recommendedLabel: UILabel!

    // MARK: - Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            brandIcons = icon.iconsBrand
            solidIcons = icon.iconsSolid
        } else {
            brandIcons = icon.iconsBrand.filter { $0.name.contains(searchText.lowercased()) }
            solidIcons = icon.iconsSolid.filter { $0.name.contains(searchText.lowercased()) }
        }
        iconCollectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.endEditing(true)
    }

    // MARK: - Collection View
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.recommendedIconCollectionView {
            return 1
        } else {
            return 2
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.recommendedIconCollectionView {
            return suggestedIcons.count
         } else {
            switch section {
            case 0:
                return brandIcons.count
            case 1:
                return solidIcons.count
            default:
                break
            }
         }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        let size = CGSize(width: 50, height: 50)

        if collectionView == self.recommendedIconCollectionView {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedIconCell", for:  indexPath)

            if let iconCell = cell as? RecommendedIconCell {
                if let image = icon.getFontAwesomeIcon(faName: suggestedIcons[indexPath.item].name, faType: .brands, size: size) {
                    iconCell.iconImage.image = image.addImagePadding(x: 30, y: 30)

                    iconCell.iconImage.backgroundColor = icon.getBackgroundColor(name: suggestedIcons[indexPath.item].name, uriColor: uriColor)
                }
            }
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontAwesomeIconCell", for:  indexPath)

            switch indexPath.section {
            case 0:
                if let iconCell = cell as? FontAwesomeIconCell {
                    if let image = icon.getFontAwesomeIcon(faName: brandIcons[indexPath.item].value, faType: .brands, size: size) {
                        iconCell.iconImage.image = image.addImagePadding(x: 30, y: 30)

                        iconCell.iconImage.backgroundColor = icon.getBackgroundColor(name: brandIcons[indexPath.item].value, uriColor: uriColor)
                    }
                }
            case 1:
                if let iconCell = cell as? FontAwesomeIconCell {
                    if let image = icon.getFontAwesomeIcon(faName: solidIcons[indexPath.item].value, faType: .solid, size: size) {
                        iconCell.iconImage.image = image.addImagePadding(x: 30, y: 30)
                    }

                    iconCell.iconImage.backgroundColor = icon.getBackgroundColor(name: solidIcons[indexPath.item].value, uriColor: uriColor)
                }
            default:
                break
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeaderID", for: indexPath) as? SectionHeader {

            if sectionHeader.sectionHeaderLabel.text != nil {
                var headerText = ""
                switch indexPath.section {
                case 0:
                    headerText = "Choose an icon"
                case 1:
                    headerText = "Other"
                default:
                    break
                }
                sectionHeader.sectionHeaderLabel.text = headerText
            }
            return sectionHeader
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Clear previous selection
        let prevCell = iconCollectionView.cellForItem(at: selectedIndexPath)
        prevCell?.layer.borderWidth = 0
        prevCell?.layer.borderColor = UIColor.gray.cgColor

        selectedIndexPath = indexPath

        if collectionView == self.recommendedIconCollectionView {
            selection = .init(name: suggestedIcons[indexPath.item].name, faName: suggestedIcons[indexPath.item].name, type: .recommended)
        } else {
            switch indexPath.section {
            case 0:
                selection = .init(name: brandIcons[indexPath.item].name, faName: brandIcons[indexPath.item].value, type: .brands)
            case 1:
                selection = .init(name: solidIcons[indexPath.item].name, faName: solidIcons[indexPath.item].value, type: .solid)
            default:
                break
            }
        }
        performSegue(withIdentifier: "unwindToMainIconWithSegue", sender: self)
    }

    // MARK: - Methods
    func presentAlert(_ title: String, _ message: String, _ actionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        outputUrlc = inputUrlc

        iconCollectionView.layer.borderColor = UIColor.darkGray.cgColor
        iconCollectionView.layer.borderWidth = 2.0
        iconCollectionView.layer.cornerRadius = 5.0

        iconCollectionView.allowsMultipleSelection = false

        suggestedIcons = icon.getSuggestions(urlc: outputUrlc)
        if suggestedIcons.count == 0 {
            recommendedIconCollectionView.isHidden = true
            recommendedLabel.isHidden = true
        }

        iconSearchBar.delegate = self

        brandIcons = icon.iconsBrand
        solidIcons = icon.iconsSolid
    }
}
