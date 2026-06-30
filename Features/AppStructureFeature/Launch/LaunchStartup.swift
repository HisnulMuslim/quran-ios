//
//  LaunchStartup.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppMigrationFeature
import AppMigrator
import AudioUpdater
import SettingsService
import UIKit
import VLogging
import TranslationService

@MainActor
public final class LaunchStartup {
    // MARK: Lifecycle

    init(
        appBuilder: AppBuilder,
        audioUpdater: AudioUpdater,
        translationsUpdater: TranslationsUpdater,
        fileSystemMigrator: FileSystemMigrator,
        recitersPathMigrator: RecitersPathMigrator,
        reviewService: ReviewService
    ) {
        self.appBuilder = appBuilder
        self.audioUpdater = audioUpdater
        self.translationsUpdater = translationsUpdater
        self.fileSystemMigrator = fileSystemMigrator
        self.recitersPathMigrator = recitersPathMigrator
        self.reviewService = reviewService
    }

    // MARK: Public

    public func launch(from window: UIWindow) {
        upgradeIfNeeded(window: window)
    }

    // MARK: Private

    private let fileSystemMigrator: FileSystemMigrator
    private let recitersPathMigrator: RecitersPathMigrator
    private let appBuilder: AppBuilder
    private let audioUpdater: AudioUpdater
    private let translationsUpdater: TranslationsUpdater
    private let reviewService: ReviewService

    private let appMigrator = AppMigrator()
    private var appViewController: UIViewController?

    private func upgradeIfNeeded(window: UIWindow) {
        registerMigrators()

        // Show the SplashViewController for the branding delay
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()

        Task {
            let delayTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0 seconds branding delay (matching Android)
            }

            switch appMigrator.migrationStatus() {
            case .noMigration:
                _ = await delayTask.result
                showApp(window: window)
            case let .migrate(blocksUI, titles):
                if blocksUI {
                    _ = await delayTask.result
                    logger.notice("Performing long upgrade task: \(titles)")
                    let migrationVC = MigrationViewController()
                    migrationVC.setTitles(titles)
                    window.rootViewController = migrationVC

                    await appMigrator.migrate()
                    showApp(window: window)
                } else {
                    await appMigrator.migrate()
                    _ = await delayTask.result
                    showApp(window: window)
                }
            }
        }
    }

    private func showApp(window: UIWindow) {
        if self.appViewController != nil {
            return
        }

        updateAudioIfNeeded()
        updateTranslationsIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        let wasUpdated = window.rootViewController != nil

        let appViewController = appBuilder.build()
        self.appViewController = appViewController

        if wasUpdated {
            appViewController.transition(to: window, duration: 0.3, options: .transitionCrossDissolve)
        } else {
            appViewController.launch(from: window)
        }
        reviewService.checkForReview(in: window)
    }

    @objc private func applicationWillEnterForeground() {
        updateAudioIfNeeded()
        updateTranslationsIfNeeded()
    }

    private func registerMigrators() {
        appMigrator.register(migrator: fileSystemMigrator, for: "1.16.0")
        appMigrator.register(migrator: recitersPathMigrator, for: "1.19.1")
    }

    private func updateAudioIfNeeded() {
        // don't run audio updater after upgrading the app
        if case .sameVersion = appMigrator.launchVersion {
            Task {
                await audioUpdater.updateAudioIfNeeded()
            }
        }
    }

    private func updateTranslationsIfNeeded() {
        // don't run translations updater after upgrading the app
        if case .sameVersion = appMigrator.launchVersion {
            Task {
                await translationsUpdater.updateTranslationsIfNeeded()
            }
        }
    }
}

private extension UIViewController {
    func launch(from window: UIWindow) {
        window.rootViewController = self
        window.makeKeyAndVisible()
    }

    func transition(to window: UIWindow, duration: TimeInterval, options: UIView.AnimationOptions) {
        window.switchRootViewController(to: self, duration: duration, options: options)
    }
}
