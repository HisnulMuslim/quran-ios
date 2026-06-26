//
//  TranslationsUpdater.swift
//  Quran
//
//  Created by Antigravity on 2026-06-25.
//

import Foundation
import UserNotifications
import VLogging
import Crashing
import Localization
import QuranText

public protocol TranslationUpdateNotifier: Sendable {
    func requestAuthorization() async -> Bool
    func sendUpdateNotification(for translation: Translation) async
}

public final class DefaultTranslationUpdateNotifier: TranslationUpdateNotifier {
    public init() {}

    public func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            return false
        }
    }

    public func sendUpdateNotification(for translation: Translation) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = l("translation.update.notification.title")
        content.body = lFormat("translation.update.notification.body", translation.displayName)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "translation_update_\(translation.id)",
            content: content,
            trigger: nil // deliver immediately
        )
        try? await center.add(request)
    }
}

public final class TranslationsUpdater {
    // MARK: Lifecycle

    public init(
        translationsRepository: TranslationsRepository,
        localTranslationsRetriever: LocalTranslationsRetriever,
        downloader: TranslationsDownloader,
        notifier: TranslationUpdateNotifier = DefaultTranslationUpdateNotifier()
    ) {
        self.translationsRepository = translationsRepository
        self.localTranslationsRetriever = localTranslationsRetriever
        self.downloader = downloader
        self.notifier = notifier
    }

    // MARK: Public

    public func updateTranslationsIfNeeded(bypassThrottle: Bool = false) async {
        logger.info("TranslationsUpdater: Checking for translation updates...")
        
        if !bypassThrottle {
            if let lastChecked = preferences.lastChecked {
                let timePassed = Date().timeIntervalSince(lastChecked)
                if timePassed < TranslationUpdatePreferences.updateCheckInterval {
                    logger.info("TranslationsUpdater: Checked recently. Skipping automatic check.")
                    return
                }
            }
        }

        do {
            // 1. Sync remote translations
            try await translationsRepository.downloadAndSyncTranslations()
            
            // Update last checked time on a successful check
            preferences.lastChecked = Date()

            // 2. Load local translations
            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()

            // 3. Find active translations that need an upgrade
            for translation in localTranslations {
                if translation.isDownloaded {
                    logger.info("TranslationsUpdater: Comparing '\(translation.displayName)' (ID: \(translation.id)) - installedVersion (local): \(translation.installedVersion.map { String($0) } ?? "nil"), version (remote): \(translation.version) -> needsUpgrade: \(translation.needsUpgrade)")
                }
            }

            let translationsToUpgrade = localTranslations.filter { $0.isDownloaded && $0.needsUpgrade }
            logger.info("TranslationsUpdater: Found \(translationsToUpgrade.count) translations that need upgrade.")

            guard !translationsToUpgrade.isEmpty else {
                return
            }

            // 4. Request notification permission if needed
            _ = await notifier.requestAuthorization()

            // 5. Download and update each translation
            for translation in translationsToUpgrade {
                logger.info("TranslationsUpdater: Starting auto-upgrade for \(translation.displayName) (version: \(translation.version))")
                let response = try await downloader.download(translation)

                do {
                    for try await _ in response.progress {
                        // Wait for the download to complete
                    }
                    
                    // Unzip and update version
                    let updated = try await localTranslationsRetriever.getLocalTranslations()
                    if let newVersion = updated.first(where: { $0.id == translation.id }), !newVersion.needsUpgrade {
                        logger.info("TranslationsUpdater: Successfully updated translation \(translation.displayName)")
                        await notifier.sendUpdateNotification(for: newVersion)
                    }
                } catch {
                    logger.error("TranslationsUpdater: Failed to download update for \(translation.displayName). Error: \(error)")
                }
            }
        } catch {
            logger.error("TranslationsUpdater: Failed to check or sync translations. Error: \(error)")
            crasher.recordError(error, reason: "Translations check/sync failed.")
        }
    }

    // MARK: Private

    private let translationsRepository: TranslationsRepository
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let downloader: TranslationsDownloader
    private let notifier: TranslationUpdateNotifier
    private let preferences = TranslationUpdatePreferences.shared
}
