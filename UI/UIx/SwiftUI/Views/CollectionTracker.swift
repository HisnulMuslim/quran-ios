//
//  CollectionTracker.swift
//
//
//  Created by Mohamed Afifi on 2024-01-27.
//

import SwiftUI

// MARK: - TrackingView

private class TrackingTargetView<Item: Hashable>: UIView {
    var item: Item

    init(item: Item) {
        self.item = item
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct TrackingTargetViewRepresentable<Item: Hashable>: UIViewRepresentable {
    let item: Item

    func makeUIView(context: Context) -> TrackingTargetView<Item> {
        TrackingTargetView(item: item)
    }

    func updateUIView(_ view: TrackingTargetView<Item>, context: Context) {
        view.item = item
    }
}

private struct TrackingTargetModifier<Item: Hashable>: ViewModifier {
    let item: Item

    func body(content: Content) -> some View {
        content
            .background(TrackingTargetViewRepresentable(item: item))
    }
}

// MARK: - TrackingContainer

private class CollectionTrackerView: UIView {}

private struct CollectionTrackerViewRepresentable<Item: Hashable>: UIViewRepresentable {
    let tracker: CollectionTracker<Item>

    func makeUIView(context: Context) -> CollectionTrackerView {
        let view = CollectionTrackerView()
        tracker.registerView(view)
        return view
    }

    func updateUIView(_ view: CollectionTrackerView, context: Context) {
        tracker.registerView(view)
    }
}

public final class CollectionTracker<Item: Hashable> {
    private var trackingViews = NSHashTable<CollectionTrackerView>.weakObjects()

    public init() {}

    fileprivate func registerView(_ view: CollectionTrackerView) {
        trackingViews.add(view)
    }

    private var visibleViews: [TrackingTargetView<Item>] {
        let activeViews = trackingViews.allObjects
        guard !activeViews.isEmpty else {
            return []
        }
        for activeView in activeViews {
            var current: UIView? = activeView
            var bestFound: [TrackingTargetView<Item>] = []
            while let c = current {
                let found = c.findVisibleSubviews(ofType: TrackingTargetView<Item>.self)
                if found.count > bestFound.count {
                    bestFound = found
                }
                current = c.superview
            }
            if !bestFound.isEmpty {
                return bestFound
            }
        }
        return []
    }

    public func itemAtPoint(_ point: CGPoint) -> Item? {
        let views = visibleViews
        guard !views.isEmpty else {
            return nil
        }

        // 1. Exact hit check
        for visibleView in views {
            let localPoint = visibleView.convert(point, from: nil)
            if visibleView.point(inside: localPoint, with: nil) {
                return visibleView.item
            }
        }

        // 2. Nearest view fallback (for margins, line gaps, headers/footers, and smooth drag)
        var closestItem: Item?
        var minDistance: CGFloat = .greatestFiniteMagnitude

        for visibleView in views {
            let windowFrame = visibleView.convert(visibleView.bounds, to: nil)
            guard windowFrame.width > 0 && windowFrame.height > 0 else {
                continue
            }
            let dx = max(0, max(windowFrame.minX - point.x, point.x - windowFrame.maxX))
            let dy = max(0, max(windowFrame.minY - point.y, point.y - windowFrame.maxY))
            // Vertical distance weighted more heavily for stacked text lines / verses
            let distance = dy * 2.0 + dx
            if distance < minDistance {
                minDistance = distance
                closestItem = visibleView.item
            }
        }

        return closestItem
    }
}

private struct CollectionTrackerModifier<Item: Hashable>: ViewModifier {
    let tracker: CollectionTracker<Item>

    func body(content: Content) -> some View {
        content
            .background(CollectionTrackerViewRepresentable(tracker: tracker))
    }
}

extension View {
    public func trackingTarget(item: some Hashable) -> some View {
        modifier(TrackingTargetModifier(item: item))
    }

    public func trackCollection(with tracker: CollectionTracker<some Hashable>) -> some View {
        modifier(CollectionTrackerModifier(tracker: tracker))
    }
}
