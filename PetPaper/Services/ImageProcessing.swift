import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageProcessing {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    static func normalized(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let size = image.size
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func constrained(_ image: UIImage, maxDimension: CGFloat = 2048) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func uiImage(from buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        return uiImage(from: ciImage)
    }

    static func uiImage(from ciImage: CIImage) -> UIImage? {
        let extent = ciImage.extent.integral
        guard !extent.isEmpty,
              let cgImage = ciContext.createCGImage(ciImage, from: extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    static func crop(_ image: UIImage, normalizedRect: CGRect) -> UIImage {
        let rect = CGRect(
            x: normalizedRect.minX * image.size.width,
            y: normalizedRect.minY * image.size.height,
            width: max(normalizedRect.width * image.size.width, 8),
            height: max(normalizedRect.height * image.size.height, 8)
        ).integral
        guard let cgImage = image.cgImage,
              let cropped = cgImage.cropping(to: rect) else {
            return image
        }
        return UIImage(cgImage: cropped, scale: 1, orientation: .up)
    }

    /// Soft elliptical cutout used when Vision finds no subject.
    static func ellipticalCutout(from image: UIImage, inset: CGFloat = 0.04) -> UIImage {
        let size = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(
                dx: size.width * inset,
                dy: size.height * inset
            )
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func refine(cutout: UIImage, edge: Double, cropInset: Double) -> UIImage {
        var working = cutout
        if cropInset > 0.01 {
            let inset = min(max(cropInset, 0), 0.28)
            working = crop(working, normalizedRect: CGRect(x: inset, y: inset, width: 1 - inset * 2, height: 1 - inset * 2))
        }
        guard abs(edge) > 0.02, let ciImage = CIImage(image: working) else { return working }

        let output: CIImage
        if edge > 0 {
            let radius = CGFloat(edge) * 8
            output = ciImage
                .clampedToExtent()
                .applyingGaussianBlur(sigma: radius)
                .cropped(to: ciImage.extent)
        } else {
            let radius = Float(abs(edge) * 6)
            let filter = CIFilter.morphologyMinimum()
            filter.inputImage = ciImage
            filter.radius = radius
            output = filter.outputImage?.cropped(to: ciImage.extent) ?? ciImage
        }
        return uiImage(from: output) ?? working
    }
}
