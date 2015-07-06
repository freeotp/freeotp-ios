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
    private var sections: PHFetchResult! = nil
    private var items: PHFetchResult! = nil

    var token: Token!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var numCols: CGFloat = 4

        if collectionView.frame.size.width > collectionView.frame.size.height {
            numCols = floor(collectionView.frame.size.width / (collectionView.frame.size.height / numCols))
        }

        let width = (collectionViewLayout as! UICollectionViewFlowLayout).columnWidth(collectionView, numCols: numCols)
        return CGSizeMake(width, width);
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: nil)
        return items.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let a = items[indexPath.row] as! PHAsset
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("image", forIndexPath: indexPath)
        let i = c.viewWithTag(1) as! UIImageView

        PHImageManager.defaultManager().requestImageForAsset(a, targetSize: i.bounds.size, contentMode: .AspectFill, options: nil, resultHandler: {
            (image: UIImage?, objects: [NSObject : AnyObject]?) -> Void in
            if image != nil {
                i.image = image!
            }
        })

        return c
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)

        let a = items[indexPath.row] as! PHAsset
        token.image = "phasset:" + a.localIdentifier
        navigationController?.popViewControllerAnimated(true)
    }
}
