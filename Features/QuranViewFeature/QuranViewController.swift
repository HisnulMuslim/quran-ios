//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
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
//

import Combine
import Localization
import NoorUI
import QuranKit
import QuranTextKit
import SwiftUI
import Timing
import TranslationService
import UIKit
import UIx
import VLogging

class QuranViewController: BaseViewController, QuranViewDelegate,
    QuranPresentable, PopoverPresenterDelegate, ForcedNavigationBarVisibilityController
{
    // MARK: Lifecycle

    init(interactor: QuranInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        interactor.start()
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let interactor: QuranInteractor

    var pagesView: UIView { quranView!.contentView! }

    // MARK: - View hierarchy

    var navigationBarHidden: Bool { true }

    override var prefersHomeIndicatorAutoHidden: Bool {
        prefersStatusBarHidden
    }

    override var prefersStatusBarHidden: Bool {
        // hide if it is compact size or status bar is shown
        statusBarHidden || traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        ThemeService.shared.themeStyle.statusBarStyle
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override func loadView() {
        view = QuranView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        quranView?.navigationItem.largeTitleDisplayMode = .never
        quranView?.delegate = self

        // set the custom title view
        let titleView = TwoLineNavigationTitleView(
            firstLineFont: .boldSystemFont(ofSize: 15),
            secondLineFont: .systemFont(ofSize: 12, weight: .regular)
        )
        titleView.showsDropdownChevron = true
        titleView.isUserInteractionEnabled = true
        let titleTap = UITapGestureRecognizer(target: self, action: #selector(onTitleViewTapped))
        titleView.addGestureRecognizer(titleTap)
        quranView?.navigationItem.titleView = titleView

        if !lastVisiblePages.isEmpty {
            updateTitle(lastVisiblePages)
        } else if !interactor.visiblePages.isEmpty {
            updateTitle(interactor.visiblePages)
        }

        let backImage: UIImage?
        backImage = UIImage(systemName: "chevron.backward")

        let backButton = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        quranView?.navigationItem.leftBarButtonItem = backButton

        setupContentStatus()
        setupTranslationQuickSwitch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateTranslationQuickSwitchMenu()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Theme
    private func setupTheme() {
        let initialTheme = ThemeService.shared.themeStyle
        view.backgroundColor = initialTheme.backgroundColor
        quranView?.applyTheme(initialTheme)

        ThemeService.shared.themeStylePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.view.backgroundColor = theme.backgroundColor
                self?.quranView?.applyTheme(theme)
                self?.setNeedsStatusBarAppearanceUpdate()
            }
            .store(in: &cancellables)
    }

    // MARK: - Content Status

    func setupContentStatus() {
        interactor.$contentStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateContentStatus($0) }
            .store(in: &cancellables)
    }

    func hideBars() {
        setBarsHidden(true)
    }

    func startHiddenBarsTimer() {
        // increate the timer duration to give existing users the time to see the new buttons
        barsTimer = Timer(interval: 5) { [weak self] in
            if self?.presentedViewController == nil {
                self?.setBarsHidden(true)
            }
        }
    }

    // MARK: - Quran View Delegate

    func onQuranViewTapped(_ quranView: QuranView) {
        if let presented = presentedViewController {
            if presented.isBeingPresented || presented is TranslationsSelectionNavigationController {
                return
            }
            presented.dismiss(animated: true)
            return
        }
        if interactor.contentStatus == nil && quranView.contentView != nil {
            setBarsHidden(!statusBarHidden)
        }
    }

    // MARK: - View Controllable

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint, completion: @escaping () -> Void) {
        let activityViewController = UIActivityViewController(activityItems: lines, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            completion()
        }
        if let sharePresentationController = activityViewController.popoverPresentationController {
            sharePresentationController.sourceView = sourceView
            sharePresentationController.sourceRect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        }
        present(activityViewController, animated: true, completion: nil)
    }

    func presentWordPointer(_ viewController: UIViewController) {
        addChild(viewController)
        quranView?.addWordPointerView(viewController.view)
        viewController.didMove(toParent: self)
    }

    func dismissWordPointer(_ viewController: UIViewController) {
        removeChild(viewController)
    }

    func presentMoreMenu(_ viewController: UIViewController) {
        currentPresentedMoreMenu = viewController
        presentPopover(viewController, pointingTo: moreNavigationButton)
    }

    func presentThemeSettings(_ viewController: UIViewController) {
        currentPresentedAppearanceController = viewController
        if traitCollection.userInterfaceIdiom == .pad {
            presentPopover(viewController, pointingTo: appearanceNavigationButton)
        } else {
            present(viewController, animated: true)
        }
    }

    func presentTranslationsSelection(_ viewController: UIViewController) {
        let translationsNavigationController = TranslationsSelectionNavigationController(rootViewController: viewController)
        translationsNavigationController.presentationController?.delegate = self
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "x.circle"),
            style: .done,
            target: self,
            action: #selector(onTranslationsSelectionDoneTapped)
        )
        present(translationsNavigationController, animated: true, completion: nil)
    }

    func presentJumpDialog(_ viewController: UIViewController) {
        currentPresentedJumpController = viewController
        present(viewController, animated: true)
    }

    func presentAudioBanner(_ audioBanner: UIViewController) {
        addChild(audioBanner)
        quranView?.addAudioBannerView(audioBanner.view)
        audioBanner.didMove(toParent: self)
        setAudioBarHidden(false)
    }

    func presentAyahMenu(_ viewController: UIViewController, in sourceView: UIView, at point: CGPoint) {
        popoverPresenter.present(
            presenting: self,
            presented: viewController,
            pointingTo: sourceView,
            at: CGRect(x: point.x, y: point.y, width: 1, height: 1),
            permittedArrowDirections: []
        )
    }

    func presentQuranContent(_ viewController: UIViewController) {
        addContent(viewController)
    }

    func presentTranslatedVerse(_ viewController: UIViewController, didDismiss: @escaping () -> Void) {
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        if let navigationController = viewController as? UINavigationController {
            navigationController.visibleViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissTranslatedVerse)
            )
        }
        presentationsMonitor.monitor(viewController, actions: .init(didDismiss: { _ in
            didDismiss()
        }))
        present(viewController, animated: true)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let presentedViewController {
            presentationsMonitor.dismiss(presentedViewController)
        }
        super.dismiss(animated: flag, completion: completion)
    }

    func dismissPresentedViewController(completion: (() -> Void)?) {
        if presentedViewController != nil {
            dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
    }

    func didDismissPopover() {
        interactor.didDismissPopover()
    }

    private var lastVisiblePages: [Page] = []

    func setVisiblePages(_ pages: [Page]) {
        lastVisiblePages = pages
        title = pages.map { $0.startSura.localizedName(withPrefix: true) }.joined(separator: " | ")
        updateTitle(pages)
    }

    func updateBookmark(_ isBookmarked: Bool) {
        updateRightBarItems(animated: false, isBookmarked: isBookmarked)
    }

    // MARK: Private

    private class TranslationsSelectionNavigationController: BaseNavigationController {}

    private var contentStatusView: UIHostingController<ContentStatusView>?

    private var cancellables: Set<AnyCancellable> = []
    private lazy var popoverPresenter = PhonePopoverPresenter(delegate: self)
    private let presentationsMonitor = PresentationsMonitor()

    // MARK: - Navigation bars

    private var barsTimer: Timing.Timer?

    // MARK: - Navigation Bar

    private weak var currentPresentedAppearanceController: UIViewController?
    private weak var currentPresentedMoreMenu: UIViewController?
    private weak var currentPresentedJumpController: UIViewController?
    private var lastTitleTapTime: TimeInterval = 0

    private lazy var moreNavigationButton: UIBarButtonItem = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let moreImage = UIImage.symbol("ellipsis.circle", withConfiguration: config)
        return UIBarButtonItem(image: moreImage, style: .plain, target: self, action: #selector(onMoreBarButtonTapped(_:)))
    }()

    private lazy var appearanceNavigationButton: UIBarButtonItem = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let appearanceImage = UIImage.symbol("textformat.size", withConfiguration: config)
        let button = UIBarButtonItem(image: appearanceImage, style: .plain, target: self, action: #selector(onAppearanceBarButtonTapped(_:)))
        button.accessibilityLabel = l("menu.theme_settings")
        return button
    }()

    private lazy var translationQuickSwitchButton: UIBarButtonItem = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let globeImage = UIImage.symbol("globe", withConfiguration: config)
        let button = UIBarButtonItem(image: globeImage, style: .plain, target: nil, action: nil)
        button.accessibilityLabel = l("menu.translation")
        return button
    }()

    private var isBookmarked: Bool = false

    private func setupTranslationQuickSwitch() {
        updateTranslationQuickSwitchMenu()

        SelectedTranslationsPreferences.shared.$selectedTranslationIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTranslationQuickSwitchMenu()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .localTranslationsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTranslationQuickSwitchMenu()
            }
            .store(in: &cancellables)

        QuranContentStatePreferences.shared.$quranMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateRightBarItems(animated: true, isBookmarked: self.isBookmarked)
            }
            .store(in: &cancellables)
    }

    private func updateTranslationQuickSwitchMenu() {
        Task { [weak self] in
            guard let self else { return }
            let downloaded = (try? await self.interactor.localTranslationsRetriever.getLocalTranslations())?.filter(\.isDownloaded) ?? []
            guard !downloaded.isEmpty else {
                self.translationQuickSwitchButton.menu = nil
                return
            }

            var selectedIds = SelectedTranslationsPreferences.shared.selectedTranslationIds
            if !downloaded.contains(where: { selectedIds.contains($0.id) }), let firstDownloaded = downloaded.first {
                SelectedTranslationsPreferences.shared.select(firstDownloaded.id)
                selectedIds = [firstDownloaded.id]
            }

            var children: [UIMenuElement] = []

            for trans in downloaded {
                let isSelected = selectedIds.contains(trans.id)
                let title = trans.displayName
                let action = UIAction(
                    title: title,
                    state: isSelected ? .on : .off
                ) { [weak self] _ in
                    SelectedTranslationsPreferences.shared.select(trans.id)
                    self?.updateTranslationQuickSwitchMenu()
                }
                children.append(action)
            }

            let manageAction = UIAction(
                title: l("menu.select_translation"),
                image: UIImage(systemName: "gearshape")
            ) { [weak self] _ in
                self?.interactor.onTranslationsSelectionsTapped()
            }
            let manageMenu = UIMenu(options: .displayInline, children: [manageAction])
            children.append(manageMenu)

            let menu = UIMenu(
                title: l("translation.selectedTranslations"),
                children: children
            )
            self.translationQuickSwitchButton.menu = menu
        }
    }

    private var titleView: TwoLineNavigationTitleView? { quranView?.navigationItem.titleView as? TwoLineNavigationTitleView }
    private var quranView: QuranView? {
        view as? QuranView
    }

    private var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private func stopBarHiddenTimer() {
        barsTimer?.cancel()
        barsTimer = nil
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func updateContentStatus(_ newStatus: ContentStatusView.State?) {
        if let newStatus {
            if let contentStatusView {
                contentStatusView.rootView = ContentStatusView(state: newStatus)
            } else {
                let contentStatusView = UIHostingController(rootView: ContentStatusView(state: newStatus))
                self.contentStatusView = contentStatusView
                addChild(contentStatusView)
                quranView?.showStatusView(contentStatusView.view)
                contentStatusView.didMove(toParent: self)
            }
        } else {
            if let contentStatusView {
                removeChild(contentStatusView)
                quranView?.hideStatusView()
                self.contentStatusView = nil
            }
        }
    }

    private func setBarsHidden(_ hidden: Bool) {
        // remove the timer
        stopBarHiddenTimer()

        // make it visible
        if quranView?.navigationBar.isHidden ?? true, !hidden {
            quranView?.navigationBar.isHidden = false
            quranView?.topBarBlurView.isHidden = false
        }

        // animate the change
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, animations: {
            self.statusBarHidden = hidden
            self.setAudioBarHidden(hidden)
            self.quranView?.navigationBar.alpha = hidden ? 0 : 1
            self.quranView?.topBarBlurView.alpha = hidden ? 0 : 1
        }, completion: { _ in
            self.quranView?.navigationBar.isHidden = hidden
            self.quranView?.topBarBlurView.isHidden = hidden
        })
    }

    private func setAudioBarHidden(_ hidden: Bool) {
        quranView?.setBarsHidden(hidden)
    }

    private func addContent(_ viewController: UIViewController) {
        addChild(viewController)
        quranView?.addContentView(viewController.view)
        viewController.didMove(toParent: self)
    }

    @objc
    private func dismissTranslatedVerse() {
        dismiss(animated: true)
    }

    @objc
    private func onTranslationsSelectionDoneTapped() {
        logger.info("Quran: translations selection dismissed")
        dismiss(animated: true) { [weak self] in
            self?.updateTranslationQuickSwitchMenu()
        }
    }

    @objc
    private func onTitleViewTapped() {
        logger.info("Quran: onTitleViewTapped")
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTitleTapTime > 0.4 else {
            return
        }
        lastTitleTapTime = now

        if let presented = presentedViewController {
            presented.dismiss(animated: true)
            if presented === currentPresentedJumpController {
                currentPresentedJumpController = nil
                return
            }
        }
        interactor.onJumpTapped()
    }

    private func updateTitle(_ pages: [Page]) {
        if pages.isEmpty {
            titleView?.firstLine = ""
            titleView?.secondLine = ""
            return
        }
        let suras = pages.map(\.startSura)
        let juzs = pages.map(\.startJuz)
        let pageNumbers = pages.map(\.pageNumber).map(NumberFormatter.shared.format).joined(separator: " - ")
        let pageDescription = lFormat(
            "page_description",
            table: .android,
            pageNumbers,
            NumberFormatter.shared.format(juzs.min()!.juzNumber)
        )
        titleView?.firstLine = suras.min()!.localizedName(withPrefix: true)
        titleView?.secondLine = pageDescription
    }

    private func updateRightBarItems(animated: Bool, isBookmarked: Bool) {
        self.isBookmarked = isBookmarked
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let bookmarkImage = UIImage.symbol(isBookmarked ? "bookmark.fill" : "bookmark", withConfiguration: config)
        let bookmark = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(onBookmarkButtonTapped))
        if isBookmarked {
            bookmark.tintColor = .systemRed
        }

        var items = [moreNavigationButton, appearanceNavigationButton]
        if QuranContentStatePreferences.shared.quranMode == .translation {
            items.append(translationQuickSwitchButton)
        }
        items.append(bookmark)

        quranView?.navigationItem.setRightBarButtonItems(items, animated: animated)
    }

    @objc
    private func onBookmarkButtonTapped() {
        Task {
            await interactor.toogleBookmark()
        }
    }

    @objc
    private func onMoreBarButtonTapped(_ barButton: UIBarButtonItem) {
        if let presented = presentedViewController {
            presented.dismiss(animated: true)
            if presented === currentPresentedMoreMenu {
                currentPresentedMoreMenu = nil
                return
            }
        }
        interactor.onMoreBarButtonTapped()
    }

    @objc
    private func onAppearanceBarButtonTapped(_ barButton: UIBarButtonItem) {
        if let presented = presentedViewController {
            presented.dismiss(animated: true)
            if presented === currentPresentedAppearanceController {
                currentPresentedAppearanceController = nil
                return
            }
        }
        interactor.onAppearanceBarButtonTapped()
    }
}

extension QuranViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        updateTranslationQuickSwitchMenu()
    }
}
