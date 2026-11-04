//
//  AyahCardRenderer.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import SwiftUI
import UIKit

@MainActor
public enum AyahCardRenderer {
    public static func render<Content: View>(view: Content, targetWidth: CGFloat = 1000) -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            if let image = renderer.uiImage {
                return image
            }
        }

        // Fallback for iOS 15
        let hosting = UIHostingController(rootView: view)
        guard let targetView = hosting.view else { return nil }

        targetView.translatesAutoresizingMaskIntoConstraints = false
        let maxSize = CGSize(width: targetWidth, height: 10000)
        let fittingSize = targetView.sizeThatFits(maxSize)
        let finalSize = CGSize(width: targetWidth, height: ceil(fittingSize.height))

        targetView.bounds = CGRect(origin: .zero, size: finalSize)
        targetView.backgroundColor = .clear

        let window = UIWindow(frame: CGRect(origin: .zero, size: finalSize))
        window.addSubview(targetView)
        targetView.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: finalSize, format: format)
        let image = renderer.image { ctx in
            targetView.layer.render(in: ctx.cgContext)
        }

        targetView.removeFromSuperview()
        return image
    }

    public static func saveToTemporaryFile(image: UIImage, fileName: String = "kannada_quran_ayah.png") -> URL? {
        guard let data = image.pngData() else { return nil }
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
