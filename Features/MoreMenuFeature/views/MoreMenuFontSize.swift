//
//  MoreMenuFontSize.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import QuranText
import SwiftUI
import VLogging

struct MoreMenuFontSize: View {
    // MARK: Internal

    let label: String
    @Binding var fontSize: FontSize

    var body: some View {
        Stepper(value: fontIndex, in: 0 ... fonts.count - 1) {
            HStack {
                Text(label)
                Spacer()
                    .background(
                        HStack {
                            Spacer()
                            Text(l("menu.fontSizeLetter")).font(.system(size: fontSizeInPoints))
                            Spacer()
                        }
                    )
            }
        }
        .padding()
    }

    // MARK: Private

    private let fonts = FontSize.supportedRange

    private var fontIndex: Binding<Int> {
        Binding(
            get: {
                if let index = fonts.firstIndex(of: fontSize) {
                    return index
                }
                let clamped = fontSize.clampedToSupported
                return fonts.firstIndex(of: clamped) ?? 0
            },
            set: { fontSize = fonts[$0] }
        )
    }

    private var fontSizeInPoints: CGFloat {
        switch fontSize {
        case .level1: return 26
        case .level2: return 28
        case .level3: return 31
        case .level4: return 34
        case .level5: return 36
        case .level6: return 39
        case .level7: return 43
        case .level8: return 46
        case .level9: return 50
        case .level10: return 54
        case .level11: return 59
        case .level12: return 64
        case .accessibility5: return 61
        case .accessibility4: return 57
        case .accessibility3: return 51
        case .accessibility2: return 46
        case .accessibility1: return 41
        case .xxxLarge: return 36
        case .xxLarge: return 31
        case .xLarge: return 25
        case .large: return 20
        case .medium: return 14
        case .small: return 10
        case .xSmall: return 7
        }
    }
}

struct MoreMenuFontSize_Previews: PreviewProvider {
    struct Container: View {
        @State var fontSize: FontSize

        var body: some View {
            MoreMenuFontSize(label: "Font Size", fontSize: $fontSize)
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(fontSize: .xSmall)
            Divider()
            Container(fontSize: .medium)
            Divider()
            Container(fontSize: .xLarge)
        }
    }
}
