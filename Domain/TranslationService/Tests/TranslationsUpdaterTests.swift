//
//  TranslationsUpdaterTests.swift
//  Quran
//
//  Created by Antigravity on 2026-06-25.
//

import BatchDownloaderFake
import NetworkSupportFake
import QuranText
import SystemDependenciesFake
import TranslationPersistence
import TranslationServiceFake
import Utilities
import VerseTextPersistence
import XCTest
@testable import BatchDownloader
@testable import NetworkSupport
@testable import TranslationService

class TranslationsUpdaterTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        preferences.reset()

        let uuid = UUID().uuidString
        uniqueDatabasesURL = FileManager.documentsURL
            .appendingPathComponent("databases-\(uuid)", isDirectory: true)

        session = NetworkSessionFake(queue: .main, delegate: nil)
        fileSystem = FileSystemFake()
        persistence = GRDBActiveTranslationsPersistence(directory: uniqueDatabasesURL)

        testContext = BatchDownloaderFake.makeContext()

        let expectation = expectation(description: "Downloader Setup")
        Task {
            (batchDownloader, downloaderSession) = await testContext.makeDownloader(fileManager: fileSystem)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        downloader = TranslationsDownloader(downloader: batchDownloader)

        repository = TranslationsRepository(
            databasesURL: uniqueDatabasesURL,
            networkManager: NetworkManager(session: session, baseURL: baseURL)
        )

        let persistenceFactory = { [fileSystem] (translation: Translation) in
            GRDBDatabaseVersionPersistence(fileURL: translation.localPath.url)
        }
        unzipper = FakeTranslationUnzipper(didUnzip: false)
        retriever = LocalTranslationsRetriever(
            databasesURL: uniqueDatabasesURL,
            fileSystem: fileSystem,
            unzipper: unzipper,
            versionPersistenceFactory: persistenceFactory
        )

        notifier = FakeTranslationUpdateNotifier()

        updater = TranslationsUpdater(
            translationsRepository: repository,
            localTranslationsRetriever: retriever,
            downloader: downloader,
            notifier: notifier
        )
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: uniqueDatabasesURL)
        testContext.tearDown()
        preferences.reset()

        updater = nil
        repository = nil
        downloader = nil
        batchDownloader = nil
        session = nil
        downloaderSession = nil
        testContext = nil
        notifier = nil
        persistence = nil
        retriever = nil
        fileSystem = nil
    }

    func test_throttling_skipsCheckingIfCheckedWithinInterval() async throws {
        // Set lastChecked to half of the check interval ago
        preferences.lastChecked = Date().addingTimeInterval(-TranslationUpdatePreferences.updateCheckInterval / 2)

        await updater.updateTranslationsIfNeeded()

        // Verify no network requests were made
        XCTAssertTrue(session.dataResults.isEmpty)
    }

    func test_throttling_runsCheckingIfNeverCheckedBefore() async throws {
        preferences.reset()

        try nextResponse(TranslationsResponse(data: []))

        await updater.updateTranslationsIfNeeded()

        // Verify a network request was made
        XCTAssertFalse(session.dataResults.isEmpty)
        XCTAssertNotNil(preferences.lastChecked)
    }

    func test_throttling_runsCheckingIfCheckedMoreThanIntervalAgo() async throws {
        // Set lastChecked to 30 seconds more than the check interval ago
        preferences.lastChecked = Date().addingTimeInterval(-TranslationUpdatePreferences.updateCheckInterval - 30)

        try nextResponse(TranslationsResponse(data: []))

        await updater.updateTranslationsIfNeeded()

        // Verify a network request was made
        XCTAssertFalse(session.dataResults.isEmpty)
        XCTAssertNotNil(preferences.lastChecked)
    }

    func test_updateNeeded_downloadsUnzipsAndNotifies() async throws {
        preferences.reset()

        // Insert a local downloaded translation with version 5
        let translation = TranslationTestData.khanTranslation
        try await insertTranslation(translation, installedVersion: 5, downloaded: true)

        // API response has version 17
        let newRemoteTranslation = Translation(
            id: translation.id,
            displayName: translation.displayName,
            translator: translation.translator,
            translatorForeign: translation.translatorForeign,
            fileURL: translation.fileURL,
            fileName: translation.fileName,
            languageCode: translation.languageCode,
            version: 17,
            installedVersion: nil
        )
        let remoteResponse = TranslationsResponse(data: [TranslationResponse(newRemoteTranslation)])
        try nextResponse(remoteResponse)

        // Run the updater in a background task so we can simulate download completion asynchronously
        let updateTask = Task {
            await updater.updateTranslationsIfNeeded()
        }

        // Wait briefly for the task to start and trigger the download
        try await Task.sleep(nanoseconds: 50_000_000)

        // Verify download was triggered
        let running = await downloader.runningTranslationDownloads()
        XCTAssertEqual(running.count, 1)

        // Verify notification is not sent yet
        XCTAssertNil(notifier.lastNotifiedTranslation)

        // Set didUnzip to true so when the download completes, the unzipper returns true
        unzipper.didUnzip = true

        // Complete the download task
        let downloadRequest = running[0].requests[0]
        let tempURL = downloadRequest.destination.url
            .deletingLastPathComponent()
            .appendingPathComponent("temp_download.db")
        fileSystem.files.insert(tempURL)

        if let task = downloaderSession.downloads.first(where: { $0.originalRequest?.url == downloadRequest.request.url }) {
            await downloaderSession.completeDownloadTask(task, location: tempURL, totalBytes: 100, progressLoops: 1)
        }

        // Wait for the update task to complete
        await updateTask.value

        // Verify local version is updated in DB
        let localResults = try await retriever.getLocalTranslations()
        XCTAssertEqual(localResults.first { $0.id == translation.id }?.installedVersion, 17)

        // Verify notification was sent
        XCTAssertEqual(notifier.lastNotifiedTranslation?.id, translation.id)
    }

    // MARK: Private

    private var updater: TranslationsUpdater!
    private var repository: TranslationsRepository!
    private var downloader: TranslationsDownloader!
    private var notifier: FakeTranslationUpdateNotifier!
    private var retriever: LocalTranslationsRetriever!
    private var unzipper: FakeTranslationUnzipper!
    private var persistence: ActiveTranslationsPersistence!
    private var fileSystem: FileSystemFake!

    private var batchDownloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var downloaderSession: NetworkSessionFake!
    private var testContext: BatchDownloaderTestContext!
    private var uniqueDatabasesURL: URL!

    private let preferences = TranslationUpdatePreferences.shared
    private let selectedPreferences = SelectedTranslationsPreferences.shared
    private let baseURL = URL(validURL: "http://example.com")

    private func nextResponse(_ response: TranslationsResponse) throws {
        let encoder = JSONEncoder()
        let parameters: [(String, String)] = []
        let request = NetworkManager.request(
            baseURL: baseURL,
            path: TranslationNetworkManager.path,
            parameters: parameters
        )
        session.dataResults[request.url!] = .success(try encoder.encode(response))
    }

    private func insertTranslation(
        _ translation: Translation,
        installedVersion: Int?,
        downloaded: Bool
    ) async throws {
        var translation = translation
        translation.installedVersion = installedVersion
        try await persistence.insert(translation)

        if installedVersion != nil {
            selectedPreferences.toggleSelection(translation.id)
        }

        if downloaded {
            fileSystem.files.insert(translation.localPath.url)
        }
    }
}

// MARK: - Mocks

private final class FakeTranslationUpdateNotifier: TranslationUpdateNotifier, @unchecked Sendable {
    var authorizationGranted = true
    var lastNotifiedTranslation: Translation?

    func requestAuthorization() async -> Bool {
        authorizationGranted
    }

    func sendUpdateNotification(for translation: Translation) async {
        lastNotifiedTranslation = translation
    }
}

private final class FakeTranslationUnzipper: TranslationUnzipper, @unchecked Sendable {
    var didUnzip: Bool
    init(didUnzip: Bool) {
        self.didUnzip = didUnzip
    }

    func unzipIfNeeded(_ translation: Translation) throws -> Bool {
        didUnzip
    }
}

private extension TranslationResponse {
    init(_ translation: Translation) {
        self.init(
            id: translation.id,
            displayName: translation.displayName,
            translator: translation.translator,
            translatorForeign: translation.translatorForeign,
            fileUrl: translation.fileURL,
            fileName: translation.fileName,
            languageCode: translation.languageCode,
            currentVersion: translation.version
        )
    }
}
