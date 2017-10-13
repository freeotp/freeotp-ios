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
    fileprivate let DEFAULT = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)!
    fileprivate let size: CGSize

    init(_ size: CGSize) {
        self.size = size
        super.init()
    }

    func fromPHAsset(_ asset: PHAsset, completion: @escaping (UIImage) -> Void) {
        let opts: PHImageRequestOptions = PHImageRequestOptions()
        opts.isSynchronous = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: PHImageContentMode.aspectFill,
            options: opts,
            resultHandler: {
                (image: UIImage?, objects: [AnyHashable: Any]?) -> Void in
                completion(image == nil ? self.DEFAULT : image!)
            }
        )
    }

    func fromALAsset(_ asset: URL, completion: @escaping (UIImage) -> Void) {
        if asset.scheme == "assets-library" {
            let rslt = PHAsset.fetchAssets(withALAssetURLs: [asset], options: nil)
            if rslt.count > 0 {
                return fromPHAsset(rslt[0] , completion: completion)
            }
        }

        return completion(DEFAULT)
    }

    func fromURL(_ url: URL, completion: @escaping (UIImage) -> Void) {
        switch url.scheme! {
        case "file":
            if let img = UIImage(contentsOfFile: url.path) {
                return completion(img)
            }

        case "assets-library":
            return fromALAsset(url, completion: completion)

        case "http":
            fallthrough
        case "https":
            let moa = Moa()

            moa.onError = {
                (e, r) -> () in
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

    func fromURI(_ uri: String?, completion: @escaping (UIImage) -> Void) {
        if uri == nil { return completion(DEFAULT) }
        var uri = uri!
        
        if uri.hasPrefix("phasset:") {
            let id = String(uri[uri.index(uri.startIndex, offsetBy: "phasset:".characters.count)...])
            let rslt = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            if rslt.count > 0 {
                return fromPHAsset(rslt[0], completion: completion)
            }
            return completion(DEFAULT)
        }
        
        // App Transport Security doesn't allow arbitrary loading of HTTP resources any longer.
        // Most desired images can be retrieved via HTTPS, so just promote URIs to HTTPS.
        if uri.hasPrefix("http:") {
            uri.insert("s", at: uri.index(uri.startIndex, offsetBy: 4))
        }
        
        if let url = URL(string: uri) {
            return fromURL(url, completion: completion)
        }

        return completion(DEFAULT)
    }
}
