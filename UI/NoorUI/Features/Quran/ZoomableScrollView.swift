//
//  ZoomableScrollView.swift
//  NoorUI
//
//  Created by Antigravity on 7/5/26.
//

import SwiftUI
import UIKit

class ZoomingScrollView: UIScrollView {
    var containerView: UIView? {
        didSet {
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let containerView else { return }

        // If not zooming, make the container view match the scroll view's bounds
        if zoomScale == 1.0 {
            containerView.transform = .identity
            containerView.frame = bounds
            contentSize = bounds.size
        } else {
            // Center the container view if it is smaller than the bounds during zoom
            let boundsSize = bounds.size
            let contentsSize = CGSize(
                width: containerView.bounds.size.width * zoomScale,
                height: containerView.bounds.size.height * zoomScale
            )

            var newCenter = CGPoint(x: contentSize.width / 2.0, y: contentSize.height / 2.0)

            if contentsSize.width < boundsSize.width {
                newCenter.x = boundsSize.width / 2.0
            }
            if contentsSize.height < boundsSize.height {
                newCenter.y = boundsSize.height / 2.0
            }

            containerView.center = newCenter
        }
    }
}

public struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = ZoomingScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.delegate = context.coordinator

        let containerView = UIView()
        containerView.backgroundColor = .clear
        scrollView.addSubview(containerView)
        scrollView.containerView = containerView
        context.coordinator.containerView = containerView

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(doubleTapGesture)

        context.coordinator.hostingController = hostingController
        return scrollView
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        if let zoomingScrollView = uiView as? ZoomingScrollView {
            zoomingScrollView.setNeedsLayout()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>?
        var containerView: UIView?

        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            containerView
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if (gestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer is UILongPressGestureRecognizer) ||
                (otherGestureRecognizer is UITapGestureRecognizer && gestureRecognizer is UILongPressGestureRecognizer) {
                return false
            }
            return true
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            if scrollView.zoomScale > 1.001 {
                feedback.impactOccurred()
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                feedback.impactOccurred()
                guard let containerView = containerView else { return }
                let location = gesture.location(in: containerView)
                let zoomWidth = scrollView.bounds.width / 2.0
                let zoomHeight = scrollView.bounds.height / 2.0
                let rect = CGRect(
                    x: location.x - (zoomWidth / 2.0),
                    y: location.y - (zoomHeight / 2.0),
                    width: zoomWidth,
                    height: zoomHeight
                )
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}
