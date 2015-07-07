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

import moa
import Foundation
import Photos
import UIKit

class ImageDownloader : NSObject {
    private let DEFAULT = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("default", ofType: "png")!)!
    private let size: CGSize

    init(_ size: CGSize) {
        self.size = size
        super.init()
    }

    func fromPHAsset(asset: PHAsset, completion: (UIImage) -> Void) {
        let opts: PHImageRequestOptions = PHImageRequestOptions()
        opts.synchronous = true

        PHImageManager.defaultManager().requestImageForAsset(
            asset,
            targetSize: size,
            contentMode: PHImageContentMode.AspectFill,
            options: opts,
            resultHandler: {
                (image: UIImage?, objects: [NSObject: AnyObject]?) -> Void in
                completion(image == nil ? self.DEFAULT : image!)
            }
        )
    }

    func fromALAsset(asset: NSURL, completion: (UIImage) -> Void) {
        if asset.scheme == "assets-library" {
            let rslt = PHAsset.fetchAssetsWithALAssetURLs([asset], options: nil)
            if rslt.count > 0 {
                return fromPHAsset(rslt[0] as! PHAsset, completion: completion)
            }
        }

        return completion(DEFAULT)
    }

    func fromURL(url: NSURL, completion: (UIImage) -> Void) {
        switch url.scheme {
        case "file":
            if let p = url.path {
                if let img = UIImage(contentsOfFile: p) {
                    return completion(img)
                }
            }

        case "assets-library":
            return fromALAsset(url, completion: completion)

        case "http":
            fallthrough
        case "https":
            let moa = Moa()

            moa.onError = {
                (e: NSError?, r: NSHTTPURLResponse?) -> () in
                moa.errorImage = nil // Keep a strong reference to moa
                completion(self.DEFAULT)
            }

            moa.onSuccess = {
                (i: MoaImage) -> MoaImage? in
                moa.errorImage = nil // Keep a strong reference to moa
                completion(i)
                return nil
            }

            moa.url = url.absoluteString
            return

        default:
            break
        }

        return completion(DEFAULT)
    }

    func fromURI(uri: String?, completion: (UIImage) -> Void) {
        if uri == nil { return completion(DEFAULT) }

        if uri!.hasPrefix("phasset:") {
            let id = uri!.substringFromIndex(advance(uri!.startIndex, "phasset:".characters.count))
            let rslt = PHAsset.fetchAssetsWithLocalIdentifiers([id], options: nil)
            if rslt.count > 0 {
                return fromPHAsset(rslt[0] as! PHAsset, completion: completion)
            }
        } else if let url = NSURL(string: uri!) {
            return fromURL(url, completion: completion)
        }

        return completion(DEFAULT)
    }
}
