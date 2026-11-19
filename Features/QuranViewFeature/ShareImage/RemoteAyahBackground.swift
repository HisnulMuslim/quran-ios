//
//  RemoteAyahBackground.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Foundation
import Localization
import UIKit

public struct RemoteAyahBackgroundItem: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let nameKn: String?
    public let nameAr: String?
    public let thumbnailUrl: String
    public let imageUrl: String?
    public let type: String?
    public let videoUrl: String?
    public let durationSec: Double?
    public let sizeBytes: Int64?
    public let resolution: String?
    public let isHd: Bool?

    public init(
        id: String,
        name: String,
        nameKn: String? = nil,
        nameAr: String? = nil,
        thumbnailUrl: String,
        imageUrl: String? = nil,
        type: String? = nil,
        videoUrl: String? = nil,
        durationSec: Double? = nil,
        sizeBytes: Int64? = nil,
        resolution: String? = nil,
        isHd: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.nameKn = nameKn
        self.nameAr = nameAr
        self.thumbnailUrl = thumbnailUrl
        self.imageUrl = imageUrl
        self.type = type
        self.videoUrl = videoUrl
        self.durationSec = durationSec
        self.sizeBytes = sizeBytes
        self.resolution = resolution
        self.isHd = isHd
    }

    public var isVideo: Bool {
        !(videoUrl?.isEmpty ?? true) && type != "image"
    }

    public var isHdVideo: Bool {
        if isHd == true { return true }
        guard let res = resolution?.lowercased() else { return false }
        return res == "1080p" || res == "hd"
    }

    public var formattedSizeLabel: String? {
        guard let bytes = sizeBytes, bytes > 0 else { return nil }
        return String(format: "%.1f MB", Double(bytes) / 1_000_000.0)
    }

    public var localizedName: String {
        if AppLanguage == .kannada, let kn = nameKn, !kn.isEmpty {
            return kn
        }
        if AppLanguage == .arabic, let ar = nameAr, !ar.isEmpty {
            return ar
        }
        return name
    }
}

public struct RemoteAyahBackgroundCatalog: Codable {
    public let version: Int
    public let backgrounds: [RemoteAyahBackgroundItem]
    public let videos: [RemoteAyahBackgroundItem]?

    public var allItems: [RemoteAyahBackgroundItem] {
        var seen = Set<String>()
        return (backgrounds + (videos ?? [])).filter { seen.insert($0.id).inserted }
    }
}

