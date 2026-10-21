//
//  FontSize.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import SwiftUI

public enum FontSize: Int, CaseIterable, CustomStringConvertible {
    case accessibility5 = -6
    case accessibility4 = -5
    case accessibility3 = -4
    case accessibility2 = -3
    case accessibility1 = -2
    case xxxLarge = -1
    case xxLarge = 0
    case xLarge = 1
    case large = 2
    case medium = 3
    case small = 4
    case xSmall = 5

    // 12 smooth zoom levels spanning from old Dot 5 (.xLarge) to old Dot 9 (.accessibility2)
    case level1 = 10
    case level2 = 11
    case level3 = 12
    case level4 = 13
    case level5 = 14
    case level6 = 15
    case level7 = 16
    case level8 = 17
    case level9 = 18
    case level10 = 19
    case level11 = 20
    case level12 = 21

    // MARK: Public

    public var description: String {
        switch self {
        case .level1: "level1"
        case .level2: "level2"
        case .level3: "level3"
        case .level4: "level4"
        case .level5: "level5"
        case .level6: "level6"
        case .level7: "level7"
        case .level8: "level8"
        case .level9: "level9"
        case .level10: "level10"
        case .level11: "level11"
        case .level12: "level12"
        case .accessibility5: "accessibility5"
        case .accessibility4: "accessibility4"
        case .accessibility3: "accessibility3"
        case .accessibility2: "accessibility2"
        case .accessibility1: "accessibility1"
        case .xxxLarge: "xxxLarge"
        case .xxLarge: "xxLarge"
        case .xLarge: "xLarge"
        case .large: "large"
        case .medium: "medium"
        case .small: "small"
        case .xSmall: "xSmall"
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

private var isPadDevice: Bool {
    #if canImport(UIKit)
    return UIDevice.current.userInterfaceIdiom == .pad
    #else
    return false
    #endif
}

private var isPad13Inch: Bool {
    #if canImport(UIKit)
    guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
    let bounds = UIScreen.main.bounds
    return max(bounds.width, bounds.height) >= 1300
    #else
    return false
    #endif
}

extension FontSize {
    public var dynamicTypeSize: DynamicTypeSize {
        if isPad13Inch {
            switch self {
            case .level1, .level2: .accessibility2
            case .level3, .level4: .accessibility3
            case .level5, .level6: .accessibility4
            case .level7, .level8, .level9, .level10, .level11, .level12: .accessibility5
            case .accessibility5, .accessibility4, .accessibility3, .accessibility2, .accessibility1: .accessibility5
            case .xxxLarge: .accessibility3
            case .xxLarge: .accessibility2
            case .xLarge: .accessibility2
            case .large, .medium, .small, .xSmall: .accessibility2
            }
        } else if isPadDevice {
            switch self {
            case .level1, .level2: .xxxLarge
            case .level3, .level4: .accessibility1
            case .level5, .level6: .accessibility2
            case .level7, .level8: .accessibility3
            case .level9, .level10: .accessibility4
            case .level11, .level12: .accessibility5
            case .accessibility5: .accessibility5
            case .accessibility4: .accessibility5
            case .accessibility3: .accessibility5
            case .accessibility2: .accessibility4
            case .accessibility1: .accessibility3
            case .xxxLarge: .accessibility2
            case .xxLarge: .accessibility1
            case .xLarge: .xxxLarge
            case .large: .xxLarge
            case .medium: .xLarge
            case .small: .large
            case .xSmall: .medium
            }
        } else {
            switch self {
            case .level1, .level2: .xLarge
            case .level3, .level4, .level5: .xxLarge
            case .level6, .level7, .level8: .xxxLarge
            case .level9, .level10: .accessibility1
            case .level11, .level12: .accessibility2
            case .accessibility5: .accessibility5
            case .accessibility4: .accessibility4
            case .accessibility3: .accessibility3
            case .accessibility2: .accessibility2
            case .accessibility1: .accessibility1
            case .xxxLarge: .xxxLarge
            case .xxLarge: .xxLarge
            case .xLarge: .xLarge
            case .large: .large
            case .medium: .medium
            case .small: .small
            case .xSmall: .xSmall
            }
        }
    }

    public var translationDynamicTypeSize: DynamicTypeSize {
        if isPad13Inch {
            switch self {
            case .level1, .level2: .accessibility1
            case .level3, .level4: .accessibility2
            case .level5, .level6: .accessibility3
            case .level7, .level8: .accessibility4
            case .level9, .level10, .level11, .level12: .accessibility5
            case .accessibility5, .accessibility4, .accessibility3, .accessibility2, .accessibility1: .accessibility5
            case .xxxLarge: .accessibility3
            case .xxLarge: .accessibility2
            case .xLarge: .accessibility2
            case .large, .medium, .small, .xSmall: .accessibility2
            }
        } else if isPadDevice {
            switch self {
            case .level1, .level2: .xxLarge
            case .level3, .level4: .xxxLarge
            case .level5, .level6: .accessibility1
            case .level7, .level8: .accessibility2
            case .level9, .level10: .accessibility3
            case .level11, .level12: .accessibility4
            case .accessibility5: .accessibility5
            case .accessibility4: .accessibility5
            case .accessibility3: .accessibility5
            case .accessibility2: .accessibility4
            case .accessibility1: .accessibility3
            case .xxxLarge: .accessibility2
            case .xxLarge: .accessibility1
            case .xLarge: .xxxLarge
            case .large: .xxLarge
            case .medium: .xLarge
            case .small: .large
            case .xSmall: .medium
            }
        } else {
            switch self {
            case .level1: .medium
            case .level2: .large
            case .level3: .xLarge
            case .level4: .xxLarge
            case .level5: .xxxLarge
            case .level6, .level7: .accessibility1
            case .level8, .level9: .accessibility2
            case .level10, .level11: .accessibility3
            case .level12: .accessibility4
            case .accessibility5: .accessibility5
            case .accessibility4: .accessibility4
            case .accessibility3: .accessibility3
            case .accessibility2: .accessibility2
            case .accessibility1: .accessibility1
            case .xxxLarge: .xxxLarge
            case .xxLarge: .xxLarge
            case .xLarge: .xLarge
            case .large: .large
            case .medium: .medium
            case .small: .small
            case .xSmall: .xSmall
            }
        }
    }
}

extension FontSize: Strideable {
    public func distance(to other: FontSize) -> Int {
        Stride(other.rawValue) - Stride(rawValue)
    }

    public func advanced(by n: Int) -> FontSize {
        FontSize(rawValue: Stride(rawValue) + n) ?? self
    }
}

extension FontSize {
    /// Supported 12-level font size range (from level1 to level12).
    /// Bounded between old Dot 5 (.xLarge) and old Dot 9 (.accessibility2).
    public static let supportedRange: [FontSize] = [
        .level1,
        .level2,
        .level3,
        .level4,
        .level5,
        .level6,
        .level7,
        .level8,
        .level9,
        .level10,
        .level11,
        .level12,
    ]

    /// Clamps any FontSize to the supported 12-level range.
    public var clampedToSupported: FontSize {
        switch self {
        case .level1, .level2, .level3, .level4, .level5, .level6,
             .level7, .level8, .level9, .level10, .level11, .level12:
            return self
        case .xSmall, .small, .medium, .large, .xLarge:
            return .level1
        case .xxLarge:
            return .level4
        case .xxxLarge:
            return .level7
        case .accessibility1:
            return .level9
        case .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return .level12
        }
    }
}

