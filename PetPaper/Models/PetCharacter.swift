import SwiftUI

enum PetSpecies: String, CaseIterable, Identifiable, Hashable {
    case cat
    case dog

    var id: String { rawValue }
    var titleKey: String { "species.\(rawValue)" }
}

enum EarStyle: String, Hashable {
    case triangle
    case rounded
    case floppy
}

enum TailStyle: String, Hashable {
    case longCurve
    case short
    case fluffy
    case curled
}

enum PatternStyle: String, Hashable {
    case solid
    case stripes
    case spots
    case tuxedo
    case calico
    case huskyMask
    case siamese
    case saddle
}

struct PetCharacter: Identifiable, Hashable {
    let id: String
    let species: PetSpecies
    let nameKey: String
    let ear: EarStyle
    let tail: TailStyle
    let pattern: PatternStyle
    let body: RGBAColor
    let secondary: RGBAColor
    let tertiary: RGBAColor
    let belly: RGBAColor
    let eye: RGBAColor
    let nose: RGBAColor
    let innerEar: RGBAColor
    let legLength: Double
    let bodyWidth: Double
    let headScale: Double
    let snoutLength: Double

    static let catalog: [PetCharacter] = [
        PetCharacter(
            id: "cat-tabby",
            species: .cat,
            nameKey: "pet.cat.tabby",
            ear: .triangle,
            tail: .longCurve,
            pattern: .stripes,
            body: .hex(0xE89A4A),
            secondary: .hex(0xC46A28),
            tertiary: .hex(0x5C3A21),
            belly: .hex(0xF8E1C4),
            eye: .hex(0x3D7A3A),
            nose: .hex(0xE3899B),
            innerEar: .hex(0xF4B6C3),
            legLength: 0.55,
            bodyWidth: 0.86,
            headScale: 1.05,
            snoutLength: 0.22
        ),
        PetCharacter(
            id: "cat-calico",
            species: .cat,
            nameKey: "pet.cat.calico",
            ear: .triangle,
            tail: .longCurve,
            pattern: .calico,
            body: .hex(0xF4EFE6),
            secondary: .hex(0xE07A3D),
            tertiary: .hex(0x2B2B2B),
            belly: .hex(0xFFF9F1),
            eye: .hex(0xC9A227),
            nose: .hex(0xE3899B),
            innerEar: .hex(0xF4B6C3),
            legLength: 0.52,
            bodyWidth: 0.9,
            headScale: 1.08,
            snoutLength: 0.2
        ),
        PetCharacter(
            id: "cat-tuxedo",
            species: .cat,
            nameKey: "pet.cat.tuxedo",
            ear: .triangle,
            tail: .longCurve,
            pattern: .tuxedo,
            body: .hex(0x1C1C1C),
            secondary: .hex(0xF5F5F5),
            tertiary: .hex(0x111111),
            belly: .hex(0xFFFFFF),
            eye: .hex(0x3AA0C8),
            nose: .hex(0xF2A0B0),
            innerEar: .hex(0xF4B6C3),
            legLength: 0.58,
            bodyWidth: 0.84,
            headScale: 1.02,
            snoutLength: 0.2
        ),
        PetCharacter(
            id: "cat-siamese",
            species: .cat,
            nameKey: "pet.cat.siamese",
            ear: .triangle,
            tail: .longCurve,
            pattern: .siamese,
            body: .hex(0xF3E6D0),
            secondary: .hex(0x6B4A32),
            tertiary: .hex(0x4A3224),
            belly: .hex(0xFFF6EA),
            eye: .hex(0x3B6FD4),
            nose: .hex(0xC97B8A),
            innerEar: .hex(0xE7B3A0),
            legLength: 0.62,
            bodyWidth: 0.78,
            headScale: 0.98,
            snoutLength: 0.28
        ),
        PetCharacter(
            id: "cat-grey",
            species: .cat,
            nameKey: "pet.cat.grey",
            ear: .rounded,
            tail: .fluffy,
            pattern: .solid,
            body: .hex(0xA9B1BA),
            secondary: .hex(0x7E8791),
            tertiary: .hex(0x5C646C),
            belly: .hex(0xE6EAEF),
            eye: .hex(0x8BC34A),
            nose: .hex(0xD9899A),
            innerEar: .hex(0xE9C0C8),
            legLength: 0.48,
            bodyWidth: 0.92,
            headScale: 1.12,
            snoutLength: 0.18
        ),
        PetCharacter(
            id: "cat-white",
            species: .cat,
            nameKey: "pet.cat.white",
            ear: .rounded,
            tail: .longCurve,
            pattern: .solid,
            body: .hex(0xFFF8F2),
            secondary: .hex(0xF0D9C8),
            tertiary: .hex(0xE4C7B2),
            belly: .hex(0xFFFFFF),
            eye: .hex(0x7A4CC8),
            nose: .hex(0xF09AA8),
            innerEar: .hex(0xF7C2CE),
            legLength: 0.5,
            bodyWidth: 0.88,
            headScale: 1.1,
            snoutLength: 0.18
        ),
        PetCharacter(
            id: "dog-golden",
            species: .dog,
            nameKey: "pet.dog.golden",
            ear: .floppy,
            tail: .fluffy,
            pattern: .solid,
            body: .hex(0xE8B05A),
            secondary: .hex(0xC78A32),
            tertiary: .hex(0xA66B1E),
            belly: .hex(0xF8E0B0),
            eye: .hex(0x4A3218),
            nose: .hex(0x2B2B2B),
            innerEar: .hex(0xD9A06A),
            legLength: 0.7,
            bodyWidth: 0.95,
            headScale: 1.0,
            snoutLength: 0.42
        ),
        PetCharacter(
            id: "dog-corgi",
            species: .dog,
            nameKey: "pet.dog.corgi",
            ear: .triangle,
            tail: .short,
            pattern: .saddle,
            body: .hex(0xE79A3C),
            secondary: .hex(0xF4EFE6),
            tertiary: .hex(0x3A2A1C),
            belly: .hex(0xFFF6EA),
            eye: .hex(0x3A2A1C),
            nose: .hex(0x222222),
            innerEar: .hex(0xE8B48A),
            legLength: 0.28,
            bodyWidth: 1.08,
            headScale: 1.08,
            snoutLength: 0.32
        ),
        PetCharacter(
            id: "dog-husky",
            species: .dog,
            nameKey: "pet.dog.husky",
            ear: .triangle,
            tail: .fluffy,
            pattern: .huskyMask,
            body: .hex(0xE8EEF4),
            secondary: .hex(0x6B7580),
            tertiary: .hex(0x2E343B),
            belly: .hex(0xFFFFFF),
            eye: .hex(0x3AA0C8),
            nose: .hex(0x222222),
            innerEar: .hex(0xE8B8B0),
            legLength: 0.78,
            bodyWidth: 0.88,
            headScale: 0.96,
            snoutLength: 0.38
        ),
        PetCharacter(
            id: "dog-dalmatian",
            species: .dog,
            nameKey: "pet.dog.dalmatian",
            ear: .floppy,
            tail: .longCurve,
            pattern: .spots,
            body: .hex(0xF7F4EF),
            secondary: .hex(0x1A1A1A),
            tertiary: .hex(0x111111),
            belly: .hex(0xFFFFFF),
            eye: .hex(0x3A2A1C),
            nose: .hex(0x222222),
            innerEar: .hex(0xE8B8B0),
            legLength: 0.82,
            bodyWidth: 0.82,
            headScale: 0.94,
            snoutLength: 0.4
        ),
        PetCharacter(
            id: "dog-shiba",
            species: .dog,
            nameKey: "pet.dog.shiba",
            ear: .triangle,
            tail: .curled,
            pattern: .saddle,
            body: .hex(0xE07A3D),
            secondary: .hex(0xF7F1E8),
            tertiary: .hex(0x3A2A1C),
            belly: .hex(0xFFF8F0),
            eye: .hex(0x3A2A1C),
            nose: .hex(0x222222),
            innerEar: .hex(0xE8B48A),
            legLength: 0.62,
            bodyWidth: 0.9,
            headScale: 1.02,
            snoutLength: 0.3
        ),
        PetCharacter(
            id: "dog-black",
            species: .dog,
            nameKey: "pet.dog.black",
            ear: .floppy,
            tail: .longCurve,
            pattern: .solid,
            body: .hex(0x2A2A2E),
            secondary: .hex(0x1A1A1E),
            tertiary: .hex(0x111114),
            belly: .hex(0x4A4A52),
            eye: .hex(0xC9A227),
            nose: .hex(0x111111),
            innerEar: .hex(0xC9897A),
            legLength: 0.68,
            bodyWidth: 0.92,
            headScale: 1.0,
            snoutLength: 0.36
        )
    ]

    /// Illustrated pet available after a trial expires without Plus.
    static let freePetID = "cat-tabby"
    static let freeIDs: Set<String> = [freePetID]

    static func isFree(_ id: String) -> Bool {
        freeIDs.contains(id)
    }

    static func character(id: String) -> PetCharacter {
        catalog.first(where: { $0.id == id }) ?? catalog[0]
    }

    static func resolvedID(_ petID: String?, hasPlusAccess: Bool) -> String {
        let candidate: String
        if let petID, catalog.contains(where: { $0.id == petID }) {
            candidate = petID
        } else {
            candidate = freePetID
        }
        if hasPlusAccess || isFree(candidate) {
            return candidate
        }
        return freePetID
    }
}
