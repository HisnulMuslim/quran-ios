//
//  Container.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Analytics
import AppDependencies
import AuthenticationClient
import BatchDownloader
import CoreDataModel
import CoreDataPersistence
import Foundation
import LastPagePersistence
import NotePersistence
import PageBookmarkPersistence
import QuranKit
import ReadingService
import UIKit

/// Hosts singleton dependencies
class Container: AppDependencies {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = Container()

    private(set) lazy var remoteResources: ReadingRemoteResources? = AppReadingRemoteResources(appHost: Constant.appHost)
    private(set) lazy var readingResources = ReadingResourcesService(downloader: downloadManager, remoteResources: remoteResources)

    let analytics: AnalyticsLibrary = LoggingAnalyticsLibrary()

    private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: coreDataStack)
    private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)
    private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)
    private(set) lazy var authenticationClient: (any AuthenticationClient)? = {
        guard let configurations = Constant.QuranOAuthAppConfigurations else {
            return nil
        }
        let client = AuthenticationClientImpl(configurations: configurations)
        return client
    }()

    private(set) lazy var downloadManager: DownloadManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "DownloadsBackgroundIdentifier")
        configuration.timeoutIntervalForRequest = 60 * 5 // 5 minutes
        return DownloadManager(
            maxSimultaneousDownloads: 600,
            configuration: configuration,
            downloadsURL: Constant.databasesURL.appendingPathComponent("downloads.db", isDirectory: false)
        )
    }()

    var databasesURL: URL { Constant.databasesURL }
    var wordsDatabase: URL { Constant.wordsDatabase }
    var filesAppHost: URL { Constant.filesAppHost }
    var appHost: URL { Constant.appHost }
    var databasesDirectory: URL { Constant.databasesURL }
    var logsDirectory: URL { FileManager.documentsURL.appendingPathComponent("logs") }

    var supportsCloudKit: Bool { false }

    // MARK: Private

    private lazy var coreDataStack: CoreDataStack = {
        let stack = CoreDataStack(name: "Quran", modelUrl: CoreDataModelResources.quranModel) {
            let lastPage = CoreDataLastPageUniquifier()
            let pageBookmark = CoreDataPageBookmarkUniquifier()
            let note = CoreDataNoteUniquifier()
            return [lastPage, pageBookmark, note]
        }
        return stack
    }()
}

private enum Constant {
    static let wordsDatabase = Bundle.main
        .url(forResource: "words", withExtension: "db")!

    static let appHost: URL = URL(validURL: "https://quran-files.hisnulmuslimdua.com/")

    static let filesAppHost: URL = URL(validURL: "https://quran-files.hisnulmuslimdua.com/")

    static let databasesURL = FileManager.documentsURL
        .appendingPathComponent("databases", isDirectory: true)

    /// If set, the Quran.com login will be enabled.
    static let QuranOAuthAppConfigurations: AuthenticationClientConfiguration? = nil
}

struct AppReadingRemoteResources: ReadingRemoteResources {
    let appHost: URL

    func resource(for reading: Reading) -> RemoteResource? {
        let path: String = switch reading {
        case .hafs_1405:
            // Pointing to images_1920 to prevent folder mismatch crashes in ContentImageBuilder
            "data/zips/images_1920.zip"
        case .tajweed:
            "data/tajweed/zips/images_1280.zip"
        default:
            // Since other readings are commented out, we don't need their paths.
            // Using a dummy path just in case.
            ""
        }

        let url = appHost.appendingPathComponent(path)
        return RemoteResource(url: url, reading: reading, version: 1)
    }
}
