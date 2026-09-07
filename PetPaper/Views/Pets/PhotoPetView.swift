import SwiftUI
import UIKit

struct PhotoPetView: View {
    let cutout: PhotoPetCutout

    var body: some View {
        Canvas { context, size in
            let image = context.resolve(Image(uiImage: cutout.cutout))
            let imageSize = image.size
            guard imageSize.width > 0, imageSize.height > 0, size.width > 0, size.height > 0 else { return }
            let scale = min(size.width / imageSize.width, size.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            let rect = CGRect(
                x: (size.width - width) / 2,
                y: (size.height - height) / 2,
                width: width,
                height: height
            )
            if cutout.shadowEnabled {
                var shadowed = context
                shadowed.addFilter(.shadow(color: .black.opacity(0.38), radius: 14, x: 0, y: 9))
                shadowed.draw(image, in: rect)
            } else {
                context.draw(image, in: rect)
            }
        }
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
    var pose: IdlePose = .rest

    var body: some View {
        if let photoPet {
            PhotoPetView(cutout: photoPet)
                .rotationEffect(.degrees(lean + pose.lean))
                .scaleEffect(x: 1, y: pose.bodySquash)
        } else {
            PetIllustration(character: character, lookOffset: lookOffset, lean: lean, pose: pose)
        }
    }
}
