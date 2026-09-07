import SwiftUI

/// Weighted idle activities. Ticket space is 0..<100 so **flyOutDoor is exactly 2%**.
enum PetIdleAction: String, CaseIterable, Identifiable {
    case blinkBreathe
    case lookAround
    case earTailFlick
    case yawnStretch
    case bellyRoll
    case scratch
    case sleepCurl
    case zoomies
    case flyOutDoor

    var id: String { rawValue }

    var nameKey: String { "idle.action.\(rawValue)" }

    /// Chance out of 100 for a full illustrated pet.
    var weight: Int {
        switch self {
        case .blinkBreathe: return 22
        case .lookAround: return 22
        case .earTailFlick: return 12
        case .yawnStretch: return 12
        case .bellyRoll: return 12
        case .scratch: return 12
        case .sleepCurl: return 3
        case .zoomies: return 3
        case .flyOutDoor: return 2
        }
    }

    /// Photo cutouts have no separate ears/mouth, so a subset of moves is remapped.
    var isAvailableForPhotoCutout: Bool {
        switch self {
        case .earTailFlick, .yawnStretch:
            return false
        default:
            return true
        }
    }

    static let flyOutWeight = 2
    static let ticketCount = 100

    static var weightTable: [(PetIdleAction, Int)] {
        allCases.map { ($0, $0.weight) }
    }

    static var weightsSumToOneHundred: Bool {
        allCases.reduce(0) { $0 + $1.weight } == ticketCount
            && Self.flyOutDoor.weight == flyOutWeight
    }

    /// Deterministic pick from a 0..<100 ticket. Fly-out is tickets 98 and 99 (exactly 2%).
    static func action(for ticket: Int, photoCutout: Bool) -> PetIdleAction {
        let clamped = min(max(ticket, 0), ticketCount - 1)
        var cumulative = 0
        var picked = PetIdleAction.blinkBreathe
        for action in allCases {
            cumulative += action.weight
            if clamped < cumulative {
                picked = action
                break
            }
        }
        if photoCutout, !picked.isAvailableForPhotoCutout {
            return remapForPhoto(picked)
        }
        return picked
    }

    static func roll(photoCutout: Bool, using generator: inout some RandomNumberGenerator) -> PetIdleAction {
        action(for: Int.random(in: 0..<ticketCount, using: &generator), photoCutout: photoCutout)
    }

    static func roll(photoCutout: Bool) -> PetIdleAction {
        var generator = SystemRandomNumberGenerator()
        return roll(photoCutout: photoCutout, using: &generator)
    }

    /// Keep fly-out at 2%; swap unsupported photo moves for nearby transform-only actions.
    private static func remapForPhoto(_ action: PetIdleAction) -> PetIdleAction {
        switch action {
        case .earTailFlick: return .lookAround
        case .yawnStretch: return .blinkBreathe
        default: return action
        }
    }
}

enum IdleInterval: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case twoHours
    case fourHours
    case demo

    var id: String { rawValue }
    var titleKey: String { "idle.interval.\(rawValue)" }

    var seconds: TimeInterval {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .demo: return 8
        }
    }

    /// Short pause after an action before the next interval starts.
    var cooldown: TimeInterval {
        switch self {
        case .demo: return 2
        default: return 12
        }
    }

    /// WidgetKit coalesces aggressive refreshes. Demo still aims for a short cycle so Simulator QA can see poses.
    var widgetSeconds: TimeInterval {
        switch self {
        case .demo: return 20
        default: return seconds
        }
    }
}

/// Temporary visual pose. Never written into `EditorState` (export stays the resting pet).
struct IdlePose: Equatable {
    var positionDelta: CGPoint = .zero
    var extraScale: CGFloat = 1
    var extraRotation: Double = 0
    var lookOffset: CGSize = .zero
    var lean: Double = 0
    var eyeClose: CGFloat = 0
    var earFlick: Double = 0
    var tailWag: Double = 0
    var bodySquash: CGFloat = 1
    var opacity: Double = 1
    var portalVisible: Double = 0
    var sparkleAmount: Double = 0

    static let rest = IdlePose()
}

struct IdlePoseFrame: Equatable {
    var pose: IdlePose
    var duration: TimeInterval
}

extension IdlePose {
    /// Discrete Home Screen poses. WidgetKit cannot run the in-app animator; it swaps timeline entries instead.
    static func widgetFrames(for action: PetIdleAction) -> [IdlePoseFrame] {
        switch action {
        case .blinkBreathe:
            return [
                IdlePoseFrame(pose: IdlePose(eyeClose: 1, bodySquash: 1.08, extraScale: 1.03), duration: 2),
                IdlePoseFrame(pose: IdlePose(bodySquash: 0.96, extraScale: 0.99), duration: 3)
            ]
        case .lookAround:
            return [
                IdlePoseFrame(pose: IdlePose(lookOffset: CGSize(width: -5, height: 1), lean: -12), duration: 3),
                IdlePoseFrame(pose: IdlePose(lookOffset: CGSize(width: 6, height: -1), lean: 12), duration: 3)
            ]
        case .earTailFlick:
            return [
                IdlePoseFrame(pose: IdlePose(earFlick: 22, tailWag: 28, lean: 6), duration: 2),
                IdlePoseFrame(pose: IdlePose(earFlick: -18, tailWag: -24, lean: -6), duration: 2)
            ]
        case .yawnStretch:
            return [
                IdlePoseFrame(
                    pose: IdlePose(
                        positionDelta: CGPoint(x: 0, y: -0.04),
                        extraScale: 1.12,
                        extraRotation: -8,
                        eyeClose: 0.4,
                        bodySquash: 1.1
                    ),
                    duration: 4
                )
            ]
        case .bellyRoll:
            return [
                IdlePoseFrame(pose: IdlePose(extraRotation: 90, extraScale: 1.05, positionDelta: CGPoint(x: 0.02, y: 0.02)), duration: 2),
                IdlePoseFrame(pose: IdlePose(extraRotation: 180, extraScale: 1.04, positionDelta: CGPoint(x: 0, y: 0.05)), duration: 3)
            ]
        case .scratch:
            return [
                IdlePoseFrame(pose: IdlePose(lean: 14, extraRotation: 8, positionDelta: CGPoint(x: 0.02, y: 0.01), earFlick: 12), duration: 2),
                IdlePoseFrame(pose: IdlePose(lean: -10, extraRotation: -6, positionDelta: CGPoint(x: -0.015, y: 0.01), earFlick: -8), duration: 2)
            ]
        case .sleepCurl:
            return [
                IdlePoseFrame(
                    pose: IdlePose(
                        positionDelta: CGPoint(x: -0.02, y: 0.04),
                        extraScale: 0.86,
                        extraRotation: 16,
                        eyeClose: 1,
                        bodySquash: 0.9
                    ),
                    duration: 5
                )
            ]
        case .zoomies:
            return [
                IdlePoseFrame(pose: IdlePose(positionDelta: CGPoint(x: 0.14, y: -0.05), extraRotation: 18, extraScale: 1.08, lean: 12), duration: 2),
                IdlePoseFrame(pose: IdlePose(positionDelta: CGPoint(x: -0.12, y: 0.06), extraRotation: -16, extraScale: 1.06, lean: -12), duration: 2)
            ]
        case .flyOutDoor:
            return [
                IdlePoseFrame(
                    pose: IdlePose(
                        positionDelta: CGPoint(x: 0.16, y: -0.1),
                        extraScale: 0.92,
                        extraRotation: -18,
                        portalVisible: 1,
                        sparkleAmount: 0.85
                    ),
                    duration: 2
                ),
                IdlePoseFrame(
                    pose: IdlePose(
                        positionDelta: CGPoint(x: 0.38, y: -0.18),
                        extraScale: 0.5,
                        extraRotation: 26,
                        opacity: 0.2,
                        portalVisible: 1,
                        sparkleAmount: 1
                    ),
                    duration: 2
                ),
                IdlePoseFrame(
                    pose: IdlePose(opacity: 0, portalVisible: 1, sparkleAmount: 0.9),
                    duration: 3
                ),
                IdlePoseFrame(
                    pose: IdlePose(
                        positionDelta: CGPoint(x: -0.22, y: -0.04),
                        extraScale: 0.88,
                        extraRotation: -10,
                        portalVisible: 0.45,
                        sparkleAmount: 0.5
                    ),
                    duration: 2
                )
            ]
        }
    }
}
