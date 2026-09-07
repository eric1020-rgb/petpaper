import SwiftUI
import Observation

/// Main-actor idle playback: weighted roll → temporary pose → restore.
@MainActor
@Observable
final class PetIdleDirector {
    var pose = IdlePose.rest
    var toastKey: String?
    var isPlaying = false
    var currentAction: PetIdleAction?
    var showToast = true

    /// Resting normalized pet position, used so fly-out aims at a door on the canvas edge.
    var anchorPosition = CGPoint(x: 0.5, y: 0.62)

    private var playTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var playGeneration = 0

    func cancel() {
        playGeneration += 1
        playTask?.cancel()
        playTask = nil
        toastTask?.cancel()
        toastTask = nil
        isPlaying = false
        currentAction = nil
        toastKey = nil
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            pose = .rest
        }
    }

    func playRandom(photoCutout: Bool) {
        play(PetIdleAction.roll(photoCutout: photoCutout))
    }

    func play(_ action: PetIdleAction) {
        playGeneration += 1
        let token = playGeneration
        playTask?.cancel()
        playTask = Task { [weak self] in
            await self?.run(action, token: token)
        }
    }

    /// Interval loop. Caller should cancel this task when the screen is inactive or Follow is on.
    func runScheduledLoop(
        interval: TimeInterval,
        cooldown: TimeInterval,
        photoCutout: @escaping () -> Bool,
        shouldPause: @escaping () -> Bool
    ) async {
        while !Task.isCancelled {
            let nanos = UInt64(max(interval, 0.5) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            if shouldPause() { continue }
            if isPlaying { continue }
            playRandom(photoCutout: photoCutout())
            while isPlaying && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
            let coolNanos = UInt64(max(cooldown, 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: coolNanos)
        }
    }

    private func run(_ action: PetIdleAction, token: Int) async {
        isPlaying = true
        currentAction = action
        presentToast(action.nameKey)
        defer {
            if playGeneration == token {
                isPlaying = false
                currentAction = nil
            }
        }
        do {
            try await perform(action)
            guard playGeneration == token, !Task.isCancelled else { return }
            try await restoreRest()
        } catch {
            guard playGeneration == token else { return }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                pose = .rest
            }
        }
    }

    private func presentToast(_ key: String) {
        toastTask?.cancel()
        guard showToast else {
            toastKey = nil
            return
        }
        toastKey = key
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard !Task.isCancelled else { return }
            self?.toastKey = nil
        }
    }

    private func perform(_ action: PetIdleAction) async throws {
        switch action {
        case .blinkBreathe:
            try await blinkBreathe()
        case .lookAround:
            try await lookAround()
        case .earTailFlick:
            try await earTailFlick()
        case .yawnStretch:
            try await yawnStretch()
        case .bellyRoll:
            try await bellyRoll()
        case .scratch:
            try await scratch()
        case .sleepCurl:
            try await sleepCurl()
        case .zoomies:
            try await zoomies()
        case .flyOutDoor:
            try await flyOutDoor()
        }
    }

    private func blinkBreathe() async throws {
        for _ in 0..<2 {
            try await animate(0.12) { pose.eyeClose = 1 }
            try await animate(0.12) { pose.eyeClose = 0 }
        }
        try await animate(0.45) {
            pose.bodySquash = 1.08
            pose.extraScale = 1.03
        }
        try await animate(0.45) {
            pose.bodySquash = 0.97
            pose.extraScale = 0.99
        }
        try await animate(0.4) {
            pose.bodySquash = 1.05
            pose.extraScale = 1.02
        }
    }

    private func lookAround() async throws {
        try await animate(0.35) {
            pose.lookOffset = CGSize(width: -5, height: 1)
            pose.lean = -10
        }
        try await wait(0.35)
        try await animate(0.4) {
            pose.lookOffset = CGSize(width: 6, height: -1)
            pose.lean = 12
        }
        try await wait(0.28)
        try await animate(0.32) {
            pose.lookOffset = CGSize(width: -2, height: 2)
            pose.lean = -4
        }
    }

    private func earTailFlick() async throws {
        for i in 0..<3 {
            try await animate(0.12) {
                pose.earFlick = i.isMultiple(of: 2) ? 22 : -18
                pose.tailWag = i.isMultiple(of: 2) ? 28 : -24
            }
        }
        try await animate(0.18) {
            pose.earFlick = 0
            pose.tailWag = 10
        }
    }

    private func yawnStretch() async throws {
        try await animate(0.4) {
            pose.eyeClose = 0.45
            pose.extraScale = 1.1
            pose.extraRotation = -8
            pose.positionDelta = CGPoint(x: 0, y: -0.035)
            pose.bodySquash = 1.12
        }
        try await wait(0.45)
        try await animate(0.35) {
            pose.eyeClose = 0.15
            pose.extraScale = 1.04
            pose.extraRotation = 4
            pose.positionDelta = CGPoint(x: 0.01, y: -0.01)
        }
    }

    private func bellyRoll() async throws {
        try await animate(0.35) {
            pose.extraRotation = 90
            pose.positionDelta = CGPoint(x: 0.02, y: 0.02)
            pose.extraScale = 1.05
        }
        try await animate(0.4) {
            pose.extraRotation = 180
            pose.positionDelta = CGPoint(x: 0, y: 0.04)
        }
        try await wait(0.35)
        try await animate(0.45) {
            pose.extraRotation = 360
            pose.positionDelta = .zero
            pose.extraScale = 1
        }
        pose.extraRotation = 0
    }

    private func scratch() async throws {
        for i in 0..<6 {
            try await animate(0.09) {
                pose.lean = i.isMultiple(of: 2) ? 14 : -10
                pose.extraRotation = i.isMultiple(of: 2) ? 8 : -6
                pose.positionDelta = CGPoint(x: i.isMultiple(of: 2) ? 0.012 : -0.01, y: 0.008)
                pose.earFlick = i.isMultiple(of: 2) ? 12 : -8
            }
        }
    }

    private func sleepCurl() async throws {
        try await animate(0.5) {
            pose.eyeClose = 1
            pose.extraScale = 0.86
            pose.extraRotation = 16
            pose.positionDelta = CGPoint(x: -0.01, y: 0.025)
            pose.bodySquash = 0.9
        }
        try await wait(1.4)
        try await animate(0.28) {
            pose.eyeClose = 0.2
            pose.extraScale = 0.95
        }
    }

    private func zoomies() async throws {
        let dashes: [CGPoint] = [
            CGPoint(x: 0.12, y: -0.04),
            CGPoint(x: -0.1, y: 0.05),
            CGPoint(x: 0.08, y: 0.06),
            CGPoint(x: -0.14, y: -0.03),
            CGPoint(x: 0.04, y: -0.06)
        ]
        for (index, dash) in dashes.enumerated() {
            try await animate(0.16) {
                pose.positionDelta = dash
                pose.extraRotation = index.isMultiple(of: 2) ? 18 : -16
                pose.extraScale = 1.08
                pose.lean = index.isMultiple(of: 2) ? 12 : -12
            }
        }
    }

    private func flyOutDoor() async throws {
        let portal = CGPoint(x: 0.9, y: 0.4)
        let exitDelta = CGPoint(x: portal.x - anchorPosition.x, y: portal.y - anchorPosition.y)
        let enterDelta = CGPoint(x: 0.08 - anchorPosition.x, y: portal.y - anchorPosition.y)

        try await animate(0.35) {
            pose.portalVisible = 1
            pose.sparkleAmount = 0.7
        }
        try await animate(0.55) {
            pose.positionDelta = CGPoint(x: exitDelta.x * 0.45, y: exitDelta.y * 0.45 - 0.08)
            pose.extraRotation = -22
            pose.extraScale = 0.92
            pose.sparkleAmount = 1
        }
        try await animate(0.45) {
            pose.positionDelta = exitDelta
            pose.extraRotation = 28
            pose.extraScale = 0.55
            pose.opacity = 0
            pose.sparkleAmount = 1
        }
        try await wait(0.28)
        pose.positionDelta = enterDelta
        pose.extraRotation = -18
        pose.extraScale = 0.6
        try await animate(0.5) {
            pose.opacity = 1
            pose.positionDelta = CGPoint(x: enterDelta.x * 0.35, y: (0.62 - anchorPosition.y))
            pose.extraScale = 1.05
            pose.extraRotation = 8
            pose.sparkleAmount = 0.6
        }
        try await animate(0.4) {
            pose.portalVisible = 0
            pose.sparkleAmount = 0
            pose.positionDelta = .zero
            pose.extraScale = 1
            pose.extraRotation = 0
        }
    }

    private func restoreRest() async throws {
        try await animate(0.32) {
            pose = .rest
        }
    }

    private func animate(_ duration: Double, _ updates: () -> Void) async throws {
        try Task.checkCancellation()
        withAnimation(.easeInOut(duration: duration)) {
            updates()
        }
        try await wait(duration)
    }

    private func wait(_ seconds: Double) async throws {
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: UInt64(max(seconds, 0) * 1_000_000_000))
        try Task.checkCancellation()
    }
}
