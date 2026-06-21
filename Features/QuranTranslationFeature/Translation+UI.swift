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

extension Translation {
    var textFont: Font {
        if languageCode == "ar" {
            return .arabicTafseer()
        } else if languageCode == "kn" {
            return .kannada(for: .body)
        } else {
            return .body
        }
    }

    var characterDirection: Locale.LanguageDirection {
        Locale.characterDirection(forLanguage: languageCode)
    }
}

