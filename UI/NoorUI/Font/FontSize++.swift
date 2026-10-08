//
//  FontSize++.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import CoreFoundation
import QuranText

public extension FontSize {
    func fontSize(forMediumSize size: CGFloat) -> CGFloat {
        let factor: CGFloat = switch self {
        case .level1: 1.2500
        case .level2: 1.3557
        case .level3: 1.4702
        case .level4: 1.5945
        case .level5: 1.7293
        case .level6: 1.8755
        case .level7: 2.0340
        case .level8: 2.2059
        case .level9: 2.3924
        case .level10: 2.5946
        case .level11: 2.8139
        case .level12: 3.0518
        case .xSmall: 0.7 * 0.7 * 0.7
        case .small: 0.7 * 0.7
        case .medium: 0.7
        case .large: 1
        case .xLarge: 1 / 0.8
        case .xxLarge: 1 / 0.8 / 0.8
        case .xxxLarge: 1 / 0.8 / 0.8 / 0.8
        case .accessibility1: 1 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility2: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility3: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility4: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility5: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        }
        return size * factor
    }

    /// Font size in points calibrated specifically for translation prose (Kannada, English, etc.).
    /// Spans 12 smooth levels from 16.0 pt (compact/SE) to 42.0 pt (large accessibility).
    var translationFontSize: CGFloat {
        switch self {
        case .level1: 16.0
        case .level2: 17.5
        case .level3: 19.0
        case .level4: 21.0
        case .level5: 23.0
        case .level6: 25.5
        case .level7: 28.0
        case .level8: 31.0
        case .level9: 34.0
        case .level10: 37.0
        case .level11: 39.5
        case .level12: 42.0
        case .xSmall: 13.0
        case .small: 14.5
        case .medium: 16.0
        case .large: 19.0
        case .xLarge: 23.0
        case .xxLarge: 28.0
        case .xxxLarge: 34.0
        case .accessibility1: 37.0
        case .accessibility2: 40.0
        case .accessibility3: 42.0
        case .accessibility4: 45.0
        case .accessibility5: 48.0
        }
    }
}
