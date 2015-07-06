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

extension UIImage {
    private static let DEFAULT = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("default", ofType: "png")!)!

    class func fromAsset(asset: PHAsset, size: CGSize) -> UIImage {
        let opts: PHImageRequestOptions = PHImageRequestOptions()
        opts.synchronous = true

        var img: UIImage? = nil
        PHImageManager.defaultManager().requestImageForAsset(
            asset,
            targetSize: size,
            contentMode: PHImageContentMode.AspectFill,
            options: opts,
            resultHandler: {
                (image: UIImage?, objects: [NSObject: AnyObject]?) -> Void in
                img = image == nil ? UIImage.DEFAULT : image!
            }
        )

        return img!
    }

    class func fromURI(uri: String?, size: CGSize) -> UIImage {
        if let u = uri {
            if u.hasPrefix("phasset:") {
                let id = u.substringFromIndex(advance(u.startIndex, "phasset:".characters.count))
                let rslt = PHAsset.fetchAssetsWithLocalIdentifiers([id], options: nil)
                if rslt.count > 0 {
                    return fromAsset(rslt[0] as! PHAsset, size: size)
                }
            } else if let url = NSURL(string: u) {
                switch url.scheme {
                case "file":
                    if let p = url.path {
                        if let img = UIImage(contentsOfFile: p) {
                            return img
                        }
                    }

                case "assets-library":
                    let rslt = PHAsset.fetchAssetsWithALAssetURLs([url], options: nil)
                    if rslt.count > 0 {
                        return fromAsset(rslt[0] as! PHAsset, size: size)
                    }

                default:
                    break
                }
            }
        }

        return UIImage.DEFAULT
    }
}

