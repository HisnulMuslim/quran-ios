//
//  DefaultTranslationInstaller.swift
//
//  Automatically downloads and selects the default Kannada translation
//  on first app install. Runs once; subsequent launches are skipped.
//

import BatchDownloader
import Foundation
import NetworkSupport
import QuranText
import TranslationPersistence
import VLogging

/// Installs the default Kannada translation on first launch.
///
/// Call `installIfNeeded(databasesURL:baseURL:downloadManager:)` once at app
/// start (after the `DownloadManager` has been started). It is a no-op on
/// every subsequent launch.
public struct DefaultTranslationInstaller {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    /// Downloads and selects the Kannada translation on first launch.
    ///
    /// - Parameters:
    ///   - databasesURL: The local databases folder (same one used by the rest of the app).
    ///   - baseURL: The host URL for the translation API and file downloads.
    ///   - downloadManager: The shared `DownloadManager` (must already be started).
    public func installIfNeeded(
        databasesURL: URL,
        baseURL: URL,
        downloadManager: DownloadManager
    ) async {
        // Only run once per device install.
        guard !Self.hasInstalledDefaultTranslation else {
            logger.info("DefaultTranslationInstaller: already installed, skipping")
            return
        }

        logger.info("DefaultTranslationInstaller: first launch — downloading Kannada translation")

        do {
            let networkManager = NetworkManager(baseURL: baseURL)
            let networkTranslationManager = TranslationNetworkManager(
                networkManager: networkManager,
                parser: JSONTranslationsParser()
            )

            // Fetch translation list from the server.
            let remoteTranslations = try await networkTranslationManager.getTranslations()

            // Find the Kannada translation (languageCode == "kn").
            guard let kannadaTranslation = remoteTranslations.first(where: { $0.languageCode == "kn" }) else {
                logger.warning("DefaultTranslationInstaller: no Kannada translation found in remote list")
                return
            }

            // Persist to the local active-translations database.
            let persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
            let existing = try await persistence.retrieveAll()
            for old in existing where old.id == kannadaTranslation.id {
                try await persistence.remove(old)
            }
            try await persistence.insert(kannadaTranslation)

            // Kick off the download and wait for it to complete.
            let downloader = TranslationsDownloader(downloader: downloadManager)
            let response = try await downloader.download(kannadaTranslation)

            // Wait for the download to finish (mirrors DownloadManager.waitForCompletion).
            do {
                for try await _ in response.progress { }
            } catch {
                logger.error("DefaultTranslationInstaller: download failed — \(error)")
                // Do NOT set the flag so we retry on next launch.
                return
            }

            // Select it so the translation view is active by default.
            SelectedTranslationsPreferences.shared.select(kannadaTranslation.id)

            // Mark as done so we never repeat this.
            Self.hasInstalledDefaultTranslation = true
            logger.info("DefaultTranslationInstaller: Kannada translation installed (id=\(kannadaTranslation.id))")
        } catch {
            logger.error("DefaultTranslationInstaller: failed — \(error)")
            // Do NOT set the flag: we'll retry on next launch.
        }
    }

    // MARK: Private

    private static let installedKey = "defaultKannadaTranslationInstalled"

    private static var hasInstalledDefaultTranslation: Bool {
        get { UserDefaults.standard.bool(forKey: installedKey) }
        set { UserDefaults.standard.set(newValue, forKey: installedKey) }
    }
}
