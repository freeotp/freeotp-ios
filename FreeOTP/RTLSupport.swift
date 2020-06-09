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

import UIKit
import TinyConstraints

extension UIView {
    private var usingDefaultLayoutDirection: Bool {
        return Self.userInterfaceLayoutDirection(for: self.semanticContentAttribute) != .rightToLeft
    }

    @discardableResult
    func rtlLeftToSuperview(offset: CGFloat = 0) -> Constraint {
        usingDefaultLayoutDirection ? leftToSuperview(offset: offset) : rightToSuperview(offset: -offset)
    }

    @discardableResult
    func rtlRightToSuperview(offset: CGFloat = 0) -> Constraint {
        usingDefaultLayoutDirection ? rightToSuperview(offset: offset) : leftToSuperview(offset: -offset)
    }

    @discardableResult
    func rtlLeftToRight(of constrainable: Constrainable, offset: CGFloat = 0) -> Constraint {
        usingDefaultLayoutDirection ? leftToRight(of: constrainable, offset: offset) : rightToLeft(of: constrainable, offset: -offset)
    }

    @discardableResult
    func rtlRightToLeft(of constrainable: Constrainable, offset: CGFloat = 0) -> Constraint {
        usingDefaultLayoutDirection ? rightToLeft(of: constrainable, offset: offset) : leftToRight(of: constrainable, offset: -offset)
    }
}
