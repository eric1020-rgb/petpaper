import SwiftUI

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
    }

    private var chooseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("import.choose.title")
                .font(.title2.bold())
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
    }

    private var previewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("import.preview.title")
                    .font(.title2.bold())
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
                select(only, origin: .vision)
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

    private func select(_ candidate: SubjectCandidate, origin: PreviewOrigin = .vision) {
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
        select(candidate, origin: .manual)
    }

    private func confirm() {
        guard let previewImage else { return }
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

private struct CropHandleOverlay: View {
    @Binding var rect: CGRect
    @State private var startRect: CGRect?

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
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: pixel.width, height: pixel.height)
                    .position(x: pixel.midX, y: pixel.midY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if startRect == nil { startRect = rect }
                                guard let startRect else { return }
                                let dx = value.translation.width / geo.size.width
                                let dy = value.translation.height / geo.size.height
                                var next = startRect.offsetBy(dx: dx, dy: dy)
                                next.origin.x = min(max(next.origin.x, 0), 1 - next.width)
                                next.origin.y = min(max(next.origin.y, 0), 1 - next.height)
                                rect = next
                            }
                            .onEnded { _ in
                                startRect = nil
                            }
                    )
            }
        }
        .allowsHitTesting(true)
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
