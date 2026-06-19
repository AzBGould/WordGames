import SwiftUI

// MARK: - Confetti View
//
// A short celebratory burst shown on a win. Rendered in a single `Canvas`
// (one GPU-backed draw pass for all particles) and driven by a
// `TimelineView(.animation(paused:))` so it updates in step with the display
// refresh only while active, and is fully paused — zero CPU/GPU cost — the rest
// of the time. Particle motion is computed in closed form from a start date, so
// there is no per-frame mutable state and no repeating `Timer` on the run loop.

struct ConfettiView: View {
    @Binding var isActive: Bool

    /// Frozen particle definitions for the current burst (regenerated per launch).
    @State private var particles: [Particle] = []
    /// When the current burst began; `nil` means idle (animation paused).
    @State private var startDate: Date? = nil

    // Tuning constants
    private static let duration: Double  = 4.0    // seconds the burst lasts
    private static let particleCount     = 100
    private static let gravity: Double   = 0.15   // per-frame² (60 fps reference)
    private static let fadeStart: Double = 2.5    // seconds before fade-out begins

    private let palette: [Color] = [
        Color(hex: "2FA98E"), Color(hex: "F4A259"), Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"), Color(hex: "FFE66D"),
        Color(hex: "A8DADC"), Color(hex: "F72585")
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: startDate == nil)) { timeline in
                Canvas { context, size in
                    guard let start = startDate else { return }
                    draw(into: context, size: size,
                         elapsed: timeline.date.timeIntervalSince(start))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            // Launch when a win sets the flag; the structured task below tears down.
            .onChange(of: isActive) { _, active in
                if active { launch(in: geo.size) }
            }
            // One structured task per burst handles teardown — no run-loop timer.
            .task(id: startDate) {
                guard startDate != nil else { return }
                try? await Task.sleep(nanoseconds: UInt64(Self.duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                startDate = nil
                particles = []
                isActive  = false
            }
        }
    }

    // MARK: - Drawing

    private func draw(into context: GraphicsContext, size: CGSize, elapsed: Double) {
        let frame = elapsed * 60                     // convert seconds → 60 fps "frames"
        for p in particles {
            let y = p.y0 + p.vy0 * frame + 0.5 * Self.gravity * frame * frame
            guard y < size.height + 40 else { continue }   // skip particles past the bottom

            let opacity = elapsed > Self.fadeStart
                ? max(0, 1 - (elapsed - Self.fadeStart) / (Self.duration - Self.fadeStart))
                : 1
            guard opacity > 0 else { continue }

            let x = p.x0 + p.vx * frame
            let w = p.size
            let h = p.isCircle ? p.size : p.size * 0.55
            let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            let path = p.isCircle ? Path(ellipseIn: rect) : Path(rect)

            context.drawLayer { layer in
                layer.opacity = opacity
                layer.translateBy(x: x, y: y)
                layer.rotate(by: .degrees(p.rotation0 + p.vr * frame))
                layer.fill(path, with: .color(p.color))
            }
        }
    }

    // MARK: - Launch

    private func launch(in size: CGSize) {
        particles = (0..<Self.particleCount).map { _ in
            Particle(
                x0:        CGFloat.random(in: 0...max(size.width, 1)),
                y0:        -20,
                vx:        CGFloat.random(in: -2...2),
                vy0:       CGFloat.random(in: 3...8),
                rotation0: Double.random(in: 0...360),
                vr:        Double.random(in: -8...8),
                size:      CGFloat.random(in: 8...16),
                color:     palette.randomElement() ?? .appAccent,
                isCircle:  Bool.random()
            )
        }
        startDate = .now
    }
}

// MARK: - Particle
// Immutable launch parameters; on-screen position is derived from elapsed time.

private struct Particle {
    let x0: CGFloat          // start x
    let y0: CGFloat          // start y
    let vx: CGFloat          // horizontal velocity (per 60-fps frame)
    let vy0: CGFloat         // initial vertical velocity (per 60-fps frame)
    let rotation0: Double    // start rotation (degrees)
    let vr: Double           // rotation velocity (degrees per frame)
    let size: CGFloat
    let color: Color
    let isCircle: Bool
}
