//
//  AppUpdateChecker.swift
//
//
//  Created by Antigravity on 2026-07-01.
//

import Foundation
import NetworkSupport
import Preferences
import SystemDependencies
import VLogging

public struct AppVersionConfig: Codable, Sendable {
    public let iosMinVersion: String
    public let iosLatestVersion: String
    public let iosUpdatePostponeDays: Int

    enum CodingKeys: String, CodingKey {
        case iosMinVersion = "ios_min_version"
        case iosLatestVersion = "ios_latest_version"
        case iosUpdatePostponeDays = "ios_update_postpone_days"
    }
}

public struct AppUpdateNetworkManager {
    #if DEBUG
        public static let path = "/data/api-test/ios_app_update.json"
    #else
        public static let path = "/data/api/ios_app_update.json"
    #endif
    let networkManager: NetworkManager

    public init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    public func getVersionConfig() async throws -> AppVersionConfig {
        let data = try await networkManager.request(Self.path)
        let decoder = JSONDecoder()
        return try decoder.decode(AppVersionConfig.self, from: data)
    }
}

public enum AppUpdateStatus: Equatable, Sendable {
    case noUpdate
    case optional(latestVersion: String, postponeDays: Int)
    case mandatory(minVersion: String)
}

public final class AppUpdateChecker {
    private let networkService: AppUpdateNetworkManager
    private let preferences: AppUpdatePreferences
    private let currentVersion: String
    private let baseURL: URL

    public init(
        networkManager: NetworkManager,
        baseURL: URL,
        preferences: AppUpdatePreferences = .shared,
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    ) {
        networkService = AppUpdateNetworkManager(networkManager: networkManager)
        self.baseURL = baseURL
        self.preferences = preferences
        self.currentVersion = currentVersion
    }

    public func checkUpdate() async -> AppUpdateStatus {
        #if !DEBUG
            if let lastChecked = preferences.lastChecked, Date().timeIntervalSince(lastChecked) < 6 * 60 * 60 {
                logger.info("AppUpdateChecker: Skipping update check, last checked was \(lastChecked).")
                return .noUpdate
            }
        #endif

        let fullUrl = baseURL.appendingPathComponent(AppUpdateNetworkManager.path)
        logger.info("AppUpdateChecker: Starting app update check. URL: \(fullUrl.absoluteString), Current version: \(currentVersion)")
        do {
            let config = try await networkService.getVersionConfig()
            logger.info("AppUpdateChecker: Fetched remote config. min_version: \(config.iosMinVersion), latest_version: \(config.iosLatestVersion), postpone_days: \(config.iosUpdatePostponeDays)")
            preferences.lastChecked = Date()

            // 1. Check if mandatory update is required
            if currentVersion.compare(config.iosMinVersion, options: .numeric) == .orderedAscending {
                logger.warning("AppUpdateChecker: Mandatory update required. Min version: \(config.iosMinVersion). App Store URL: https://apps.apple.com/app/id6780201059")
                return .mandatory(minVersion: config.iosMinVersion)
            }

            // 2. Check if optional update is available and not postponed
            if currentVersion.compare(config.iosLatestVersion, options: .numeric) == .orderedAscending {
                if let postponeUntil = preferences.postponeUntil, Date() < postponeUntil {
                    logger.info("AppUpdateChecker: Optional update available (\(config.iosLatestVersion)) but is postponed until \(postponeUntil).")
                    return .noUpdate
                }
                logger.info("AppUpdateChecker: Optional update available. Latest version: \(config.iosLatestVersion). App Store URL: https://apps.apple.com/app/id6780201059")
                return .optional(latestVersion: config.iosLatestVersion, postponeDays: config.iosUpdatePostponeDays)
            }

            logger.info("AppUpdateChecker: App is up-to-date. No update required.")
            return .noUpdate
        } catch {
            logger.error("AppUpdateChecker: Failed to check for app updates. \(error)")
            return .noUpdate
        }
    }

    public func postponeUpdate(days: Int) {
        let postponeTime = Date().addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
        preferences.postponeUntil = postponeTime
        logger.info("AppUpdateChecker: Postponed optional update until \(postponeTime)")
    }
}
