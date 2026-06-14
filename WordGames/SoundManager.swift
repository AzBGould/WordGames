import AudioToolbox
import UIKit

// MARK: - SoundManager
// Lightweight feedback using built-in iOS system sounds + haptics.
// No audio assets are bundled. All effects are gated by the caller's
// `soundEnabled` setting, so callers should check that before invoking.

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    // Haptic generators (reused; prepared lazily before firing)
    private let impactLight  = UIImpactFeedbackGenerator(style: .light)
    private let impactRigid  = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    // System sound IDs (present on all iOS devices)
    private let tockSound: SystemSoundID = 1104  // keyboard "Tock"
    private let tickSound: SystemSoundID = 1103  // keyboard "Tick"

    /// Light tap when a letter key is pressed.
    func keyTap() {
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.5)
        AudioServicesPlaySystemSound(tickSound)
    }

    /// Soft tap when a letter is deleted.
    func keyDelete() {
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.35)
    }

    /// Per-tile feedback as a row flips. Greens/yellows feel firmer.
    func reveal(_ state: TileState) {
        switch state {
        case .correct, .present:
            impactRigid.prepare()
            impactRigid.impactOccurred()
        default:
            impactLight.prepare()
            impactLight.impactOccurred(intensity: 0.4)
        }
        AudioServicesPlaySystemSound(tockSound)
    }

    /// Error buzz for an invalid or rejected guess.
    func invalid() {
        notification.prepare()
        notification.notificationOccurred(.error)
    }

    /// Success feedback on a win.
    func win() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Warning feedback on a loss.
    func lose() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
}
