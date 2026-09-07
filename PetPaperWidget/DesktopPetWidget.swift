import WidgetKit
import SwiftUI

struct DesktopPetEntry: TimelineEntry {
    let date: Date
    let petID: String
    let template: TemplateKind
    let pose: IdlePose
    let action: PetIdleAction?
    let usesPhoto: Bool
    let idleEnabled: Bool

    var character: PetCharacter {
        PetCharacter.character(id: petID)
    }

    var photoPet: PhotoPetCutout? {
        usesPhoto ? AppGroupStore.loadPhotoCutout() : nil
    }
}

struct DesktopPetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DesktopPetEntry {
        restEntry(date: Date(), intent: DesktopPetIntent())
    }

    func snapshot(for configuration: DesktopPetIntent, in context: Context) async -> DesktopPetEntry {
        restEntry(date: Date(), intent: configuration)
    }

    /// Local WidgetKit timeline only. No push, silent push, or BGAppRefresh — deleting the app removes the widget.
    func timeline(for configuration: DesktopPetIntent, in context: Context) async -> Timeline<DesktopPetEntry> {
        let now = Date()
        let enabled = configuration.resolvedIdleEnabled
        let interval = configuration.resolvedInterval
        let usesPhoto = configuration.resolvedUsesPhoto

        if !enabled {
            let rest = restEntry(date: now, intent: configuration)
            return Timeline(entries: [rest], policy: .after(now.addingTimeInterval(6 * 60 * 60)))
        }

        var generator = SystemRandomNumberGenerator()
        var entries: [DesktopPetEntry] = []
        entries.append(restEntry(date: now, intent: configuration))

        let spacing = max(interval.widgetSeconds, 15)
        let cycles: Int
        switch interval {
        case .demo:
            cycles = 8
        case .thirtyMinutes:
            cycles = 16
        case .oneHour:
            cycles = 12
        case .twoHours:
            cycles = 10
        case .fourHours:
            cycles = 8
        }

        var cursor = now.addingTimeInterval(spacing)
        for _ in 0..<cycles {
            guard entries.count < 72 else { break }
            let action = PetIdleAction.roll(photoCutout: usesPhoto, using: &generator)
            let frames = IdlePose.widgetFrames(for: action)
            var frameTime = cursor
            for frame in frames {
                entries.append(
                    DesktopPetEntry(
                        date: frameTime,
                        petID: configuration.resolvedPetID,
                        template: configuration.resolvedTemplate,
                        pose: frame.pose,
                        action: action,
                        usesPhoto: usesPhoto,
                        idleEnabled: true
                    )
                )
                frameTime += frame.duration
            }
            entries.append(restEntry(date: frameTime, intent: configuration))
            cursor = cursor.addingTimeInterval(spacing)
        }

        let reload: TimelineReloadPolicy
        if interval == .demo {
            reload = .after(now.addingTimeInterval(45))
        } else {
            reload = .atEnd
        }
        return Timeline(entries: entries, policy: reload)
    }

    private func restEntry(date: Date, intent: DesktopPetIntent) -> DesktopPetEntry {
        DesktopPetEntry(
            date: date,
            petID: intent.resolvedPetID,
            template: intent.resolvedTemplate,
            pose: .rest,
            action: nil,
            usesPhoto: intent.resolvedUsesPhoto,
            idleEnabled: intent.resolvedIdleEnabled
        )
    }
}

struct DesktopPetWidgetView: View {
    var entry: DesktopPetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let pose = entry.pose
            let petAnchor = CGPoint(x: 0.5 + pose.positionDelta.x, y: 0.72 + pose.positionDelta.y)
            ZStack {
                TemplateSceneView(template: entry.template, palette: entry.template.defaultPalette)
                IdlePortalOverlay(progress: pose.portalVisible, in: size)
                petLayer(in: size, pose: pose, anchor: petAnchor)
                IdleSparkleOverlay(
                    amount: pose.sparkleAmount,
                    in: size,
                    around: CGPoint(x: petAnchor.x * size.width, y: petAnchor.y * size.height),
                    animated: false
                )
                if family != .systemSmall, let action = entry.action {
                    VStack {
                        IdleToastBanner(key: action.nameKey)
                            .padding(.top, 8)
                        Spacer()
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            entry.template.defaultPalette.gradient
        }
        .widgetURL(AppGroupStore.editorURL(petID: entry.petID, template: entry.template))
    }

    @ViewBuilder
    private func petLayer(in size: CGSize, pose: IdlePose, anchor: CGPoint) -> some View {
        let petSize: CGFloat = family == .systemSmall ? 78 : 108
        PetLayerView(
            character: entry.character,
            photoPet: entry.photoPet,
            lookOffset: pose.lookOffset,
            lean: pose.lean,
            pose: pose
        )
        .frame(width: petSize, height: petSize * 1.12)
        .scaleEffect(pose.extraScale)
        .rotationEffect(.degrees(pose.extraRotation))
        .opacity(pose.opacity)
        .position(x: anchor.x * size.width, y: anchor.y * size.height)
    }
}

struct DesktopPetWidget: Widget {
    let kind = AppGroupStore.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DesktopPetIntent.self, provider: DesktopPetProvider()) { entry in
            DesktopPetWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.displayName"))
        .description(Text("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct PetPaperWidgetBundle: WidgetBundle {
    var body: some Widget {
        DesktopPetWidget()
    }
}
