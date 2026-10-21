//
//  FontSize++.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import CoreFoundation
import QuranText
import UIKit

public extension FontSize {
    /// General UI scaling factor for iPad devices compared to iPhone 17 Pro (6.7-inch).
    static var uiPadScale: CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return 1.0 }
        let screenBounds = UIScreen.main.bounds
        let maxDim = max(screenBounds.width, screenBounds.height)
        if maxDim >= 1300 {
            return 1.40
        } else {
            return 1.25
        }
    }

    /// iPad typography scale for Arabic Quran text.
    /// On iPad 13-inch, scaled so that level 1 (minimum) corresponds to point 4 (58.60 pt),
    /// and level 3 (default) corresponds to point 6 (68.92 pt).
    static var arabicPadScale: CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return 1.0 }
        let screenBounds = UIScreen.main.bounds
        let maxDim = max(screenBounds.width, screenBounds.height)
        if maxDim >= 1300 {
            return 2.232 // level 1 = 58.59 pt (point 4), level 3 = 68.91 pt (point 6)
        } else {
            return 1.50
        }
    }

    /// iPad typography scale for Translation text (Kannada, English, etc.).
    /// On iPad 13-inch, scaled so that level 1 (minimum) corresponds to point 4 (37.58 pt),
    /// and level 3 (default) corresponds to point 6 (44.63 pt).
    static var translationPadScale: CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return 1.0 }
        let screenBounds = UIScreen.main.bounds
        let maxDim = max(screenBounds.width, screenBounds.height)
        if maxDim >= 1300 {
            return 2.349 // level 1 = 37.58 pt (point 4), level 3 = 44.63 pt (point 6)
        } else {
            return 1.50
        }
    }

    /// Check if current device is iPad 13-inch
    static var isPad13Inch: Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        let screenBounds = UIScreen.main.bounds
        return max(screenBounds.width, screenBounds.height) >= 1300
    }

    /// Backwards compatibility for general pad scale
    static var padScale: CGFloat {
        uiPadScale
    }

    static var defaultArabicMediumSize: CGFloat {
        21.0 * arabicPadScale
    }

    func arabicFontSize() -> CGFloat {
        fontSize(forMediumSize: Self.defaultArabicMediumSize)
    }

    func fontSize(forMediumSize size: CGFloat) -> CGFloat {
        if Self.isPad13Inch {
            let factor: CGFloat = switch self {
            case .level1: 0.9800 // 45.94 pt (Option A Minimum, 1 level below previous min)
            case .level2: 1.0628 // 49.82 pt (Dot 2 Default)
            case .level3: 1.1526 // 54.02 pt
            case .level4: 1.2500 // 58.59 pt
            case .level5: 1.3557 // 63.54 pt
            case .level6: 1.4702 // 68.91 pt
            case .level7: 1.5945 // 74.74 pt
            case .level8: 1.7293 // 81.06 pt
            case .level9: 1.8755 // 87.91 pt
            case .level10: 2.0340 // 95.34 pt
            case .level11: 2.2059 // 103.39 pt
            case .level12: 2.3924 // 112.14 pt (Maximum)
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
        } else {
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
    }

    /// Font size in points calibrated specifically for translation prose (Kannada, English, etc.).
    /// Spans 12 smooth levels from 16.0 pt (compact) to 42.0 pt (large) on iPhone 17 Pro.
    /// On iPad Pro 13-inch (Option A), level 1 starts at 28.8 pt, level 2 is 31.4 pt (Default),
    /// and level 12 scales up to 79.9 pt.
    var translationFontSize: CGFloat {
        if Self.isPad13Inch {
            let scale: CGFloat = Self.translationPadScale
            let baseSize: CGFloat = switch self {
            case .level1: 12.25 // 28.78 pt (Option A Minimum)
            case .level2: 13.37 // 31.41 pt (Dot 2 Default)
            case .level3: 14.65 // 34.41 pt
            case .level4: 16.00 // 37.58 pt
            case .level5: 17.50 // 41.11 pt
            case .level6: 19.00 // 44.63 pt
            case .level7: 21.00 // 49.33 pt
            case .level8: 23.00 // 54.03 pt
            case .level9: 25.50 // 59.90 pt
            case .level10: 28.00 // 65.77 pt
            case .level11: 31.00 // 72.82 pt
            case .level12: 34.00 // 79.87 pt (Maximum)
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
            return baseSize * scale
        } else {
            let scale: CGFloat = Self.translationPadScale
            let baseSize: CGFloat = switch self {
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
            return baseSize * scale
        }
    }
}
