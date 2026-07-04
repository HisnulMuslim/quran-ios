//
//  AppUpdateCheckerTests.swift
//
//
//  Created by Antigravity on 2026-07-01.
//

import NetworkSupport
import NetworkSupportFake
import XCTest
@testable import AudioUpdater

class AppUpdateCheckerTests: XCTestCase {
    var session: NetworkSessionFake!
    var checker: AppUpdateChecker!
    var preferences: AppUpdatePreferences!
    let baseURL = URL(string: "https://example.com")!

    override func setUp() async throws {
        session = NetworkSessionFake(queue: .main, delegate: nil)
        preferences = AppUpdatePreferences.shared
        preferences.reset()
    }

    func test_checkUpdate_noUpdate() async throws {
        let config = AppVersionConfig(iosMinVersion: "1.0.0", iosLatestVersion: "1.0.0", iosUpdatePostponeDays: 7)
        let data = try JSONEncoder().encode(config)

        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .success(data)

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.0.0")

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .noUpdate)
    }

    func test_checkUpdate_mandatoryUpdate() async throws {
        let config = AppVersionConfig(iosMinVersion: "1.2.0", iosLatestVersion: "1.3.0", iosUpdatePostponeDays: 7)
        let data = try JSONEncoder().encode(config)

        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .success(data)

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.1.0")

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .mandatory(minVersion: "1.2.0"))
    }

    func test_checkUpdate_optionalUpdate() async throws {
        let config = AppVersionConfig(iosMinVersion: "1.0.0", iosLatestVersion: "1.2.0", iosUpdatePostponeDays: 7)
        let data = try JSONEncoder().encode(config)

        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .success(data)

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.1.0")

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .optional(latestVersion: "1.2.0", postponeDays: 7))
    }

    func test_checkUpdate_optionalUpdatePostponed() async throws {
        let config = AppVersionConfig(iosMinVersion: "1.0.0", iosLatestVersion: "1.2.0", iosUpdatePostponeDays: 7)
        let data = try JSONEncoder().encode(config)

        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .success(data)

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.1.0")

        // Postpone it
        checker.postponeUpdate(days: 7)

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .noUpdate)
    }

    func test_checkUpdate_optionalUpdatePostponeExpired() async throws {
        let config = AppVersionConfig(iosMinVersion: "1.0.0", iosLatestVersion: "1.2.0", iosUpdatePostponeDays: 7)
        let data = try JSONEncoder().encode(config)

        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .success(data)

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.1.0")

        // Set expired postpone date
        preferences.postponeUntil = Date().addingTimeInterval(-10)

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .optional(latestVersion: "1.2.0", postponeDays: 7))
    }

    func test_checkUpdate_networkErrorGraceful() async throws {
        let url = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        session.dataResults[url] = .failure(URLError(.cannotFindHost))

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        checker = AppUpdateChecker(networkManager: networkManager, baseURL: baseURL, preferences: preferences, currentVersion: "1.1.0")

        let status = await checker.checkUpdate()
        XCTAssertEqual(status, .noUpdate)
    }
}
