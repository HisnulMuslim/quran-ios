//
//  AyahCardRenderer.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import CoreImage
import SwiftUI
import UIKit

@MainActor
public enum AyahCardRenderer {
    private static let sharedCIContext = CIContext()
    private static var qrCache: [String: UIImage] = [:]

    public static func render<Content: View>(
        view: Content,
        targetWidth: CGFloat = 1080,
        isOpaque: Bool = true
    ) -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            renderer.isOpaque = isOpaque
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
        format.opaque = isOpaque
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
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    public static func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        let cacheKey = "\(string)#\(Int(round(size)))"
        if let cached = qrCache[cacheKey] {
            return cached
        }
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage, outputImage.extent.size.width > 0 else {
            return nil
        }

        let scale = size / outputImage.extent.size.width
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = sharedCIContext.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        qrCache[cacheKey] = image
        return image
    }
}
