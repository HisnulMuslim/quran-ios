//
//  TranslationUpdatePreferences.swift
//  Quran
//
//  Created by Antigravity on 2026-06-25.
//

import Foundation
import Preferences

public final class TranslationUpdatePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = TranslationUpdatePreferences()

    public static let updateCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours (in seconds)

    @Preference(lastChecked)
    public var lastChecked: Date?

    public func reset() {
        Preferences.shared.removeValueForKey(Self.lastChecked)
    }

    // MARK: Private

    private static let lastChecked = PreferenceKey<Date?>(key: "translation-update.last-checked", defaultValue: nil)
}
