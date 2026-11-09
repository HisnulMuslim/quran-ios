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
    public static func render<Content: View>(view: Content, targetWidth: CGFloat = 1080) -> UIImage? {
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

    public static func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scale = size / outputImage.extent.size.width
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
