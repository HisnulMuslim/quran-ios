//
//  Localizations.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/13/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

public enum Language: String, Hashable, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"
    case kannada = "kn"

    public var id: String { rawValue }
}

public enum Table: String {
    case localizable = "Localizable"
    case android = "Android"
    case suras = "Suras"
    case readers = "Readers"
}

public func lFormat(_ key: String, table: Table = .localizable, language: Language? = nil, _ arguments: CVarArg...) -> String {
    let localization = l(key, table: table, language: language)
    return String(format: localization, locale: .fixedCurrentLocaleNumbers, arguments: arguments)
}

public var AppLanguage: Language {
    get {
        guard let lang = UserDefaults.standard.string(forKey: "AppLanguage") else { return .kannada }
        return Language(rawValue: lang) ?? .kannada
    }
    set {
        guard newValue != AppLanguage else { return }
        UserDefaults.standard.set(true, forKey: "hasSelectedInitialLanguage")
        UserDefaults.standard.set(newValue.rawValue, forKey: "AppLanguage")
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
    }
}

public extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("AppLanguageDidChange")
    static let requestTranslationsSelection = Notification.Name("RequestTranslationsSelection")
    static let localTranslationsDidChange = Notification.Name("LocalTranslationsDidChange")
}

public func l(_ key: String, table: Table = .localizable, language: Language? = nil) -> String {
    if let language {
        return localizedString(key, table: table, language: language)
    }

    // Always fall back to the selected `AppLanguage` first!
    if let appLangValue = optionalLocalizedString(key, table: table, language: AppLanguage), appLangValue != key {
        return appLangValue
    }

    // If not found in user's preferred language, fallback to English natively.
    return localizedString(key, table: table, language: .english)
}

private func localizedString(_ key: String, table: Table = .localizable, language: Language) -> String {
    guard
        let path = Bundle.fixedModule.path(forResource: language.rawValue, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else { return key }
    return NSLocalizedString(key, tableName: table.rawValue, bundle: bundle, comment: "")
}

private func optionalLocalizedString(_ key: String, table: Table = .localizable, language: Language) -> String? {
    guard
        let path = Bundle.fixedModule.path(forResource: language.rawValue, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else { return nil }
    let value = NSLocalizedString(key, tableName: table.rawValue, bundle: bundle, comment: "")
    return value == key ? nil : value
}

public func lAndroid(_ key: String, language: Language? = nil) -> String {
    l(key, table: .android, language: language)
}
