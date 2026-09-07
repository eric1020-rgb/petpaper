import UIKit
import ImageIO
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageProcessing {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Longest edge for picker decode, Vision, and stored `PhotoPetCutout.original`.
    /// Wallpaper export is 1290×2796; the pet is typically ~700px and at most ~1800px.
    static let workingMaxDimension: CGFloat = 1920

    /// Longest edge for the lifted cutout kept in memory after confirm.
    static let storedCutoutMaxDimension: CGFloat = 1920

    /// Decodes picker bytes (JPEG / PNG / HEIC) via ImageIO thumbnails so 48MP / panos
    /// never land in RAM at full size. Falls back to `UIImage(data:)` + constrain.
    static func uiImage(fromPhotoData data: Data) -> UIImage? {
        if let downsampled = downsampled(from: data, maxPixelSize: workingMaxDimension) {
            return downsampled
        }
        if let image = UIImage(data: data) {
            return preparedForImport(image)
        }
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldAllowFloat: true
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        let orientation = imageOrientation(from: source)
        return preparedForImport(UIImage(cgImage: cgImage, scale: 1, orientation: orientation))
    }

    /// Thumbnail decode that applies EXIF orientation (`CreateThumbnailWithTransform`).
    static func downsampled(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary),
              CGImageSourceGetCount(source) > 0 else {
            return nil
        }
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private static func imageOrientation(from source: CGImageSource) -> UIImage.Orientation {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let raw = properties[kCGImagePropertyOrientation] as? UInt32,
              let cgOrientation = CGImagePropertyOrientation(rawValue: raw) else {
            return .up
        }
        switch cgOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    static func normalized(_ image: UIImage) -> UIImage {
        let pixelSize = orientedPixelSize(of: image)
        if image.imageOrientation == .up, abs(image.scale - 1) < 0.01 {
            return image
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }

    /// Orientation-fixed and capped for the import / cutout pipeline.
    static func preparedForImport(_ image: UIImage) -> UIImage {
        constrained(normalized(image), maxDimension: workingMaxDimension)
    }

    static func preparedCutout(_ image: UIImage) -> UIImage {
        constrained(image, maxDimension: storedCutoutMaxDimension)
    }

    static func constrained(_ image: UIImage, maxDimension: CGFloat = workingMaxDimension) -> UIImage {
        let pixels = orientedPixelSize(of: image)
        let longest = max(pixels.width, pixels.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(
            width: max((pixels.width * scale).rounded(.down), 1),
            height: max((pixels.height * scale).rounded(.down), 1)
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private static func orientedPixelSize(of image: UIImage) -> CGSize {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }
        return CGSize(
            width: max(image.size.width * image.scale, 1),
            height: max(image.size.height * image.scale, 1)
        )
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
        guard let cgImage = image.cgImage else { return image }
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        let rect = CGRect(
            x: normalizedRect.minX * pixelWidth,
            y: normalizedRect.minY * pixelHeight,
            width: max(normalizedRect.width * pixelWidth, 8),
            height: max(normalizedRect.height * pixelHeight, 8)
        ).integral
        guard let cropped = cgImage.cropping(to: rect) else {
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
