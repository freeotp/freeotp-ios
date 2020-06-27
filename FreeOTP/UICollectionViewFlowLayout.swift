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

extension UICollectionViewFlowLayout {
    private var isLandscape: Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }

    func columnWidth(_ collectionView: UICollectionView, numCols: CGFloat) -> CGFloat {
        var width = collectionView.frame.size.width

        if #available(iOS 11.0, *), isLandscape {
            let window = UIApplication.shared.keyWindow
            width -= window?.safeAreaInsets.left ?? 0
            width -= window?.safeAreaInsets.right ?? 0
        }

        let ispace = minimumInteritemSpacing * (numCols - 1)
        let ospace = sectionInset.left + sectionInset.right
        return (width - ispace - ospace) / numCols
    }
}
