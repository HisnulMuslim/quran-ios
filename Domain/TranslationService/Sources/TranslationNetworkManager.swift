//
//  TranslationNetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import NetworkSupport
import QuranText

struct TranslationNetworkManager {
    static let path = "/data/api/translations.json"

    let networkManager: NetworkManager
    let parser: TranslationsParser

    func getTranslations() async throws -> [Translation] {
        let data = try await networkManager.request(Self.path)
        return try parser.parse(data)
    }
}
