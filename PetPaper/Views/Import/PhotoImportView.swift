import SwiftUI
import UIKit

struct PhotoImportView: View {
    @Environment(AppSession.self) private var session
    let original: UIImage

    @State private var phase: Phase = .processing
    @State private var candidates: [SubjectCandidate] = []
    @State private var selected: SubjectCandidate?
    @State private var previewImage: UIImage?
    @State private var errorMessage: String?
    @State private var edge: Double = 0.25
    @State private var shadowEnabled = true
    @State private var tintAmount = 0.0
    @State private var cropInset = 0.0
    @State private var template: TemplateKind = .pastel
    @State private var cropRect = CGRect(x: 0.12, y: 0.12, width: 0.76, height: 0.76)
    @State private var analyzeGeneration = 0
    @State private var previewOrigin: PreviewOrigin = .vision

    enum Phase {
        case processing
        case choose
        case preview
        case failed
        case manualCrop
    }

    private enum PreviewOrigin {
        case vision
        case manual
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .processing: processingView
                case .choose: chooseView
                case .preview: previewView
                case .failed: failedView
                case .manualCrop: manualCropView
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(Text("import.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsBackButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: "common.back")) {
                            goBack()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "import.cancel")) {
                        session.dismissPhotoImport()
                    }
                }
            }
        }
        .task { await analyze() }
        .onChange(of: phase) { _, newPhase in
            announcePhase(newPhase)
        }
    }

    private var processingView: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.coral)
            Text("import.processing")
                .font(.title3.weight(.semibold))
            Text("import.processing.privacy")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("import.processing"))
        .accessibilityValue(Text("import.processing.privacy"))
    }

    private var chooseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("import.choose.title")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("import.choose.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            GeometryReader { geo in
                let fitted = Self.aspectFit(original.size, in: geo.size)
                Image(uiImage: original)
                    .resizable()
                    .frame(width: fitted.width, height: fitted.height)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        GeometryReader { imageGeo in
                            ForEach(candidates) { candidate in
                                let rect = CGRect(
                                    x: candidate.bounds.minX * imageGeo.size.width,
                                    y: candidate.bounds.minY * imageGeo.size.height,
                                    width: max(candidate.bounds.width * imageGeo.size.width, 32),
                                    height: max(candidate.bounds.height * imageGeo.size.height, 32)
                                )
                                Button {
                                    select(candidate)
                                } label: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            selected?.index == candidate.index ? AppTheme.coral : Color.white.opacity(0.9),
                                            lineWidth: selected?.index == candidate.index ? 4 : 2
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(AppTheme.coral.opacity(selected?.index == candidate.index ? 0.16 : 0.05))
                                        )
                                }
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(candidates) { candidate in
                        Button {
                            select(candidate)
                        } label: {
                            VStack(spacing: 6) {
                                Image(uiImage: candidate.thumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .padding(6)
                                    .background(CheckerboardBackground())
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(LocalizedStringKey(candidate.animalHint.titleKey))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .padding(8)
                            .background(.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(selected?.index == candidate.index ? AppTheme.coral : Color.clear, lineWidth: 3)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Button(String(localized: "import.confirmSelection")) {
                if let selected {
                    select(selected)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.coral)
            .disabled(selected == nil)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("import.choose.title"))
    }

    private var previewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("import.preview.title")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("import.preview.body")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)

                ZStack {
                    CheckerboardBackground()
                    if let previewImage {
                        PhotoPetView(
                            cutout: PhotoPetCutout(
                                original: original,
                                cutout: previewImage,
                                instanceIndex: selected?.index ?? 0,
                                shadowEnabled: shadowEnabled,
                                edgeFeather: edge,
                                tintAmount: tintAmount
                            )
                        )
                        .padding(24)
                    }
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                refineControls
                templatePicker

                Button(String(localized: "import.confirm")) {
                    confirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.coral)
                .disabled(previewImage == nil)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("import.preview.title"))
    }

    private var refineControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            labeledSlider("import.refine.edge", value: $edge, range: -1...1)
            labeledSlider("import.refine.crop", value: $cropInset, range: 0...0.24)
            labeledSlider("import.refine.tint", value: $tintAmount, range: 0...1)
            Toggle(isOn: $shadowEnabled) {
                Text("import.refine.shadow")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppTheme.coral)
        }
        .onChange(of: edge) { _, _ in refreshPreview() }
        .onChange(of: cropInset) { _, _ in refreshPreview() }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("import.template")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TemplateKind.allCases) { item in
                        Button {
                            template = item
                        } label: {
                            TemplateSceneView(template: item, palette: item.defaultPalette)
                                .frame(width: 64, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(item == template ? AppTheme.coral : Color.clear, lineWidth: 3)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var failedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pawprint.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.coral)
            Text("import.failed.title")
                .font(.title2.bold())
            Text(errorMessage ?? String(localized: "import.failed.body"))
                .font(.body)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Text("import.failed.tips")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            VStack(spacing: 10) {
                Button(String(localized: "import.manual")) {
                    phase = .manualCrop
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.coral)
                Button(String(localized: "import.retry")) {
                    Task { await analyze() }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("import.failed.title"))
    }

    private var manualCropView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("import.manual.title")
                .font(.title2.bold())
            Text("import.manual.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            GeometryReader { geo in
                let fitted = Self.aspectFit(original.size, in: geo.size)
                Image(uiImage: original)
                    .resizable()
                    .frame(width: fitted.width, height: fitted.height)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        CropHandleOverlay(rect: $cropRect)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            Button(String(localized: "import.confirmSelection")) {
                applyManualCrop()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.coral)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
    }

    private func labeledSlider(_ key: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(key))
                .font(.subheadline.weight(.semibold))
            Slider(value: value, in: range)
                .tint(AppTheme.coral)
        }
    }

    private var showsBackButton: Bool {
        switch phase {
        case .preview:
            return previewOrigin == .manual || candidates.count > 1
        case .manualCrop:
            return true
        case .processing, .choose, .failed:
            return false
        }
    }

    private func goBack() {
        switch phase {
        case .preview where previewOrigin == .manual:
            phase = .manualCrop
        case .preview where candidates.count > 1:
            phase = .choose
        case .manualCrop:
            phase = .failed
        default:
            break
        }
    }

    private func analyze() async {
        analyzeGeneration += 1
        let generation = analyzeGeneration
        phase = .processing
        errorMessage = nil
        do {
            let found = try await SubjectLiftService.extract(from: original)
            guard generation == analyzeGeneration, !Task.isCancelled else { return }
            candidates = found
            if found.count > 1 {
                selected = found.first
                phase = .choose
            } else if let only = found.first {
                select(only, origin: .vision, playHaptic: false)
            } else {
                errorMessage = String(localized: "import.failed.body")
                phase = .failed
            }
        } catch is CancellationError {
            return
        } catch {
            guard generation == analyzeGeneration, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            phase = .failed
        }
    }

    private func select(_ candidate: SubjectCandidate, origin: PreviewOrigin = .vision, playHaptic: Bool = true) {
        if playHaptic {
            AppHaptics.light()
        }
        selected = candidate
        previewOrigin = origin
        refreshPreview(using: candidate.cutout)
        phase = .preview
    }

    private func refreshPreview(using source: UIImage? = nil) {
        let base = source ?? selected?.cutout
        guard let base else { return }
        previewImage = ImageProcessing.refine(cutout: base, edge: edge, cropInset: cropInset)
    }

    private func applyManualCrop() {
        AppHaptics.light()
        let cropped = ImageProcessing.crop(ImageProcessing.normalized(original), normalizedRect: cropRect)
        let cutout = ImageProcessing.ellipticalCutout(from: cropped)
        let candidate = SubjectCandidate(
            index: 0,
            thumbnail: cutout,
            cutout: cutout,
            bounds: cropRect,
            animalHint: .subject
        )
        candidates = [candidate]
        select(candidate, origin: .manual, playHaptic: false)
    }

    private func confirm() {
        guard let previewImage else { return }
        AppHaptics.light()
        let cutout = PhotoPetCutout(
            original: original,
            cutout: previewImage,
            instanceIndex: selected?.index ?? 0,
            shadowEnabled: shadowEnabled,
            edgeFeather: edge,
            tintAmount: tintAmount
        )
        session.finishPhotoImport(cutout: cutout, template: template)
    }

    private static func aspectFit(_ size: CGSize, in container: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return container }
        let scale = min(container.width / size.width, container.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private func announcePhase(_ phase: Phase) {
        let message: String
        switch phase {
        case .processing: message = String(localized: "import.processing")
        case .choose: message = String(localized: "import.choose.title")
        case .preview: message = String(localized: "import.preview.title")
        case .failed: message = String(localized: "import.failed.title")
        case .manualCrop: message = String(localized: "import.manual.title")
        }
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
}

private struct CheckerboardBackground: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 14
            let cols = Int(ceil(size.width / cell))
            let rows = Int(ceil(size.height / cell))
            for row in 0..<rows {
                for col in 0..<cols {
                    let light = (row + col).isMultiple(of: 2)
                    let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(light ? Color.white : Color(white: 0.9)))
                }
            }
        }
    }
}

private enum CropHandle: String, CaseIterable, Identifiable {
    case north, south, east, west
    case northWest, northEast, southWest, southEast

    var id: String { rawValue }

    var isCorner: Bool {
        switch self {
        case .northWest, .northEast, .southWest, .southEast: return true
        default: return false
        }
    }
}

private struct CropHandleOverlay: View {
    @Binding var rect: CGRect
    @State private var startRect: CGRect?
    @State private var pinchStart: CGRect?

    private let minSize: CGFloat = 0.14

    var body: some View {
        GeometryReader { geo in
            let pixel = CGRect(
                x: rect.minX * geo.size.width,
                y: rect.minY * geo.size.height,
                width: rect.width * geo.size.width,
                height: rect.height * geo.size.height
            )
            ZStack {
                Color.black.opacity(0.32)
                    .reverseMask {
                        Rectangle()
                            .frame(width: pixel.width, height: pixel.height)
                            .position(x: pixel.midX, y: pixel.midY)
                    }
                    .allowsHitTesting(false)

                Rectangle()
                    .fill(Color.white.opacity(0.01))
                    .frame(width: max(pixel.width - 28, 8), height: max(pixel.height - 28, 8))
                    .position(x: pixel.midX, y: pixel.midY)
                    .gesture(moveGesture(in: geo.size))
                    .accessibilityLabel(Text("a11y.crop.move"))

                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: pixel.width, height: pixel.height)
                    .position(x: pixel.midX, y: pixel.midY)
                    .allowsHitTesting(false)

                ForEach(CropHandle.allCases) { handle in
                    handleKnob(handle, pixel: pixel, canvas: geo.size)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(pinchGesture)
        }
        .allowsHitTesting(true)
    }

    private func handleKnob(_ handle: CropHandle, pixel: CGRect, canvas: CGSize) -> some View {
        let point = position(for: handle, in: pixel)
        return Capsule()
            .fill(Color.white)
            .overlay {
                Capsule().strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
            }
            .frame(
                width: handle.isCorner ? 22 : (isHorizontal(handle) ? 34 : 18),
                height: handle.isCorner ? 22 : (isHorizontal(handle) ? 18 : 34)
            )
            .position(x: point.x, y: point.y)
            .gesture(resizeGesture(handle, in: canvas))
            .accessibilityLabel(Text("a11y.crop.resize"))
    }

    private func isHorizontal(_ handle: CropHandle) -> Bool {
        handle == .north || handle == .south
    }

    private func position(for handle: CropHandle, in pixel: CGRect) -> CGPoint {
        switch handle {
        case .northWest: return CGPoint(x: pixel.minX, y: pixel.minY)
        case .north: return CGPoint(x: pixel.midX, y: pixel.minY)
        case .northEast: return CGPoint(x: pixel.maxX, y: pixel.minY)
        case .west: return CGPoint(x: pixel.minX, y: pixel.midY)
        case .east: return CGPoint(x: pixel.maxX, y: pixel.midY)
        case .southWest: return CGPoint(x: pixel.minX, y: pixel.maxY)
        case .south: return CGPoint(x: pixel.midX, y: pixel.maxY)
        case .southEast: return CGPoint(x: pixel.maxX, y: pixel.maxY)
        }
    }

    private func moveGesture(in canvas: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == nil { startRect = rect }
                guard let startRect else { return }
                let dx = value.translation.width / canvas.width
                let dy = value.translation.height / canvas.height
                rect = clampedMove(
                    CGRect(
                        x: startRect.origin.x + dx,
                        y: startRect.origin.y + dy,
                        width: startRect.width,
                        height: startRect.height
                    )
                )
            }
            .onEnded { _ in
                startRect = nil
            }
    }

    private func resizeGesture(_ handle: CropHandle, in canvas: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if startRect == nil { startRect = rect }
                guard let startRect else { return }
                let dx = value.translation.width / canvas.width
                let dy = value.translation.height / canvas.height
                rect = resized(startRect, handle: handle, dx: dx, dy: dy)
            }
            .onEnded { _ in
                startRect = nil
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                if pinchStart == nil { pinchStart = rect }
                guard let pinchStart else { return }
                let width = pinchStart.width * scale
                let height = pinchStart.height * scale
                rect = clampedPinch(
                    CGRect(
                        x: pinchStart.midX - width / 2,
                        y: pinchStart.midY - height / 2,
                        width: width,
                        height: height
                    )
                )
            }
            .onEnded { _ in
                pinchStart = nil
            }
    }

    private func resized(_ start: CGRect, handle: CropHandle, dx: CGFloat, dy: CGFloat) -> CGRect {
        var minX = start.minX
        var minY = start.minY
        var maxX = start.maxX
        var maxY = start.maxY

        switch handle {
        case .northWest:
            minX += dx
            minY += dy
        case .north:
            minY += dy
        case .northEast:
            maxX += dx
            minY += dy
        case .west:
            minX += dx
        case .east:
            maxX += dx
        case .southWest:
            minX += dx
            maxY += dy
        case .south:
            maxY += dy
        case .southEast:
            maxX += dx
            maxY += dy
        }

        if maxX - minX < minSize {
            switch handle {
            case .west, .northWest, .southWest:
                minX = maxX - minSize
            default:
                maxX = minX + minSize
            }
        }
        if maxY - minY < minSize {
            switch handle {
            case .north, .northWest, .northEast:
                minY = maxY - minSize
            default:
                maxY = minY + minSize
            }
        }

        return clampedResize(CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
    }

    private func clampedMove(_ raw: CGRect) -> CGRect {
        let width = min(max(raw.width, minSize), 1)
        let height = min(max(raw.height, minSize), 1)
        let x = min(max(raw.origin.x, 0), 1 - width)
        let y = min(max(raw.origin.y, 0), 1 - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func clampedPinch(_ raw: CGRect) -> CGRect {
        let width = min(max(raw.width, minSize), 1)
        let height = min(max(raw.height, minSize), 1)
        let x = min(max(raw.midX - width / 2, 0), 1 - width)
        let y = min(max(raw.midY - height / 2, 0), 1 - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func clampedResize(_ raw: CGRect) -> CGRect {
        var minX = max(min(raw.minX, raw.maxX), 0)
        var minY = max(min(raw.minY, raw.maxY), 0)
        var maxX = min(max(raw.minX, raw.maxX), 1)
        var maxY = min(max(raw.minY, raw.maxY), 1)
        if maxX - minX < minSize {
            if minX <= 0 {
                maxX = min(minSize, 1)
                minX = 0
            } else if maxX >= 1 {
                minX = max(0, 1 - minSize)
                maxX = 1
            } else {
                minX = max(0, maxX - minSize)
            }
        }
        if maxY - minY < minSize {
            if minY <= 0 {
                maxY = min(minSize, 1)
                minY = 0
            } else if maxY >= 1 {
                minY = max(0, 1 - minSize)
                maxY = 1
            } else {
                minY = max(0, maxY - minSize)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle().fill(.white)
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}
