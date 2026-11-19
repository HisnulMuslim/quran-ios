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
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

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
        return catalog.allItems
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
            try? data.write(to: catalogCacheFile, options: .atomic)
            let items = catalog.allItems
            pruneOrphanedCache(keeping: items)
            return items
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
                try? data.write(to: catalogCacheFile, options: .atomic)
                let items = catalog.allItems
                pruneOrphanedCache(keeping: items)
                return items
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

    public func cachedMemoryThumbnail(for id: String) -> UIImage? {
        thumbnailCache.object(forKey: id as NSString)
    }

    public func cachedThumbnail(for id: String) -> UIImage? {
        if let mem = cachedMemoryThumbnail(for: id) {
            return mem
        }
        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(id).jpg")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = Self.decodedThumbnail(from: data) else {
            return nil
        }
        cacheMemoryThumbnail(image, for: id)
        return image
    }

    /// Loads a decoded, display-ready thumbnail from memory or background disk/network I/O without blocking the main thread.
    public func loadThumbnail(for item: RemoteAyahBackgroundItem) async -> UIImage? {
        if let mem = cachedMemoryThumbnail(for: item.id) {
            return mem
        }

        let fileURL = cacheDirectory.appendingPathComponent("thumb_\(item.id).jpg")
        if let diskImage = await Task.detached(priority: .userInitiated, operation: { () -> UIImage? in
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            return Self.decodedThumbnail(from: data)
        }).value {
            cacheMemoryThumbnail(diskImage, for: item.id)
            return diskImage
        }

        guard let url = URL(string: item.thumbnailUrl),
              let (data, _) = try? await URLSession.shared.data(from: url) else {
            return nil
        }
        let prepared = await Task.detached(priority: .userInitiated, operation: { () -> UIImage? in
            try? data.write(to: fileURL, options: .atomic)
            return Self.decodedThumbnail(from: data)
        }).value
        if let prepared {
            cacheMemoryThumbnail(prepared, for: item.id)
        }
        return prepared
    }

    public func downloadAndCacheThumbnail(for item: RemoteAyahBackgroundItem) async -> UIImage? {
        await loadThumbnail(for: item)
    }

    /// Returns cached item IDs across disk files in a single directory scan.
    public func cachedBackgroundIds() -> Set<String> {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        var ids = Set<String>()
        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix("vid_") && name.hasSuffix(".mp4") {
                let id = String(name.dropFirst("vid_".count).dropLast(".mp4".count))
                ids.insert(id)
            } else if !name.hasPrefix("thumb_") && name.hasSuffix(".jpg") {
                let id = String(name.dropLast(".jpg".count))
                ids.insert(id)
            }
        }
        return ids
    }

    private func cacheMemoryThumbnail(_ image: UIImage, for id: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        thumbnailCache.setObject(image, forKey: id as NSString, cost: max(1, cost))
    }

    private static func decodedThumbnail(from data: Data) -> UIImage? {
        guard let raw = UIImage(data: data) else { return nil }
        let target = CGSize(width: 320, height: 320)
        return raw.preparingThumbnail(of: target) ?? raw.preparingForDisplay() ?? raw
    }

    public func hasCachedImage(for id: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        return FileManager.default.fileExists(atPath: fileURL.path)
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
        guard let imageUrl = item.imageUrl, let url = URL(string: imageUrl) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        let fileURL = cacheDirectory.appendingPathComponent("\(item.id).jpg")
        try? data.write(to: fileURL, options: .atomic)
        return image
    }

    public func cachedVideoURL(for id: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent("vid_\(id).mp4")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? Int64,
              size > 0 else {
            return nil
        }
        return fileURL
    }

    public func cachedVideoSizeBytes(for id: String) -> Int64? {
        let fileURL = cacheDirectory.appendingPathComponent("vid_\(id).mp4")
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? Int64,
              size > 0 else {
            return nil
        }
        return size
    }

    public func downloadAndCacheVideo(
        for item: RemoteAyahBackgroundItem,
        progress: (@Sendable (Int) -> Void)? = nil
    ) async throws -> URL {
        if let cached = cachedVideoURL(for: item.id) {
            progress?(100)
            return cached
        }
        guard let urlStr = item.videoUrl, let url = URL(string: urlStr) else {
            throw URLError(.badURL)
        }

        let destURL = cacheDirectory.appendingPathComponent("vid_\(item.id).mp4")
        let tmpURL = cacheDirectory.appendingPathComponent("vid_\(item.id).mp4.tmp")
        try? FileManager.default.removeItem(at: tmpURL)

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let totalExpected = response.expectedContentLength
        FileManager.default.createFile(atPath: tmpURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: tmpURL)
        defer { try? handle.close() }

        var buffer = [UInt8]()
        buffer.reserveCapacity(32_768)
        var downloaded: Int64 = 0
        var lastPct = -1

        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 32_768 {
                try handle.write(contentsOf: Data(buffer))
                downloaded += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                if totalExpected > 0 {
                    let pct = min(99, Int((Double(downloaded) / Double(totalExpected)) * 100.0))
                    if pct != lastPct {
                        lastPct = pct
                        progress?(pct)
                    }
                }
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: Data(buffer))
            downloaded += Int64(buffer.count)
        }
        try handle.synchronize()
        try handle.close()

        guard downloaded > 0 else {
            try? FileManager.default.removeItem(at: tmpURL)
            throw URLError(.cannotDecodeContentData)
        }

        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tmpURL, to: destURL)
        progress?(100)
        return destURL
    }

    private func pruneOrphanedCache(keeping validItems: [RemoteAyahBackgroundItem]) {
        guard !validItems.isEmpty else { return }
        let validIds = Set(validItems.map { $0.id })
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            let filename = file.lastPathComponent
            if filename == "catalog_cache.json" || filename.hasSuffix(".tmp") { continue }

            var id = filename
                .replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".mp4", with: "")
            if id.hasPrefix("thumb_") {
                id = String(id.dropFirst("thumb_".count))
            } else if id.hasPrefix("vid_") {
                id = String(id.dropFirst("vid_".count))
            }
            if !validIds.contains(id) {
                try? FileManager.default.removeItem(at: file)
                logger.info("RemoteBackgroundService: pruned removed background from cache: \(filename)")
            }
        }
    }
}

