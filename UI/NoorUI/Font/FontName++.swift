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

private let arabicQuranTextFontSize: CGFloat = 21
private let arabicTafseerTextFontSize: CGFloat = 21

public extension Font {
    static func quran(ofSize size: FontSize? = nil) -> Font {
        custom(.quran, size: size?.fontSize(forMediumSize: arabicQuranTextFontSize) ?? arabicQuranTextFontSize)
    }

    static func arabicTafseer() -> Font {
        custom(.arabic, size: arabicTafseerTextFontSize)
    }

    static func kannada(for textStyle: Font.TextStyle, isBold: Bool = false) -> Font {
        let size: CGFloat = switch textStyle {
        case .largeTitle: 36
        case .title: 30
        case .title2: 24
        case .title3: 22
        case .headline: 19
        case .body: 19
        case .callout: 18
        case .subheadline: 17
        case .footnote: 16
        case .caption: 14
        case .caption2: 13
        @unknown default: 19
        }
        return .custom(isBold ? .kannadaBold : .kannada, size: size, relativeTo: textStyle)
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
