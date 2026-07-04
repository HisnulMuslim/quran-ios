//
//  Translation+UI.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/29/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import NoorUI
import QuranText
import SwiftUI
import VLogging

extension Translation {
    func textFont(selection: String) -> Font {
        if languageCode == "ar" {
            return .arabicTafseer()
        } else if languageCode == "kn" || languageCode == "kan" || languageCode.hasPrefix("kn") {
            return .kannada(for: .body, selection: selection)
        } else {
            return .body
        }
    }

    var characterDirection: Locale.LanguageDirection {
        Locale.characterDirection(forLanguage: languageCode)
    }
}
