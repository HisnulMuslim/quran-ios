//
//  ThemeService.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import Preferences
import UIKit

@MainActor
public class ThemeService {
    // MARK: Lifecycle

    private var cancellables = Set<AnyCancellable>()

    private init() {
        SystemUserInterfaceStyleObserverWindow.shared
            .traitCollectionChangesPublisher
            .sink { [weak self] traitCollection in
                guard let self, self.preferenceAppearanceMode == .auto else { return }
                self.adaptToSystemInterfaceStyle(userInterfaceStyle: traitCollection.userInterfaceStyle)
                self.updateUserInterfaceStyle(themeStyle: self.themeStyle, appearanceMode: self.appearanceMode)
            }
            .store(in: &cancellables)
    }

    // MARK: Public

    public static let shared = ThemeService()

    public var appearanceMode: AppearanceMode {
        get { preferenceAppearanceMode }
        set {
            guard newValue != preferenceAppearanceMode else {
                return
            }
            preferenceAppearanceMode = newValue
            if newValue == .dark {
                if preferenceThemeStyle != .quiet {
                    preferenceLastLightStyle = preferenceThemeStyle
                    preferenceThemeStyle = .quiet
                }
            } else if newValue == .light {
                if preferenceThemeStyle == .quiet {
                    preferenceThemeStyle = preferenceLastLightStyle
                }
            } else if newValue == .auto {
                adaptToSystemInterfaceStyle(userInterfaceStyle: SystemUserInterfaceStyleObserverWindow.shared.traitCollection.userInterfaceStyle)
            }
            updateUserInterfaceStyle(themeStyle: themeStyle, appearanceMode: appearanceMode)
        }
    }

    public var themeStyle: ThemeStyle {
        get { preferenceThemeStyle }
        set {
            guard newValue != preferenceThemeStyle else {
                return
            }
            preferenceThemeStyle = newValue
            if newValue == .quiet {
                if preferenceAppearanceMode != .dark {
                    preferenceAppearanceMode = .dark
                }
            } else {
                preferenceLastLightStyle = newValue
                if preferenceAppearanceMode == .dark {
                    preferenceAppearanceMode = .light
                }
            }
            updateUserInterfaceStyle(themeStyle: newValue, appearanceMode: appearanceMode)
        }
    }

    public var appearanceModePublisher: AnyPublisher<AppearanceMode, Never> {
        $preferenceAppearanceMode
    }

    public var themeStylePublisher: AnyPublisher<ThemeStyle, Never> {
        $preferenceThemeStyle
    }

    public var userInterfaceStyle: UIUserInterfaceStyle {
        return themeStyle == .quiet ? .dark : appearanceMode.userInterfaceStyle
    }

    // MARK: Private

    private static let appearanceModeRaw = PreferenceKey<Int?>(key: "theme", defaultValue: nil)
    private static let appearanceModeTransformer = PreferenceTransformer<Int?, AppearanceMode>(
        rawToValue: { $0.flatMap { AppearanceMode(rawValue: $0) } ?? .auto },
        valueToRaw: { $0.rawValue }
    )

    private static let themeStyleRaw = PreferenceKey<Int?>(key: "themeStyle", defaultValue: nil)
    private static let themeStyleTransformer = PreferenceTransformer<Int?, ThemeStyle>(
        rawToValue: { $0.flatMap { ThemeStyle(rawValue: $0) } ?? .paper },
        valueToRaw: { $0.rawValue }
    )

    private static let lastLightThemeStyleRaw = PreferenceKey<Int?>(key: "lastLightThemeStyle", defaultValue: nil)
    private static let lastLightThemeStyleTransformer = PreferenceTransformer<Int?, ThemeStyle>(
        rawToValue: { $0.flatMap { ThemeStyle(rawValue: $0) } ?? .paper },
        valueToRaw: { $0.rawValue }
    )

    @TransformedPreference(appearanceModeRaw, transformer: appearanceModeTransformer)
    private var preferenceAppearanceMode: AppearanceMode

    @TransformedPreference(themeStyleRaw, transformer: themeStyleTransformer)
    private var preferenceThemeStyle: ThemeStyle

    @TransformedPreference(lastLightThemeStyleRaw, transformer: lastLightThemeStyleTransformer)
    private var preferenceLastLightStyle: ThemeStyle

    private func adaptToSystemInterfaceStyle(userInterfaceStyle: UIUserInterfaceStyle) {
        if userInterfaceStyle == .dark {
            if preferenceThemeStyle != .quiet {
                preferenceLastLightStyle = preferenceThemeStyle
                preferenceThemeStyle = .quiet
            }
        } else if userInterfaceStyle == .light {
            if preferenceThemeStyle == .quiet {
                preferenceThemeStyle = preferenceLastLightStyle
            }
        }
    }

    private func updateUserInterfaceStyle(themeStyle: ThemeStyle, appearanceMode: AppearanceMode) {
        let newInterfaceStyle = userInterfaceStyle
        let scenes = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
        if SystemUserInterfaceStyleObserverWindow.shared.windowScene == nil, let scene = scenes.first {
            SystemUserInterfaceStyleObserverWindow.shared.windowScene = scene
        }
        let windows = scenes.flatMap(\.windows)
        for window in windows {
            if !(window is SystemUserInterfaceStyleObserverWindow) {
                window.overrideUserInterfaceStyle = newInterfaceStyle
            }
        }
    }
}

public enum AppearanceMode: Int, CustomStringConvertible {
    case light = 0
    case dark = 1
    case auto = 2

    // MARK: Public

    public var description: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .auto: return "auto"
        }
    }
}

public enum ThemeStyle: Int, Sendable {
    case calm
    case focus
    case original
    case paper
    case quiet

    static let styles: [ThemeStyle] = [.paper, .original, .quiet, .calm, .focus]
}

private extension AppearanceMode {
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return .unspecified
        }
    }
}
