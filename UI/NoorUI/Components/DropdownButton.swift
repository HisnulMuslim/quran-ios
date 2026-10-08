//
//  DropdownButton.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import SwiftUI

public struct DropdownButton<Item: Hashable, Content: View>: View {
    private let items: [Item]
    @Binding private var selectedItem: Item
    private let content: (Item) -> Content

    @ScaledMetric private var horizontalPadding = 12.0
    @ScaledMetric private var verticalPadding = 7.0
    @ScaledMetric private var cornerRadius = 10.0

    public init(items: [Item], selectedItem: Binding<Item>, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        _selectedItem = selectedItem
        self.content = content
    }

    public var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    selectedItem = item
                } label: {
                    if item == selectedItem {
                        Label {
                            content(item)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        content(item)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                content(selectedItem)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(UIColor.secondarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
            )
            .foregroundStyle(Color.label)
        }
    }
}
