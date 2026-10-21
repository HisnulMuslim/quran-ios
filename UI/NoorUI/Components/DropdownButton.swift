//
//  DropdownButton.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import SwiftUI
import UIKit

public struct DropdownButton<Item: Hashable, Content: View>: View {
    private let items: [Item]
    @Binding private var selectedItem: Item
    private let isItemDisabled: (Item) -> Bool
    private let content: (Item) -> Content

    @ScaledMetric private var horizontalPadding = 12.0
    @ScaledMetric private var verticalPadding = 7.0
    @ScaledMetric private var cornerRadius = 10.0

    public init(
        items: [Item],
        selectedItem: Binding<Item>,
        isItemDisabled: @escaping (Item) -> Bool = { _ in false },
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        _selectedItem = selectedItem
        self.isItemDisabled = isItemDisabled
        self.content = content
    }

    public var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        UIView.performWithoutAnimation {
                            selectedItem = item
                        }
                    }
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
                .disabled(isItemDisabled(item))
            }
        } label: {
            ZStack {
                // Stable hidden footprint: measures all items to hold the maximum width and height,
                // so the dropdown button maintains a constant size across all selections without jumping or clipping.
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        content(item)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .hidden()
                }

                // Visible content: fills the footprint and stays clipped to curved continuous corners
                HStack(spacing: 8) {
                    content(selectedItem)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(UIColor.secondarySystemFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .foregroundStyle(Color.label)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .fixedSize()
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}
