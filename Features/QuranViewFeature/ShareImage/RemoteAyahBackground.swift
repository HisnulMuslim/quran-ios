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
    public let thumbnailUrl: String
    public let imageUrl: String

    public var localizedName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        if isKannada, let kn = nameKn, !kn.isEmpty {
            return kn
        }
        return name
    }
}

public struct RemoteAyahBackgroundCatalog: Codable {
    public let version: Int
    public let backgrounds: [RemoteAyahBackgroundItem]
}

