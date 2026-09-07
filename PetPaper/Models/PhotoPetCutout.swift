import SwiftUI
import UIKit

struct PhotoPetCutout: Identifiable {
    let id: UUID
    let original: UIImage
    var cutout: UIImage
    var instanceIndex: Int
    var shadowEnabled: Bool
    var edgeFeather: Double
    var tintAmount: Double

    init(
        id: UUID = UUID(),
        original: UIImage,
        cutout: UIImage,
        instanceIndex: Int,
        shadowEnabled: Bool = true,
        edgeFeather: Double = 0.35,
        tintAmount: Double = 0
    ) {
        self.id = id
        self.original = original
        self.cutout = cutout
        self.instanceIndex = instanceIndex
        self.shadowEnabled = shadowEnabled
        self.edgeFeather = edgeFeather
        self.tintAmount = tintAmount
    }
}

enum AnimalHint: String, Hashable {
    case cat
    case dog
    case subject

    var titleKey: String { "import.animal.\(rawValue)" }
}

struct SubjectCandidate: Identifiable {
    var id: Int { index }
    let index: Int
    let thumbnail: UIImage
    let cutout: UIImage
    let bounds: CGRect
    let animalHint: AnimalHint
}

enum SubjectLiftError: LocalizedError {
    case unsupportedImage
    case noSubject
    case visionFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            return String(localized: "import.failed.unsupported")
        case .noSubject:
            return String(localized: "import.failed.body")
        case .visionFailed:
            return String(localized: "import.failed.vision")
        }
    }
}
