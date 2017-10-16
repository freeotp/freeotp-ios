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

class ImageViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout {
    fileprivate var sections: PHFetchResult<PHAsset>! = nil
    fileprivate var items: PHFetchResult<PHAsset>! = nil

    var token: Token!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numCols: CGFloat = 4

        if collectionView.frame.size.width > collectionView.frame.size.height {
            numCols = floor(collectionView.frame.size.width / (collectionView.frame.size.height / numCols))
        }

        let width = (collectionViewLayout as! UICollectionViewFlowLayout).columnWidth(collectionView, numCols: numCols)
        return CGSize(width: width, height: width);
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let a = items[indexPath.row]
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath)
        let i = c.viewWithTag(1) as! UIImageView

        PHImageManager.default().requestImage(for: a, targetSize: i.bounds.size, contentMode: .aspectFill, options: nil, resultHandler: {
            (image: UIImage?, objects: [AnyHashable: Any]?) -> Void in
            if image != nil {
                i.image = image!
            }
        })

        return c
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let a = items[indexPath.row]
        token.image = "phasset:" + a.localIdentifier
        navigationController?.popViewController(animated: true)
    }
}
