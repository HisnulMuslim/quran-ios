//
//  TranslationNetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import NetworkSupport
import QuranText

struct TranslationNetworkManager {
    #if DEBUG
        static let path = "/data/api-test/translations.json"
    #else
        static let path = "/data/api/translations.json"
    #endif

    let networkManager: NetworkManager
    let parser: TranslationsParser

    func getTranslations() async throws -> [Translation] {
        let data = try await networkManager.request(Self.path)
        return try parser.parse(data)
    }
}
