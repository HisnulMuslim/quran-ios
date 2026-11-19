//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI

private struct ThemedColorInvertModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeStyle) var themeStyle
    let preserveHue: Bool

    func body(content: Content) -> some View {
        if colorScheme == .dark || themeStyle == .quiet {
            if preserveHue {
                content
                    .colorInvert()
                    .hueRotation(.degrees(180))
            } else {
                content.colorInvert()
            }
        } else {
            content
        }
    }
}

extension View {
    public func invertThemedColorIfNeeded(preserveHue: Bool = false) -> some View {
        modifier(ThemedColorInvertModifier(preserveHue: preserveHue))
    }
}
