//
//  AppViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

import Analytics
import Localization
import SwiftUI
import UIKit
import WhatsNewFeature

protocol AppPresenter: UITabBarController {
}

class AppViewController: UITabBarController, UITabBarControllerDelegate, AppPresenter {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, interactor: AppInteractor) {
        self.interactor = interactor
        whatsNewController = AppWhatsNewController(analytics: analytics)
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        interactor.start()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Open

    override open var shouldAutorotate: Bool {
        visibleViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        visibleViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let targetMask = tabBarController.supportedInterfaceOrientations
        if let currentMask = tabBarController.view.window?.windowScene?.interfaceOrientation.asMask {
            if !targetMask.contains(currentMask) {
                if let interface = targetMask.asOrientation {
                    UIDevice.current.setValue(interface.rawValue, forKey: "orientation")
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentInitialLanguagePromptIfNeeded()
    }

    // MARK: Private

    private let interactor: AppInteractor
    private let whatsNewController: AppWhatsNewController

    private func presentInitialLanguagePromptIfNeeded() {
        let key = "hasSelectedInitialLanguage"
        guard !UserDefaults.standard.bool(forKey: key) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            guard !UserDefaults.standard.bool(forKey: key) else { return }
            guard self.presentedViewController == nil else { return }

            let initialView = InitialLanguageView { [weak self] chosenLanguage in
                UserDefaults.standard.set(true, forKey: key)
                let previousLanguage = AppLanguage
                self?.dismiss(animated: true) {
                    if previousLanguage != chosenLanguage {
                        AppLanguage = chosenLanguage
                    }
                }
            }

            let hostingController = UIHostingController(rootView: initialView)
            hostingController.modalPresentationStyle = .pageSheet
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            self.present(hostingController, animated: true)
        }
    }

    private var visibleViewController: UIViewController? {
        presentedViewController ?? selectedViewController
    }
}

private extension UIInterfaceOrientation {
    var asMask: UIInterfaceOrientationMask? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

private extension UIInterfaceOrientationMask {
    var asOrientation: UIInterfaceOrientation? {
        if contains(.portrait) {
            return .portrait
        } else if contains(.landscapeLeft) {
            return .landscapeLeft
        } else if contains(.landscapeRight) {
            return .landscapeRight
        } else if contains(.portraitUpsideDown) {
            return .portraitUpsideDown
        } else {
            return nil
        }
    }
}
