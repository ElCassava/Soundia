@preconcurrency import AVFoundation
import SwiftUI

@MainActor
class SoundManager: ObservableObject {
    let engine = AVAudioEngine()
    let environment = AVAudioEnvironmentNode()

    @Published var activeSounds: Set<String> = []
    var players: [String: AVAudioPlayerNode] = [:]
    var audioFiles: [String: AVAudioFile] = [:]

    let soundNames = [
        "AirConditioner",
        "Cafe",
        "Fireplace",
        "NightCricket",
        "OceanWaves",
        "Rainfall",
        "Thunder",
        "Waterfall"
    ]

    init() {
        engine.attach(environment)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.listenerAngularOrientation = AVAudio3DAngularOrientation(
            yaw: 0,
            pitch: 0,
            roll: 0
        )
        environment.renderingAlgorithm = .HRTF
        preloadAudioFiles()
        
        
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
        try? engine.start()
    }

    private func preloadAudioFiles() {
        for name in soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
               let file = try? AVAudioFile(forReading: url) {
                audioFiles[name] = file
            } else {
                print("Missing file: \(name).mp3")
            }
        }
    }

    func activate(_ name: String) {
        guard players[name] == nil,
              let file = audioFiles[name] else { return }
        print(file.processingFormat.channelCount)
        let player = AVAudioPlayerNode()

        player.renderingAlgorithm = .HRTF

        engine.attach(player)
        engine.connect(player, to: environment, format: file.processingFormat)

        players[name] = player
        activeSounds.insert(name)

        loop(player: player, file: file)
        player.play()
    }

    private func loop(player: AVAudioPlayerNode, file: AVAudioFile) {
        player.scheduleFile(file, at: nil) { [weak self, weak player] in
            guard let self, let player else { return }
            if self.players.values.contains(player) {
                self.loop(player: player, file: file)
            }
        }
    }

    func deactivate(_ name: String) {
        guard let player = players[name] else { return }

        player.stop()
        engine.detach(player)

        players.removeValue(forKey: name)
        activeSounds.remove(name)
    }

    func updateSpatialPosition(name: String, angle: Double, radius: Float = 6.0) {
        guard let player = players[name] else { return }

        let radians = Float(angle * .pi / 180)

        player.position = AVAudio3DPoint(
            x: radius * cos(radians),
            y: 0,
            z: -radius * sin(radians)
        )
    }
}
