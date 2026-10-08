//
//  TwoLineNavigationTitleView.swift
//
//
//  Created by Mohamed Afifi on 2023-01-02.
//

import UIKit

public class TwoLineNavigationTitleView: UIControl {
    // MARK: Lifecycle

    public init(firstLineFont: UIFont, secondLineFont: UIFont) {
        self.firstLineFont = firstLineFont
        self.secondLineFont = secondLineFont
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var firstLine: String = "" {
        didSet {
            firstLineLabel.text = firstLine
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var secondLine: String = "" {
        didSet {
            secondLineLabel.text = secondLine
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var showsDropdownChevron: Bool = false {
        didSet {
            chevronImageView.isHidden = !showsDropdownChevron
            accessibilityTraits = showsDropdownChevron ? .button : .header
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var firstLineColor: UIColor = .label {
        didSet {
            firstLineLabel.textColor = firstLineColor
        }
    }

    public var secondLineColor: UIColor = .secondaryLabel {
        didSet {
            secondLineLabel.textColor = secondLineColor
        }
    }

    public var chevronColor: UIColor = .label {
        didSet {
            chevronImageView.tintColor = chevronColor
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            guard showsDropdownChevron else { return }
            UIView.animate(withDuration: 0.12) {
                self.alpha = self.isHighlighted ? 0.55 : 1.0
            }
        }
    }

    override public var intrinsicContentSize: CGSize {
        let line1Width = firstLineLabel.intrinsicContentSize.width
        let line2Width = secondLineLabel.intrinsicContentSize.width
            + (showsDropdownChevron ? (chevronImageView.intrinsicContentSize.width + 4) : 0)

        if isCompressed {
            let totalWidth = line1Width + 8 + line2Width
            return CGSize(width: ceil(totalWidth), height: 32)
        } else {
            let maxWidth = max(line1Width, line2Width)
            let height = firstLineLabel.intrinsicContentSize.height + secondLineLabel.intrinsicContentSize.height + 1
            return CGSize(width: ceil(maxWidth), height: max(36, ceil(height)))
        }
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Expand touch target vertically and horizontally for comfortable tapping
        let touchArea = bounds.insetBy(dx: -20, dy: -10)
        return touchArea.contains(point)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateIsCompressed()
    }

    // MARK: Private

    private let firstLineLabel = UILabel()
    private let secondLineLabel = UILabel()
    private let chevronImageView = UIImageView()

    private let secondLineStack = UIStackView()
    private let contentStack = UIStackView()

    private let firstLineFont: UIFont
    private let secondLineFont: UIFont

    private var isCompressed = false {
        didSet {
            updateStackLayout()
        }
    }

    private func setUp() {
        isUserInteractionEnabled = true

        // First line: Title label
        firstLineLabel.font = firstLineFont
        firstLineLabel.textColor = firstLineColor
        firstLineLabel.textAlignment = .center
        firstLineLabel.numberOfLines = 1
        firstLineLabel.lineBreakMode = .byTruncatingTail
        firstLineLabel.adjustsFontSizeToFitWidth = true
        firstLineLabel.minimumScaleFactor = 0.85
        firstLineLabel.allowsDefaultTighteningForTruncation = true
        firstLineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Second line: Subtitle label
        secondLineLabel.font = secondLineFont
        secondLineLabel.textColor = secondLineColor
        secondLineLabel.textAlignment = .center
        secondLineLabel.numberOfLines = 1
        secondLineLabel.lineBreakMode = .byTruncatingTail
        secondLineLabel.adjustsFontSizeToFitWidth = true
        secondLineLabel.minimumScaleFactor = 0.85
        secondLineLabel.allowsDefaultTighteningForTruncation = true
        secondLineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Indicator
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 9.5, weight: .semibold)
        chevronImageView.image = UIImage.symbol("arrowshape.turn.up.right", withConfiguration: chevronConfig)
        chevronImageView.tintColor = chevronColor
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronImageView.isHidden = !showsDropdownChevron

        // Second line horizontal stack
        secondLineStack.axis = .horizontal
        secondLineStack.alignment = .center
        secondLineStack.distribution = .fill
        secondLineStack.spacing = 3.5
        secondLineStack.addArrangedSubview(secondLineLabel)
        secondLineStack.addArrangedSubview(chevronImageView)

        // Content stack
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.distribution = .fill
        contentStack.spacing = 1
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(firstLineLabel)
        contentStack.addArrangedSubview(secondLineStack)

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])

        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func updateIsCompressed(_ size: CGSize? = nil) {
        if let containerHeight = navigationBar?.bounds.height ?? size?.height {
            let compressed = containerHeight < 34
            if compressed != isCompressed {
                isCompressed = compressed
            }
        }
    }

    private func updateStackLayout() {
        if isCompressed {
            contentStack.axis = .horizontal
            contentStack.spacing = 8
            firstLineLabel.font = firstLineFont
            secondLineLabel.font = firstLineFont
        } else {
            contentStack.axis = .vertical
            contentStack.spacing = 1
            firstLineLabel.font = firstLineFont
            secondLineLabel.font = secondLineFont
        }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}

private extension UIView {
    var navigationBar: UINavigationBar? {
        if let navigationBar = self as? UINavigationBar {
            return navigationBar
        } else {
            return superview?.navigationBar
        }
    }
}

