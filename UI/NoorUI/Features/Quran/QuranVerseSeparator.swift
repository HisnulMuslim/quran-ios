//
//  QuranVerseSeparator.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

public struct QuranVerseSeparator: View {
    public init() { }

    @Environment(\.themeStyle) var themeStyle

    public var body: some View {
        Rectangle()
            .fill(Color(themeStyle.pageSeparatorLine).opacity(0.85))
            .frame(height: 0.8)
            .readableInsetsPadding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }
}

#Preview {
    VStack {
        QuranVerseSeparator()
    }
    .environment(\.themeStyle, .original)
}
