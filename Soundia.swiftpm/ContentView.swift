import SwiftUI

let soundColors: [String: Color] = [
    "AirConditioner": .cyan,
    "Cafe": .orange,
    "Fireplace": .red,
    "NightCricket": .green,
    "OceanWaves": .blue,
    "Rainfall": .mint,
    "Thunder": .purple,
    "Waterfall": .teal
]

struct ContentView: View {
    @StateObject private var soundManager = SoundManager()
    @State private var isOverDropZone = false
    @State private var soundAngles: [String: Double] = [:]
    @State private var orbitTimer: Timer?
    @State private var activationOrder: [String] = []
    @State private var auraIndex: Int = 0
    @State private var auraTimer: Timer?
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 4)
    
    var inactiveSounds: [String] {
        soundManager.soundNames
            .filter { !soundManager.activeSounds.contains($0) }
    }
    
    var activeSounds: [String] {
        Array(soundManager.activeSounds)
    }
    
    var auraColor: Color {
        guard !activationOrder.isEmpty,
              activationOrder.indices.contains(auraIndex),
              let color = soundColors[activationOrder[auraIndex]]
        else {
            return .white
        }
        return color
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.38, blue: 0.32),
                    Color(red: 0.18, green: 0.28, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                let circleSize = min(geo.size.width, geo.size.height * 0.6)
                
                VStack(spacing: 24) {
                    Text("Use headphones for best experience")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 12)
                    
                    Spacer(minLength: 12)
                    
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        auraColor.opacity(0.6),
                                        auraColor.opacity(0.25),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: circleSize * 0.25
                                )
                            )
                            .frame(width: circleSize * 0.35, height: circleSize * 0.35)
                            .blur(radius: 18)
                            .animation(.easeInOut(duration: 0.6), value: auraColor)
                        
                        ForEach(activeSounds, id: \.self) { name in
                            SoundTileView(name: name, soundManager: soundManager)
                                .onTapGesture(count: 2) {
                                    deactivateSound(name)
                                }
                                .offset(getOrbitalOffset(for: name, radius: circleSize * 0.25))
                        }
                        
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: circleSize * 0.16)
                            .foregroundColor(.white)
                        
                        Text(activeSounds.isEmpty
                             ? "Drag Sounds Here"
                             : "Double-tap a sound to dismiss")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: circleSize * 0.3)
                    }
                    .frame(width: circleSize, height: circleSize)
                    .contentShape(Circle())
                    .onDrop(of: [.text], isTargeted: $isOverDropZone) { providers in
                        guard let provider = providers.first else { return false }
                        
                        provider.loadObject(ofClass: NSString.self) { item, _ in
                            if let name = item as? String {
                                DispatchQueue.main.async {
                                    activateSound(name)
                                }
                            }
                        }
                        return true
                    }
                    
                    Spacer()
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(inactiveSounds, id: \.self) { name in
                            SoundTileView(name: name, soundManager: soundManager)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    startOrbitalAnimation()
                    startAuraCycle()
                }
            }
        }
    }
    
    func activateSound(_ name: String) {
        guard !activationOrder.contains(name) else { return }
        
        soundManager.activate(name)
        soundAngles[name] = Double.random(in: 0..<360)
        activationOrder.append(name)
        
        if activationOrder.count == 1 {
            auraIndex = 0
        }
    }
    
    func deactivateSound(_ name: String) {
        soundManager.deactivate(name)
        soundAngles.removeValue(forKey: name)
        
        activationOrder.removeAll { $0 == name }
        
        if auraIndex >= activationOrder.count {
            auraIndex = 0
        }
    }
    
    func getOrbitalOffset(for name: String, radius: CGFloat) -> CGSize {
        let angle = soundAngles[name] ?? 0
        let radians = angle * .pi / 180
        return CGSize(
            width: radius * cos(radians),
            height: radius * sin(radians)
        )
    }
    
    func startOrbitalAnimation() {
        orbitTimer?.invalidate()
        
        orbitTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for name in activeSounds {
                soundAngles[name, default: 0] += 0.5
                if soundAngles[name]! >= 360 {
                    soundAngles[name] = 0
                }
                
                soundManager.updateSpatialPosition(
                    name: name,
                    angle: soundAngles[name]!
                )
            }
        }
    }
    
    func startAuraCycle() {
        auraTimer?.invalidate()
        
        auraTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            guard !activationOrder.isEmpty else { return }
            
            withAnimation(.easeInOut(duration: 0.6)) {
                auraIndex = (auraIndex + 1) % activationOrder.count
            }
        }
    }
}

struct SoundTileView: View {
    let name: String
    @ObservedObject var soundManager: SoundManager
    
    var body: some View {
        VStack {
            Image(systemName: getIcon(for: name))
                .font(.title)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.white.opacity(0.1))
                )
                .contentShape(RoundedRectangle(cornerRadius: 15))
            
            Text(name.capitalized)
                .font(.caption2)
        }
        .foregroundColor(.white)
        .onDrag {
            NSItemProvider(object: name as NSString)
        }
    }
    
    func getIcon(for name: String) -> String {
        switch name {
        case "AirConditioner": return "fan.fill"
        case "Cafe": return "cup.and.saucer.fill"
        case "Fireplace": return "flame.fill"
        case "NightCricket": return "leaf.fill"
        case "OceanWaves": return "water.waves"
        case "Rainfall": return "cloud.rain.fill"
        case "Thunder": return "bolt.fill"
        case "Waterfall": return "humidity.fill"
        default: return "fan.fill"
        }
    }
}
