import UIKit
import Vision
import CoreImage

enum SubjectLiftService {
    static func extract(from source: UIImage) async throws -> [SubjectCandidate] {
        let prepared = ImageProcessing.constrained(ImageProcessing.normalized(source), maxDimension: 2048)
        guard prepared.cgImage != nil else { throw SubjectLiftError.unsupportedImage }

        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            let box = ResumeBox(continuation)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try runVision(on: prepared)
                    box.resume(returning: result)
                } catch {
                    box.resume(throwing: error)
                }
            }
        }
    }

    private static func runVision(on image: UIImage) throws -> [SubjectCandidate] {
        guard let cgImage = image.cgImage else { throw SubjectLiftError.unsupportedImage }

        if #available(iOS 17.0, *) {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let maskRequest = VNGenerateForegroundInstanceMaskRequest()
            let animalRequest = VNRecognizeAnimalsRequest()

            do {
                try handler.perform([maskRequest])
            } catch {
                throw SubjectLiftError.visionFailed
            }
            try? handler.perform([animalRequest])

            let animalBoxes = animalObservations(from: animalRequest)
            if let observation = maskRequest.results?.first {
                let candidates = try candidates(
                    from: observation,
                    handler: handler,
                    imageSize: CGSize(width: cgImage.width, height: cgImage.height),
                    animals: animalBoxes
                )
                if !candidates.isEmpty {
                    return candidates
                }
            }
        }

        throw SubjectLiftError.noSubject
    }

    @available(iOS 17.0, *)
    private static func candidates(
        from observation: VNInstanceMaskObservation,
        handler: VNImageRequestHandler,
        imageSize: CGSize,
        animals: [(hint: AnimalHint, box: CGRect)]
    ) throws -> [SubjectCandidate] {
        let instances = observation.allInstances
        guard !instances.isEmpty else { return [] }

        let boundsMap = instanceBounds(in: observation.instanceMask)
        var results: [SubjectCandidate] = []

        for index in instances {
            do {
                let buffer = try observation.generateMaskedImage(
                    ofInstances: IndexSet(integer: index),
                    from: handler,
                    croppedToInstancesExtent: true
                )
                guard let cutout = ImageProcessing.uiImage(from: buffer) else { continue }
                guard cutout.size.width >= 36, cutout.size.height >= 36 else { continue }

                let bounds = boundsMap[index].map { maskRect in
                    normalize(maskRect, mask: observation.instanceMask)
                } ?? CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)

                let hint = animals.first(where: { $0.box.intersects(bounds) })?.hint ?? .subject
                let thumbnail = scaled(cutout, maxSide: 180)
                results.append(
                    SubjectCandidate(
                        index: index,
                        thumbnail: thumbnail,
                        cutout: cutout,
                        bounds: bounds,
                        animalHint: hint
                    )
                )
            } catch {
                continue
            }
        }

        results.sort { lhs, rhs in
            let rank: (AnimalHint) -> Int = { hint in
                switch hint {
                case .cat, .dog: return 0
                case .subject: return 1
                }
            }
            if rank(lhs.animalHint) != rank(rhs.animalHint) {
                return rank(lhs.animalHint) < rank(rhs.animalHint)
            }
            return (lhs.bounds.width * lhs.bounds.height) > (rhs.bounds.width * rhs.bounds.height)
        }
        return results
    }

    private static func animalObservations(from request: VNRecognizeAnimalsRequest) -> [(hint: AnimalHint, box: CGRect)] {
        guard let results = request.results else { return [] }
        return results.compactMap { observation in
            let labels = observation.labels.map { $0.identifier.lowercased() }
            let hint: AnimalHint?
            if labels.contains(where: { $0.contains("cat") }) {
                hint = .cat
            } else if labels.contains(where: { $0.contains("dog") }) {
                hint = .dog
            } else {
                hint = nil
            }
            guard let hint else { return nil }
            return (hint, visionToUIKit(observation.boundingBox))
        }
    }

    private static func visionToUIKit(_ box: CGRect) -> CGRect {
        CGRect(x: box.minX, y: 1 - box.minY - box.height, width: box.width, height: box.height)
    }

    private static func instanceBounds(in mask: CVPixelBuffer) -> [Int: CGRect] {
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        let bytesPerPixel = max(bytesPerRow / max(width, 1), 1)
        guard let base = CVPixelBufferGetBaseAddress(mask) else { return [:] }

        var minX: [Int: Int] = [:]
        var minY: [Int: Int] = [:]
        var maxX: [Int: Int] = [:]
        var maxY: [Int: Int] = [:]

        for y in 0..<height {
            let row = base.advanced(by: y * bytesPerRow)
            for x in 0..<width {
                let value = Int(row.load(fromByteOffset: x * bytesPerPixel, as: UInt8.self))
                guard value > 0 else { continue }
                minX[value] = min(minX[value] ?? x, x)
                maxX[value] = max(maxX[value] ?? x, x)
                minY[value] = min(minY[value] ?? y, y)
                maxY[value] = max(maxY[value] ?? y, y)
            }
        }

        var result: [Int: CGRect] = [:]
        for key in minX.keys {
            guard let x0 = minX[key], let x1 = maxX[key], let y0 = minY[key], let y1 = maxY[key] else { continue }
            result[key] = CGRect(x: x0, y: y0, width: max(x1 - x0, 1), height: max(y1 - y0, 1))
        }
        return result
    }

    private static func normalize(_ rect: CGRect, mask: CVPixelBuffer) -> CGRect {
        let width = CGFloat(CVPixelBufferGetWidth(mask))
        let height = CGFloat(CVPixelBufferGetHeight(mask))
        guard width > 0, height > 0 else { return .zero }
        return CGRect(
            x: rect.minX / width,
            y: rect.minY / height,
            width: rect.width / width,
            height: rect.height / height
        )
    }

    private static func scaled(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        ImageProcessing.constrained(image, maxDimension: maxSide)
    }
}

/// Resumes a continuation at most once so cancel + Vision completion cannot crash.
private final class ResumeBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }

    func resume(throwing error: Error) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(throwing: error)
    }
}
