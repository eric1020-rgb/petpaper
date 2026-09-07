import SwiftUI

struct PhotoPetView: View {
    let cutout: PhotoPetCutout

    var body: some View {
        Image(uiImage: cutout.cutout)
            .resizable()
            .scaledToFit()
            .shadow(
                color: cutout.shadowEnabled ? Color.black.opacity(0.38) : .clear,
                radius: cutout.shadowEnabled ? 14 : 0,
                y: cutout.shadowEnabled ? 9 : 0
            )
            .hueRotation(.degrees(cutout.tintAmount * 48))
            .saturation(1 + cutout.tintAmount * 0.12)
            .accessibilityHidden(true)
    }
}

struct PetLayerView: View {
    let character: PetCharacter
    var photoPet: PhotoPetCutout?
    var lookOffset: CGSize = .zero
    var lean: Double = 0

    var body: some View {
        if let photoPet {
            PhotoPetView(cutout: photoPet)
                .rotationEffect(.degrees(lean))
        } else {
            PetIllustration(character: character, lookOffset: lookOffset, lean: lean)
        }
    }
}
