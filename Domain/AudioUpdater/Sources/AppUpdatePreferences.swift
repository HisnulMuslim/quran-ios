//
//  AppUpdatePreferences.swift
//
//
//  Created by Antigravity on 2026-07-01.
//

import Foundation
import Preferences

public final class AppUpdatePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = AppUpdatePreferences()

    @Preference(postponeUntilKey) public var postponeUntil: Date?
    @Preference(lastCheckedKey) public var lastChecked: Date?

    public func reset() {
        Preferences.shared.removeValueForKey(Self.postponeUntilKey)
        Preferences.shared.removeValueForKey(Self.lastCheckedKey)
    }

    // MARK: Private

    private static let postponeUntilKey = PreferenceKey<Date?>(key: "app-update.postpone-until", defaultValue: nil)
    private static let lastCheckedKey = PreferenceKey<Date?>(key: "app-update.last-checked", defaultValue: nil)
}
