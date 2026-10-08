//
//  QuranView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
import NoorUI
import UIKit
import UIx
import ViewConstrainer

@MainActor
protocol QuranViewDelegate: AnyObject {
    func onQuranViewTapped(_ quranView: QuranView)
}

class QuranView: UIView, UIGestureRecognizerDelegate, UINavigationBarDelegate {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    init() {
        super.init(frame: .zero)
        setUp()
    }

    // MARK: Internal

    weak var delegate: QuranViewDelegate?

    var contentView: UIView?

    let topBarBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let navigationBar = UINavigationBar()
    let navigationItem = UINavigationItem()

    override func layoutSubviews() {
        navigationItem.titleView?.setNeedsLayout()
        super.layoutSubviews()
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }

    func addWordPointerView(_ wordPointerView: UIView) {
        addAutoLayoutSubview(wordPointerView)
        wordPointerView.vc.edges()
    }

    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        addAutoLayoutSubview(contentView)
        contentView.vc
            .verticalEdges()
            .horizontalEdges()
        sendSubviewToBack(contentView)
    }

    func showStatusView(_ statusView: UIView) {
        self.statusView?.removeFromSuperview()
        self.statusView = statusView
        addAutoLayoutSubview(statusView)
        statusView.vc
            .verticalEdges()
            .horizontalEdges()
        bringSubviewToFront(statusView)
        bringSubviewToFront(topBarBlurView)
        bringSubviewToFront(navigationBar)
        if let audioView {
            bringSubviewToFront(audioView)
        }
    }

    func hideStatusView() {
        statusView?.removeFromSuperview()
        statusView = nil
    }

    func addAudioBannerView(_ audioBannerView: UIView) {
        audioView = audioBannerView
        addAutoLayoutSubview(audioBannerView)
        audioBannerView.vc
            .horizontalEdges()
            .bottom()
    }

    func setBarsHidden(_ hidden: Bool) {
        audioView?.alpha = hidden ? 0 : 1
        audioView?.isUserInteractionEnabled = !hidden
        topBarBlurView.alpha = hidden ? 0 : 1
    }

    @objc
    func onViewTapped(_ sender: UITapGestureRecognizer) {
        if let audioView, audioView.bounds.contains(sender.location(in: audioView)), audioView.isUserInteractionEnabled {
            return
        }
        delegate?.onQuranViewTapped(self)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tapGesture {
            if touch.view?.isDescendant(of: navigationBar) == true {
                return false
            }
            if let audioView, touch.view?.isDescendant(of: audioView) == true {
                return false
            }
        }
        return true
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer != tapGesture || !isFirstResponder // dismiss bars only if not first responder
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == tapGesture && otherGestureRecognizer is UILongPressGestureRecognizer) ||
            (otherGestureRecognizer == tapGesture && gestureRecognizer is UILongPressGestureRecognizer) {
            return false
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture {
            if let tap = otherGestureRecognizer as? UITapGestureRecognizer, tap.numberOfTapsRequired == 2 {
                return true
            }
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                return true
            }
        }
        return false
    }

    // MARK: - Theme

    func applyTheme(_ theme: ThemeStyle) {
        topBarBlurView.contentView.backgroundColor = theme.backgroundColor.withAlphaComponent(0.2)
        separator.backgroundColor = theme.pageSeparatorLine
        if let titleView = navigationItem.titleView as? TwoLineNavigationTitleView {
            titleView.firstLineColor = theme.textColor
            titleView.secondLineColor = theme.secondaryTextColor
            titleView.chevronColor = theme.textColor
        }
        navigationBar.tintColor = theme.textColor
    }

    // MARK: Private

    private let tapGesture = UITapGestureRecognizer()
    private let separator = UIView()
    private var audioView: UIView?
    private var statusView: UIView?

    private func setUp() {
        clipsToBounds = true
        tapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        // navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // blur background for status bar & navigation bar
        let initialTheme = ThemeService.shared.themeStyle
        topBarBlurView.effect = UIBlurEffect(style: .systemMaterial)
        topBarBlurView.isUserInteractionEnabled = false
        topBarBlurView.contentView.backgroundColor = initialTheme.backgroundColor.withAlphaComponent(0.2)

        addAutoLayoutSubview(topBarBlurView)
        addAutoLayoutSubview(navigationBar)

        topBarBlurView.vc.horizontalEdges()
        navigationBar.vc.horizontalEdges()

        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            topBarBlurView.topAnchor.constraint(equalTo: topAnchor),
            topBarBlurView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
        ])

        // subtle hairline separator at bottom of navigation bar
        separator.backgroundColor = initialTheme.pageSeparatorLine
        topBarBlurView.contentView.addAutoLayoutSubview(separator)
        separator.vc
            .horizontalEdges()
            .bottom()
            .height(by: 1.0 / UIScreen.main.scale)

        navigationBar.pushItem(navigationItem, animated: false)
        navigationBar.delegate = self
        navigationBar.tintColor = initialTheme.textColor
    }
}
