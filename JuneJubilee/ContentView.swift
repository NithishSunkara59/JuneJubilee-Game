import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var model = GameModel()
    @State private var sceneID = UUID()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.06, blue: 0.12), Color(red: 0.02, green: 0.11, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GameCanvasView(model: model, sceneID: sceneID)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HUDView(model: model)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()
            }

            if model.phase != .playing {
                StartPanel(model: model) {
                    model.reset()
                    sceneID = UUID()
                }
                .padding(.horizontal, 22)
                .padding(.top, 128)
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

struct GameCanvasView: View {
    @ObservedObject var model: GameModel
    let sceneID: UUID
    @State private var scene: SolsticeScene?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let scene {
                    SpriteView(scene: scene)
                } else {
                    Color.clear
                }
            }
            .onAppear {
                installScene(size: proxy.size)
            }
            .onChange(of: sceneID) {
                installScene(size: proxy.size)
            }
            .onChange(of: proxy.size) {
                scene?.size = proxy.size
            }
        }
    }

    private func installScene(size: CGSize) {
        let nextScene = SolsticeScene(size: size, model: model)
        nextScene.scaleMode = .resizeFill
        scene = nextScene
    }
}

@MainActor
final class GameModel: ObservableObject {
    enum Phase {
        case ready
        case playing
        case ended
    }

    @Published var phase: Phase = .ready
    @Published var score = 0
    @Published var dayBalance = 0.5
    @Published var timeRemaining = 90
    @Published var streak = 0
    @Published var activeToast = "Gather June's lights. Keep day and night in harmony."
    @Published var cipherTarget = ""
    @Published var cipherProgress = ""
    @Published var bestScore = UserDefaults.standard.integer(forKey: "JuneJubileeBestScore")

    func start() {
        phase = .playing
        activeToast = "The month begins. Drag the keeper of light."
    }

    func reset() {
        score = 0
        dayBalance = 0.5
        timeRemaining = 90
        streak = 0
        cipherTarget = ""
        cipherProgress = ""
        activeToast = "Gather June's lights. Keep day and night in harmony."
        phase = .playing
    }

    func finish() {
        phase = .ended
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(score, forKey: "JuneJubileeBestScore")
            activeToast = "New best! Your June constellation is shining."
        } else {
            activeToast = "Festival complete. Try for a brighter constellation."
        }
    }
}

struct HUDView: View {
    @ObservedObject var model: GameModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatPill(title: "Score", value: "\(model.score)")
                StatPill(title: "Time", value: "\(model.timeRemaining)")
                StatPill(title: "Best", value: "\(model.bestScore)")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Night")
                    Spacer()
                    Text("Solstice Balance")
                    Spacer()
                    Text("Day")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                        Capsule()
                            .fill(balanceGradient)
                            .frame(width: max(10, geo.size.width * model.dayBalance))
                        Rectangle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 2)
                            .offset(x: geo.size.width * 0.5)
                    }
                }
                .frame(height: 12)
            }
            .padding(10)
            .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))

            if !model.cipherTarget.isEmpty {
                CipherStrip(target: model.cipherTarget, progress: model.cipherProgress)
            }

            Text(model.activeToast)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var balanceGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.30, green: 0.42, blue: 0.95), Color(red: 0.99, green: 0.81, blue: 0.28)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct CipherStrip: View {
    let target: String
    let progress: String

    var body: some View {
        HStack(spacing: 8) {
            Text("Turing Cipher")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.58, green: 0.84, blue: 1.0))
            Spacer(minLength: 6)
            HStack(spacing: 5) {
                ForEach(Array(target.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(index < progress.count ? .black : .white)
                        .frame(width: 22, height: 22)
                        .background(index < progress.count ? Color(red: 0.58, green: 0.84, blue: 1.0) : .white.opacity(0.16), in: RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.title3.monospacedDigit().weight(.black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StartPanel: View {
    @ObservedObject var model: GameModel
    let start: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(model.phase == .ended ? "June Jubilee Complete" : "June Jubilee")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            if model.phase == .ended {
                VStack(spacing: 4) {
                    Text("Final Score")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("\(model.score)")
                        .font(.system(size: 38, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.28))
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            Text(summary)
                .font((model.phase == .ended ? Font.footnote : Font.callout).weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: start) {
                Text(model.phase == .ended ? "Play Again" : "Begin the Jubilee")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 1.0, green: 0.84, blue: 0.28), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var summary: String {
        if model.phase == .ended {
            return "Pride streaks, Juneteenth harmony, Turing ciphers, and solstice light shaped your June."
        }
        return "Drag to collect June celebrations. Pride boosts streaks, Juneteenth restores harmony, Turing opens binary ciphers, and solstice lights shift day and night."
    }
}

