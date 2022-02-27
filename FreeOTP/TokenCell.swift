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

import TinyConstraints
import UIKit

protocol TokenCellDelegate: AnyObject {
    func share(token: Token, sender: UIView?)
}

class TokenCell: UICollectionViewCell {
    static let identifier = "TokenCell"

    private let defaultIcon = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)

    private(set) lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.image = defaultIcon
        return view
    }()

    private(set) lazy var outerProgressView = CircleProgressView()

    private(set) lazy var innerProgressView: CircleProgressView = {
        let view = CircleProgressView()
        view.hollow = false
        view.threshold = -0.25
        return view
    }()

    private(set) lazy var lockImagView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "LockIcon")
        view.tintColor = UIColor.app.cardBackground
        view.contentMode = .scaleAspectFit
        return view
    }()

    private(set) lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 2
        return view
    }()

    private(set) lazy var issuerLabel: UILabel = {
        let view = UILabel()
        view.font = .dynamicSystemFont(ofSize: 16, weight: .regular)
        view.textColor = UIColor.app.primaryText
        view.setCompressionResistance(.init(751), for: .vertical)
        return view
    }()

    private(set) lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = .dynamicSystemFont(ofSize: 14, weight: .regular)
        view.textColor = UIColor.app.secondaryText
        view.numberOfLines = 0
        return view
    }()

    private(set) lazy var shareButton: UIButton = {
        let view = UIButton(type: .system)
        view.tintColor = UIColor.app.accent
        view.setImage(UIImage(named: "ShareIcon"), for: .normal)
        return view
    }()

    private(set) lazy var codeLabel: UILabel = {
        let view = UILabel()
        view.adjustsFontSizeToFitWidth = true
        view.baselineAdjustment = .alignCenters
        view.font = .monospacedDigitSystemFont(ofSize: 100, weight: .regular)
        view.minimumScaleFactor = 0.2
        view.textAlignment = .center
        view.textColor = UIColor.app.primaryText
        return view
    }()

    var timer: Timer?
    var state: [Token.Code]? {
        didSet { animate() }
    }

    var token: Token? {
        didSet {
            guard let token = token else { return }
            lockImagView.isHidden = !token.locked
            outerProgressView.isHidden = token.kind != .totp
            issuerLabel.text = token.issuer
            subtitleLabel.text = token.label
        }
    }

    weak var delegate: TokenCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = UIColor.app.cardBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(outerProgressView)
        contentView.addSubview(innerProgressView)
        contentView.addSubview(lockImagView)
        contentView.addSubview(stackView)
        contentView.addSubview(shareButton)
        contentView.addSubview(codeLabel)

        stackView.addArrangedSubview(issuerLabel)
        stackView.addArrangedSubview(subtitleLabel)

        imageView.topToSuperview()
        imageView.rtlLeftToSuperview()
        imageView.bottomToSuperview()
        imageView.widthToHeight(of: imageView)

        outerProgressView.center(in: imageView)
        outerProgressView.size(to: imageView, multiplier: 1 / 2)

        innerProgressView.center(in: imageView)
        innerProgressView.size(to: imageView, multiplier: 5 / 12)

        lockImagView.rtlLeftToSuperview(offset: 4)
        lockImagView.bottomToSuperview(offset: -4)
        lockImagView.size(CGSize(width: 14, height: 14))

        stackView.rtlLeftToRight(of: imageView, offset: 12)
        stackView.rtlRightToLeft(of: shareButton, offset: -12)
        stackView.centerYToSuperview()

        shareButton.rtlRightToSuperview(offset: -12)
        shareButton.centerYToSuperview()
        shareButton.size(CGSize(width: 24, height: 24))

        codeLabel.topToSuperview()
        codeLabel.rtlLeftToRight(of: imageView, offset: 12)
        codeLabel.rtlRightToSuperview(offset: -12)
        codeLabel.bottomToSuperview()

        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
    }

    @objc private func share() {
        if let token = token {
            delegate?.share(token: token, sender: shareButton)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = defaultIcon
    }

    private func animate() {
        let showToken: Bool

        if state == nil || state?.count == 0 {
            timer?.invalidate()
            showToken = false
        } else if timer == nil || !timer!.isValid {
            timer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(timerCallback),
                userInfo: nil,
                repeats: true
            )

            showToken = true
        } else {
            return
        }

        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.issuerLabel.alpha = showToken ? 0 : 1
                self.subtitleLabel.alpha = showToken ? 0 : 1
                self.innerProgressView.alpha = showToken ? 1 : 0
                self.outerProgressView.alpha = showToken ? 1 : 0
                self.imageView.alpha = showToken ? 0.4 : 1
                self.codeLabel.alpha = showToken ? 1 : 0
                self.shareButton.alpha = showToken ? 0 : 1
                self.lockImagView.alpha = showToken ? 0 : 1
            },
            completion: { _ in
                if showToken == false {
                    self.outerProgressView.progress = 0.0
                    self.innerProgressView.progress = 0.0
                    self.codeLabel.text = ""
                }
            }
        )
    }

    fileprivate func progress(_ start: Date, _ point: Date, _ end: Date) -> CGFloat {
        let s = start.timeIntervalSince1970
        let p = point.timeIntervalSince1970
        let e = end.timeIntervalSince1970
        return 1.0 - CGFloat((p - s) / (e - s))
    }

    @objc func timerCallback() {
        let state = self.state ?? []
        let first = state.first
        let last = state.last

        var curr: Token.Code?

        let now = Date()

        for c in state {
            if c.from.timeIntervalSince1970 <= now.timeIntervalSince1970 && now.timeIntervalSince1970 < c.to.timeIntervalSince1970 {
                curr = c
                break
            }
        }

        if let curr = curr, let first = first, let last = last {
            innerProgressView.progress = progress(curr.from as Date, now, curr.to as Date)
            outerProgressView.progress = progress(first.from as Date, now, last.to as Date)

            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: .transitionCrossDissolve,
                animations: { self.codeLabel.text = curr.value },
                completion: nil
            )
        } else {
            self.state = nil
        }
    }

    override func updateConstraints() {
        let base: CGFloat = frame.size.height / 8 * 1.5
        issuerLabel.font = issuerLabel.font.withSize(base * 0.85)
        subtitleLabel.font = subtitleLabel.font.withSize(base * 0.80)
        super.updateConstraints()
    }
}
