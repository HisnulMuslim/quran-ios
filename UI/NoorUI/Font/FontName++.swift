//
//  FontName++.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/30/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import NoorFont
import QuranText
import SwiftUI
import VLogging

private var arabicQuranTextFontSize: CGFloat {
    FontSize.defaultArabicMediumSize
}

private var arabicTafseerTextFontSize: CGFloat {
    FontSize.defaultArabicMediumSize
}

public extension Font {
    static func quran(ofSize size: FontSize? = nil) -> Font {
        custom(.quran, size: size?.arabicFontSize() ?? arabicQuranTextFontSize)
    }

    static func arabicTafseer() -> Font {
        custom(.arabic, size: arabicTafseerTextFontSize)
    }

    static func kannada(for textStyle: Font.TextStyle, selection: String = UserDefaults.standard.string(forKey: "translationFontSelection") ?? "notoSans", isBold: Bool = false) -> Font {
        let padScale = FontSize.padScale
        let size: CGFloat = switch textStyle {
        case .largeTitle: 36 * padScale
        case .title: 30 * padScale
        case .title2: 24 * padScale
        case .title3: 22 * padScale
        case .headline: 19 * padScale
        case .body: 19 * padScale
        case .callout: 18 * padScale
        case .subheadline: 17 * padScale
        case .footnote: 16 * padScale
        case .caption: 14 * padScale
        case .caption2: 13 * padScale
        @unknown default: 19 * padScale
        }

        switch selection {
        case "kohinoor":
            let fontName = isBold ? "KohinoorKannada-SemiBold" : "KohinoorKannada-Regular"
            return .custom(fontName, size: size, relativeTo: textStyle)
        case "system":
            if isBold {
                return .system(textStyle).bold()
            } else {
                return .system(textStyle)
            }
        default: // "notoSans"
            return .custom(isBold ? .kannadaBold : .kannada, size: size, relativeTo: textStyle)
        }
    }

    static func kannada(size: CGFloat, selection: String = UserDefaults.standard.string(forKey: "translationFontSelection") ?? "notoSans", isBold: Bool = false) -> Font {
        switch selection {
        case "kohinoor":
            let fontName = isBold ? "KohinoorKannada-SemiBold" : "KohinoorKannada-Regular"
            return .custom(fontName, size: size)
        case "system":
            if isBold {
                return .system(size: size, weight: .bold)
            } else {
                return .system(size: size)
            }
        default: // "notoSans"
            return .custom(isBold ? .kannadaBold : .kannada, size: size)
        }
    }
}

public func attributedString(of text: String, arabicSuraName: String, fontSize: CGFloat) -> NSAttributedString {
    let systemFont = UIFont.systemFont(ofSize: fontSize)
    let text = NSMutableAttributedString(string: text, attributes: [.font: systemFont])
    if NSLocale.preferredLanguages.first == "ar" {
        return text
    }
    text.append(NSAttributedString(string: " "))
    let decoratedFont = UIFont(.suraNames, size: fontSize + 4)
    text.append(NSAttributedString(string: arabicSuraName, attributes: [.font: decoratedFont]))
    return text
}
