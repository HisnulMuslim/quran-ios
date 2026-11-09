//
//  RemoteBackgroundService.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Foundation
import UIKit
import VLogging

public final class RemoteBackgroundService {
    public static let shared = RemoteBackgroundService()

    #if DEBUG
    private let primaryCatalogURL = URL(string: "https://quran-files.hisnulmuslimdua.com/data/api-test/backgrounds.json")!
    private let fallbackCatalogURL = URL(string: "https://quran-files.hisnulmuslimdua.com/data/api/backgrounds.json")!
    #else
    private let primaryCatalogURL = URL(string: "https://quran-files.hisnulmuslimdua.com/data/api/backgrounds.json")!
    private let fallbackCatalogURL = URL(string: "https://quran-files.hisnulmuslimdua.com/data/api-test/backgrounds.json")!
    #endif
    private let cacheDirectory: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("remote_ayah_backgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private var catalogCacheFile: URL {
        cacheDirectory.appendingPathComponent("catalog_cache.json")
    }

    public func cachedCatalog() -> [RemoteAyahBackgroundItem]? {
        guard FileManager.default.fileExists(atPath: catalogCacheFile.path),
              let data = try? Data(contentsOf: catalogCacheFile),
              let catalog = try? JSONDecoder().decode(RemoteAyahBackgroundCatalog.self, from: data) else {
            return nil
        }
        return catalog.backgrounds
    }

    public func fetchCatalog(forceRefresh: Bool = false) async throws -> [RemoteAyahBackgroundItem] {
        var request = URLRequest(url: primaryCatalogURL, timeoutInterval: 12)
        // Always bypass stale URLSession disk/memory caches so new backgrounds appear automatically
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            let catalog = try JSONDecoder().decode(RemoteAyahBackgroundCatalog.self, from: data)
            try? data.write(to: catalogCacheFile)
            pruneOrphanedCache(keeping: catalog.backgrounds)
            return catalog.backgrounds
        } catch {
            logger.warning("RemoteBackgroundService: primary catalog failed (\(error)), trying fallback...")
            var fallbackReq = URLRequest(url: fallbackCatalogURL, timeoutInterval: 12)
            fallbackReq.cachePolicy = .reloadIgnoringLocalCacheData

            do {
                let (data, response) = try await URLSession.shared.data(for: fallbackReq)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                let catalog = try JSONDecoder().decode(RemoteAyahBackgroundCatalog.self, from: data)
                try? data.write(to: catalogCacheFile)
                pruneOrphanedCache(keeping: catalog.backgrounds)
                return catalog.backgrounds
            } catch {
                // If network fails completely, return locally cached catalog if available
                if let cached = cachedCatalog(), !cached.isEmpty {
                    logger.info("RemoteBackgroundService: network unavailable, using disk-cached catalog (\(cached.count) items)")
                    return cached
                }
                throw error
            }
        }
    }

    public func cachedThumbnail(for id: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(id).jpg")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    public func downloadAndCacheThumbnail(for item: RemoteAyahBackgroundItem) async -> UIImage? {
        if let cached = cachedThumbnail(for: item.id) {
            return cached
        }
        guard let url = URL(string: item.thumbnailUrl),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }
        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(item.id).jpg")
        try? data.write(to: fileURL)
        return image
    }

    public func cachedImage(for id: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    public func downloadAndCacheImage(for item: RemoteAyahBackgroundItem) async throws -> UIImage {
        if let cached = cachedImage(for: item.id) {
            return cached
        }
        guard let url = URL(string: item.imageUrl) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        let fileURL = cacheDirectory.appendingPathComponent("\(item.id).jpg")
        try? data.write(to: fileURL)
        return image
    }

    private func pruneOrphanedCache(keeping validItems: [RemoteAyahBackgroundItem]) {
        let validIds = Set(validItems.map { $0.id })
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            let filename = file.lastPathComponent
            if filename == "catalog_cache.json" { continue }

            var id = filename.replacingOccurrences(of: ".jpg", with: "")
            if id.hasPrefix("thumb_") {
                id = String(id.dropFirst("thumb_".count))
            }
            if !validIds.contains(id) {
                try? FileManager.default.removeItem(at: file)
                logger.info("RemoteBackgroundService: pruned removed background from cache: \(filename)")
            }
        }
    }
}

