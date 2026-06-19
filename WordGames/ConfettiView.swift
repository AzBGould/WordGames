import SwiftUI

// MARK: - Confetti Particle

private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var color: Color
    var size: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var vr: Double
    var opacity: Double
    var isCircle: Bool
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var isActive: Bool

    @State private var particles: [Particle] = []
    @State private var timer: Timer? = nil

    private let colors: [Color] = [
        Color(hex: "2FA98E"), Color(hex: "F4A259"), Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"), Color(hex: "FFE66D"),
        Color(hex: "A8DADC"), Color(hex: "F72585")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    particleView(p)
                }
            }
            .ignoresSafeArea()
            .onChange(of: isActive) { _, active in
                if active {
                    launch(in: geo.size)
                } else {
                    stop()
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle View

    @ViewBuilder
    private func particleView(_ p: Particle) -> some View {
        Group {
            if p.isCircle {
                Circle().fill(p.color)
            } else {
                Rectangle().fill(p.color)
            }
        }
        .frame(width: p.size, height: p.isCircle ? p.size : p.size * 0.55)
        .rotationEffect(.degrees(p.rotation))
        .position(x: p.x, y: p.y)
        .opacity(p.opacity)
    }

    // MARK: - Physics

    private func launch(in size: CGSize) {
        particles = (0..<120).map { _ in
            Particle(
                x:        CGFloat.random(in: 0...size.width),
                y:        -20,
                rotation: Double.random(in: 0...360),
                color:    colors.randomElement()!,
                size:     CGFloat.random(in: 8...16),
                vx:       CGFloat.random(in: -2...2),
                vy:       CGFloat.random(in: 3...8),
                vr:       Double.random(in: -8...8),
                opacity:  1.0,
                isCircle: Bool.random()
            )
        }

        timer?.invalidate()
        var elapsed = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { t in
            elapsed += 1.0/60.0
            update(elapsed: elapsed, screenHeight: size.height)
            if elapsed > 4.0 {
                t.invalidate()
                withAnimation(.easeOut(duration: 0.5)) {
                    particles.removeAll()
                }
                isActive = false
            }
        }
    }

    private func update(elapsed: Double, screenHeight: CGFloat) {
        for i in particles.indices {
            particles[i].x        += particles[i].vx
            particles[i].y        += particles[i].vy
            particles[i].rotation += particles[i].vr
            particles[i].vy       += 0.15   // gravity
            if elapsed > 2.5 {
                particles[i].opacity = max(0, particles[i].opacity - 0.02)
            }
        }
        particles = particles.filter { $0.y < screenHeight + 40 }
    }

    private func stop() {
        timer?.invalidate()
        particles = []
    }
}
