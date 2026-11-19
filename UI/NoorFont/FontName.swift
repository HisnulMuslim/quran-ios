//
//  FontName.swift
//
//
//  Created by Mohamed Afifi on 2023-06-23.
//

import Foundation
import SwiftUI

public enum FontName: CaseIterable {
    /// Used in Arabic tafseer
    case arabic

    /// Used in quran text in translation view
    case quran

    /// Used in arabic suras in Uthmanic font
    case suraNames

    /// Used for Kannada translations
    case kannada

    /// Used for Kannada translations (bold)
    case kannadaBold

    /// Used for Kannada translations (Noto Serif)
    case kannadaSerif

    struct FontDetails {
        let name: String
        let family: String
        let fileName: String
    }

    // MARK: Internal

    var details: FontDetails {
        switch self {
        case .arabic:
            return FontDetails(
                name: "Kitab-Regular",
                family: "Kitab",
                fileName: "Kitab-Regular.ttf"
            )
        case .quran:
            return FontDetails(
                name: "KFGQPCHAFSUthmanicScript-Bold",
                family: "KFGQPC HAFS Uthmanic Script",
                fileName: "UthmanicHafs1B Ver13.ttf"
            )
        case .suraNames:
            return FontDetails(
                name: "icomoon",
                family: "icomoon",
                fileName: "surah_names.ttf"
            )
        case .kannada:
            return FontDetails(
                name: "NotoSansKannada-Regular",
                family: "Noto Sans Kannada",
                fileName: "NotoSansKannada-Regular.ttf"
            )
        case .kannadaBold:
            return FontDetails(
                name: "NotoSansKannada-Bold",
                family: "Noto Sans Kannada",
                fileName: "NotoSansKannada-Bold.ttf"
            )
        case .kannadaSerif:
            return FontDetails(
                name: "NotoSerifKannada-Regular",
                family: "Noto Serif Kannada",
                fileName: "NotoSerifKannada-Regular.ttf"
            )
        }
    }
}

public extension Font {
    static func custom(_ name: FontName, size: CGFloat) -> Font {
        custom(name.details.name, size: size)
    }

    static func custom(_ name: FontName, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        custom(name.details.name, size: size, relativeTo: textStyle)
    }
}

public extension UIFont {
    convenience init(_ font: FontName, size: CGFloat) {
        self.init(name: font.details.name, size: size)!
    }
}

extension FontName {
    private static let registerOnce: Void = {
        for font in FontName.allCases {
            registerFont(font.details.fileName, in: .module)
        }
    }()

    public static func registerFonts() {
        _ = registerOnce
    }

    private static func registerFont(_ name: String, in bundle: Bundle) {
        let fontURL = bundle.url(forResource: name, withExtension: nil)
            ?? Bundle.main.url(forResource: name, withExtension: nil)
            ?? URL(fileURLWithPath: "/Users/azhar/Quran/quran-ios/UI/NoorFont/Resources/\(name)")

        guard FileManager.default.fileExists(atPath: fontURL.path),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            error?.release()
        }
    }

    public static func registerFontFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        guard let fontDataProvider = CGDataProvider(url: url as CFURL),
              let font = CGFont(fontDataProvider) else {
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            error?.release()
        }
    }
}
