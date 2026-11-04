//
//  LaunchBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-01-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AppDependencies
import AppMigrationFeature
import AudioUpdater
import ReciterService
import SettingsService
import TranslationService
import UIKit

@MainActor
public struct LaunchBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func appViewController() -> UIViewController {
        AppBuilder(container: container).build()
    }

    public func reloadApp(in window: UIWindow) {
        DispatchQueue.main.async {
            let previousSelectedTab = (window.rootViewController as? UITabBarController)?.selectedIndex ?? 0

            let switchRoot = {
                let newAppVC = appViewController()
                if let tabBar = newAppVC as? UITabBarController {
                    tabBar.selectedIndex = min(previousSelectedTab, (tabBar.viewControllers?.count ?? 1) - 1)
                }
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    let oldState = UIView.areAnimationsEnabled
                    UIView.setAnimationsEnabled(false)
                    window.rootViewController = newAppVC
                    UIView.setAnimationsEnabled(oldState)
                }, completion: nil)
            }

            if let presented = window.rootViewController?.presentedViewController {
                presented.dismiss(animated: false, completion: switchRoot)
            } else {
                switchRoot()
            }
        }
    }

    public func launchStartup() -> LaunchStartup {
        let audioUpdater = AudioUpdater(baseURL: container.appHost)
        let fileSystemMigrator = FileSystemMigrator(
            databasesURL: container.databasesURL,
            recitersRetreiver: ReciterDataRetriever()
        )

        let translationsRepository = TranslationsRepository(databasesURL: container.databasesURL, baseURL: container.appHost)
        let localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: container.databasesURL)
        let translationsDownloader = TranslationsDownloader(downloader: container.downloadManager)
        let translationsUpdater = TranslationsUpdater(
            translationsRepository: translationsRepository,
            localTranslationsRetriever: localTranslationsRetriever,
            downloader: translationsDownloader
        )

        return LaunchStartup(
            appBuilder: AppBuilder(container: container),
            baseURL: container.appHost,
            audioUpdater: audioUpdater,
            translationsUpdater: translationsUpdater,
            fileSystemMigrator: fileSystemMigrator,
            recitersPathMigrator: RecitersPathMigrator(),
            reviewService: ReviewService(analytics: container.analytics)
        )
    }

    public func handleIncomingUrl(urlContext: UIOpenURLContext) {
        let url = urlContext.url

        if url.scheme == "quran" || url.scheme == "quran-ios" {
            let path: String = if #available(iOS 16.0, *) {
                url.path(percentEncoded: true)
            } else {
                url.path
            }
            _ = navigateTo(path: path)
        }
    }

    // MARK: Internal

    let container: AppDependencies

    // MARK: Public

    private func navigateTo(path: String) -> Bool {
        // TODO: Implement the actual navigation
        return true
    }
}
