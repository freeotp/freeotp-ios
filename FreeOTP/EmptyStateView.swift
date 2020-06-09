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

class EmptyStateView: UIView {
    private(set) lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 8
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .dynamicSystemFont(ofSize: 14, weight: .regular)
        view.text = "No tokens have been added yet."
        view.textAlignment = .center
        view.textColor = UIColor.app.secondaryText
        return view
    }()

    private(set) lazy var addTokenButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Add a token", for: .normal)
        view.setTitleColor(UIColor.app.accent, for: .normal)
        return view
    }()

    var addToken: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.app.background

        addSubview(stackView)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(addTokenButton)

        stackView.centerYToSuperview()
        stackView.leftToSuperview(offset: 24)
        stackView.rightToSuperview(offset: -24)

        addTokenButton.addTarget(self, action: #selector(addTokenAction), for: .touchUpInside)
    }

    @objc private func addTokenAction() {
        addToken?()
    }
}
