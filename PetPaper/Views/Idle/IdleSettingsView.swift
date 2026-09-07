import SwiftUI

enum PlusIdleControls {
    static func enabledBinding(session: AppSession, subscriptions: SubscriptionManager) -> Binding<Bool> {
        Binding(
            get: { session.idleEnabled && subscriptions.canUsePremiumMotion() },
            set: { newValue in
                if newValue {
                    if subscriptions.requestPremiumMotion() {
                        session.idleEnabled = true
                    }
                } else {
                    session.idleEnabled = false
                }
            }
        )
    }
}

struct IdleSettingsCard: View {
    @Environment(AppSession.self) private var session
    @Environment(SubscriptionManager.self) private var subscriptions
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
                    Text(LocalizedStringKey(subscriptions.canUsePremiumMotion() ? "idle.subtitle" : "idle.locked"))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if !subscriptions.canUsePremiumMotion() {
                    PlusLockBadge()
                }
            }

            IdleMiniPreview(idle: idle)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle(isOn: PlusIdleControls.enabledBinding(session: session, subscriptions: subscriptions)) {
                Text("idle.enabled")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppTheme.coral)
            .accessibilityHint(Text(subscriptions.canUsePremiumMotion() ? "a11y.idle.hint" : "a11y.plus.locked"))

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
            .accessibilityHint(Text(subscriptions.canUsePremiumMotion() ? "a11y.idle.preview" : "a11y.plus.locked"))

            VStack(alignment: .leading, spacing: 6) {
                Text("widget.install.title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text("widget.install.steps")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("idle.wallpaperNote")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("widget.install.limitation")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("idle.uninstallNote")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
    @Environment(SubscriptionManager.self) private var subscriptions
    var onPreview: () -> Void
    var onClose: () -> Void

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            Form {
                if !subscriptions.canUsePremiumMotion() {
                    Section {
                        Text("idle.locked")
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                Section {
                    Toggle(isOn: PlusIdleControls.enabledBinding(session: session, subscriptions: subscriptions)) {
                        Text("idle.enabled")
                    }
                    .accessibilityHint(Text(subscriptions.canUsePremiumMotion() ? "a11y.idle.hint" : "a11y.plus.locked"))
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
                    .accessibilityHint(Text(subscriptions.canUsePremiumMotion() ? "a11y.idle.preview" : "a11y.plus.locked"))
                }

                Section {
                    Text("idle.subtitle")
                    Text("idle.followPaused")
                    Text("widget.install.steps")
                    Text("idle.wallpaperNote")
                    Text("widget.install.limitation")
                    Text("idle.uninstallNote")
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
