import SwiftUI

struct IdleSettingsCard: View {
    @Environment(AppSession.self) private var session
    @Bindable var idle: PetIdleDirector
    var onPreview: () -> Void

    var body: some View {
        @Bindable var session = session
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "pawprint.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.lilac)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("idle.title")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("idle.subtitle")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            IdleMiniPreview(idle: idle)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle(isOn: $session.idleEnabled) {
                Text("idle.enabled")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppTheme.coral)
            .accessibilityHint(Text("a11y.idle.hint"))

            VStack(alignment: .leading, spacing: 6) {
                Text("idle.interval")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Picker(String(localized: "idle.interval"), selection: $session.idleInterval) {
                    ForEach(IdleInterval.allCases) { interval in
                        Text(LocalizedStringKey(interval.titleKey)).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel(Text("idle.interval"))
            }

            Toggle(isOn: $session.idleToastEnabled) {
                Text("idle.toast")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppTheme.coral)

            Button(action: onPreview) {
                Label(String(localized: "idle.preview"), systemImage: "play.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.coral)
            .accessibilityHint(Text("a11y.idle.preview"))

            Text("idle.wallpaperNote")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal, 20)
    }
}

struct IdleSettingsSheet: View {
    @Environment(AppSession.self) private var session
    var onPreview: () -> Void
    var onClose: () -> Void

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $session.idleEnabled) {
                        Text("idle.enabled")
                    }
                    .accessibilityHint(Text("a11y.idle.hint"))
                    Picker(String(localized: "idle.interval"), selection: $session.idleInterval) {
                        ForEach(IdleInterval.allCases) { interval in
                            Text(LocalizedStringKey(interval.titleKey)).tag(interval)
                        }
                    }
                    Toggle(isOn: $session.idleToastEnabled) {
                        Text("idle.toast")
                    }
                }

                Section {
                    Button(action: onPreview) {
                        Label(String(localized: "idle.preview"), systemImage: "play.circle.fill")
                    }
                    .accessibilityHint(Text("a11y.idle.preview"))
                }

                Section {
                    Text("idle.subtitle")
                    Text("idle.followPaused")
                    Text("idle.wallpaperNote")
                }
            }
            .navigationTitle(Text("idle.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "editor.text.done"), action: onClose)
                }
            }
        }
    }
}

struct IdleMiniPreview: View {
    @Bindable var idle: PetIdleDirector

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                TemplateSceneView(template: .pastel, palette: TemplateKind.pastel.defaultPalette)
                IdlePortalOverlay(progress: idle.pose.portalVisible, in: size)
                IdleSparkleOverlay(
                    amount: idle.pose.sparkleAmount,
                    in: size,
                    around: CGPoint(
                        x: (0.5 + idle.pose.positionDelta.x) * size.width,
                        y: (0.72 + idle.pose.positionDelta.y) * size.height
                    )
                )
                PetIllustration(
                    character: PetCharacter.character(id: "cat-calico"),
                    lookOffset: idle.pose.lookOffset,
                    lean: idle.pose.lean,
                    pose: idle.pose
                )
                .frame(width: 92, height: 104)
                .scaleEffect(idle.pose.extraScale * idle.pose.bodySquash)
                .rotationEffect(.degrees(idle.pose.extraRotation))
                .opacity(idle.pose.opacity)
                .position(
                    x: (0.5 + idle.pose.positionDelta.x) * size.width,
                    y: (0.72 + idle.pose.positionDelta.y) * size.height
                )

                if let key = idle.toastKey {
                    IdleToastBanner(key: key)
                        .padding(.top, 8)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct IdleToastBanner: View {
    var key: String

    var body: some View {
        Text(LocalizedStringKey(key))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(AppTheme.ink)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct IdlePortalOverlay: View {
    var progress: Double
    var size: CGSize

    init(progress: Double, in size: CGSize) {
        self.progress = progress
        self.size = size
    }

    var body: some View {
        let doorWidth = size.width * 0.2
        let doorHeight = size.height * 0.28
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.35, blue: 0.95),
                            Color(red: 0.35, green: 0.78, blue: 0.95),
                            Color(red: 0.95, green: 0.7, blue: 0.95)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 3)
                .padding(7)
            Image(systemName: "door.left.hand.open")
                .font(.system(size: min(doorWidth, 36), weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: doorWidth, height: doorHeight)
        .opacity(progress)
        .scaleEffect(0.82 + 0.18 * progress)
        .position(x: size.width * 0.9, y: size.height * 0.4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct IdleSparkleOverlay: View {
    var amount: Double
    var size: CGSize
    var around: CGPoint

    init(amount: Double, in size: CGSize, around: CGPoint) {
        self.amount = amount
        self.size = size
        self.around = around
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: amount < 0.04)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    let angle = Double(index) / 10 * .pi * 2 + t * 1.6
                    let radius = min(size.width, size.height) * (0.08 + 0.04 * sin(t * 3 + Double(index)))
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "sparkles")
                        .font(.system(size: 10 + CGFloat(index % 3) * 3))
                        .foregroundStyle(.white.opacity(0.95))
                        .scaleEffect(0.7 + 0.4 * sin(t * 5 + Double(index)))
                        .opacity(amount * (0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4 + Double(index)))))
                        .position(
                            x: around.x + CGFloat(cos(angle)) * radius,
                            y: around.y + CGFloat(sin(angle)) * radius * 0.85
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
