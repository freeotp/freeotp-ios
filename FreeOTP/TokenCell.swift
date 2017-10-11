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

class TokenCell : UICollectionViewCell {
    fileprivate var timer: Timer? = nil

    @IBOutlet weak var issuer: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var outer: CircleProgressView!
    @IBOutlet weak var inner: CircleProgressView!
    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var edit: TokenButton!
    @IBOutlet weak var share: TokenButton!
    @IBOutlet weak var lock: UIImageView!

    var state: [Token.Code]? {
        didSet {
            if state == nil || state?.count == 0 {
                UIView.animate(withDuration: 0.5,
                    animations: {
                        self.issuer.alpha = 1.0
                        self.label.alpha = 1.0
                        self.inner.alpha = 0.0
                        self.outer.alpha = 0.0
                        self.image.alpha = 1.0
                        self.code.alpha = 0.0
                        self.edit.alpha = 1.0
                        self.share.alpha = 1.0
                        self.lock.alpha = 0.5
                    }, completion: {(Bool) -> Void in
                        self.outer.progress = 0.0
                        self.inner.progress = 0.0
                        self.code.text = ""
                    })

                timer?.invalidate()
            } else if timer == nil || !timer!.isValid {
                timer = Timer.scheduledTimer(timeInterval: 0.1,
                    target: self,
                    selector: #selector(TokenCell.timerCallback(_:)),
                    userInfo: nil,
                    repeats: true)

                // Setup the UI for progress.
                UIView.animate(withDuration: 0.5, animations: {
                    self.issuer.alpha = 0.0
                    self.label.alpha = 0.0
                    self.inner.alpha = 1.0
                    self.outer.alpha = 1.0
                    self.image.alpha = 0.1
                    self.code.alpha = 1.0
                    self.edit.alpha = 0.0
                    self.share.alpha = 0.0
                    self.lock.alpha = 0.0
                })
            }
        }
    }

    fileprivate func progress(_ start: Date, _ point: Date, _ end: Date) -> CGFloat {
        let s = start.timeIntervalSince1970
        let p = point.timeIntervalSince1970
        let e = end.timeIntervalSince1970
        return 1.0 - CGFloat((p - s) / (e - s))
    }

    func timerCallback(_ timer: Timer) {
        let frst: Token.Code = state!.first!
        let last: Token.Code = state!.last!
        var curr: Token.Code? = nil

        let now = Date()
        for c in state == nil ? [] : state! {
            if c.from.timeIntervalSince1970 <= now.timeIntervalSince1970
                && now.timeIntervalSince1970 < c.to.timeIntervalSince1970 {
                    curr = c
                    break
            }
        }

        if curr == nil {
            self.state = nil;
        } else {
            inner.progress = progress(curr!.from as Date, now, curr!.to as Date)
            outer.progress = progress(frst.from as Date, now, last.to as Date)
            code.text = curr!.value;
        }
    }

    override func updateConstraints() {
        let base: CGFloat = frame.size.height / 8 * 1.5
        issuer.font = issuer.font.withSize(base * 0.85)
        label.font = label.font.withSize(base * 0.80)
        edit.titleLabel?.font = edit.titleLabel?.font.withSize(base * 0.80)
        share.titleLabel?.font = share.titleLabel?.font.withSize(base * 0.80)
        super.updateConstraints()
    }
}
