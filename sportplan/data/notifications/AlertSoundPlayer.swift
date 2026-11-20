import AVFoundation
import Foundation
import Synchronization

nonisolated final class AlertSoundPlayer: NSObject, AVAudioPlayerDelegate, Sendable {
    static let soundFileName = "timer_end.caf"
    private static let soundName = "timer_end"
    private static let soundExtension = "caf"
    private static let headphonePorts: Set<AVAudioSession.Port> = [
        .headphones,
        .bluetoothA2DP,
        .bluetoothLE,
        .bluetoothHFP,
        .usbAudio,
    ]

    private let activePlayer = Mutex<AVAudioPlayer?>(nil)

    func playThroughHeadphones() -> Bool {
        let session = AVAudioSession.sharedInstance()
        let usesHeadphones = session.currentRoute.outputs.contains { output in
            return Self.headphonePorts.contains(output.portType)
        }
        guard usesHeadphones,
              let url = Bundle.main.url(forResource: Self.soundName, withExtension: Self.soundExtension)
        else {
            return false
        }
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            guard player.play() else {
                return false
            }
            activePlayer.withLock { current in
                current = player
            }
            return true
        } catch {
            return false
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activePlayer.withLock { current in
            current = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
