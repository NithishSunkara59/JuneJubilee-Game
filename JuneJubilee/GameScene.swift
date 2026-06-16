import SpriteKit
import SwiftUI

final class SolsticeScene: SKScene, SKPhysicsContactDelegate {
    private enum Category {
        static let player: UInt32 = 1 << 0
        static let token: UInt32 = 1 << 1
        static let shadow: UInt32 = 1 << 2
    }

    fileprivate enum TokenKind: CaseIterable {
        case solstice
        case pride
        case juneteenth
        case turing
        case soccer
        case sushi
        case flipFlop
        case bitZero
        case bitOne

        var symbol: String {
            switch self {
            case .solstice: return "☀"
            case .pride: return "✦"
            case .juneteenth: return "★"
            case .turing: return "01"
            case .soccer: return "⚽"
            case .sushi: return "寿"
            case .flipFlop: return "FF"
            case .bitZero: return "0"
            case .bitOne: return "1"
            }
        }

        var name: String {
            switch self {
            case .solstice: return "Solstice"
            case .pride: return "Pride"
            case .juneteenth: return "Juneteenth"
            case .turing: return "Turing"
            case .soccer: return "World Cup"
            case .sushi: return "Sushi Day"
            case .flipFlop: return "Flip-Flop Day"
            case .bitZero: return "Cipher Bit"
            case .bitOne: return "Cipher Bit"
            }
        }

        var score: Int {
            switch self {
            case .solstice: return 80
            case .pride: return 60
            case .juneteenth: return 70
            case .turing: return 75
            case .soccer: return 45
            case .sushi: return 40
            case .flipFlop: return 35
            case .bitZero: return 20
            case .bitOne: return 20
            }
        }

        var dayShift: Double {
            switch self {
            case .solstice: return 0.10
            case .pride: return -0.03
            case .juneteenth: return 0.0
            case .turing: return 0.04
            case .soccer: return -0.05
            case .sushi: return 0.03
            case .flipFlop: return 0.06
            case .bitZero: return -0.01
            case .bitOne: return 0.01
            }
        }

        var color: SKColor {
            switch self {
            case .solstice: return SKColor(red: 1.0, green: 0.78, blue: 0.18, alpha: 1)
            case .pride: return SKColor(red: 0.95, green: 0.22, blue: 0.62, alpha: 1)
            case .juneteenth: return SKColor(red: 0.08, green: 0.78, blue: 0.42, alpha: 1)
            case .turing: return SKColor(red: 0.30, green: 0.72, blue: 1.0, alpha: 1)
            case .soccer: return SKColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
            case .sushi: return SKColor(red: 1.0, green: 0.37, blue: 0.28, alpha: 1)
            case .flipFlop: return SKColor(red: 0.12, green: 0.86, blue: 0.88, alpha: 1)
            case .bitZero: return SKColor(red: 0.08, green: 0.15, blue: 0.22, alpha: 1)
            case .bitOne: return SKColor(red: 0.58, green: 0.84, blue: 1.0, alpha: 1)
            }
        }

        var message: String {
            switch self {
            case .solstice: return "Solstice light stretches the day. Keep it balanced."
            case .pride: return "Pride spark! Authentic streaks are worth more."
            case .juneteenth: return "Juneteenth joy restores the balance."
            case .turing: return "Turing signal decoded. Bonus lights appear."
            case .soccer: return "World Cup teamwork keeps the rhythm moving."
            case .sushi: return "International Sushi Day: quick points, tiny delight."
            case .flipFlop: return "Flip-Flop Day breeze speeds you up."
            case .bitZero: return "Decode the next bit in Turing's sequence."
            case .bitOne: return "Decode the next bit in Turing's sequence."
            }
        }

        var canSpawnNaturally: Bool {
            self != .bitZero && self != .bitOne
        }
    }

    private let model: GameModel
    private let player = SKShapeNode(circleOfRadius: 22)
    private var playerSpeed: CGFloat = 1.0
    private var targetPosition: CGPoint?
    private var lastUpdate: TimeInterval = 0
    private var tokenSpawnClock: TimeInterval = 0
    private var shadowSpawnClock: TimeInterval = 0
    private var secondClock: TimeInterval = 0
    private var gameTime = 90
    private var bonusUntil: TimeInterval = 0
    private var cipherTarget = ""
    private var cipherProgress = ""
    private var cipherUntil: TimeInterval = 0

    init(size: CGSize, model: GameModel) {
        self.model = model
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        setupBackground()
        setupPlayer()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if player.parent != nil {
            player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.32)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard model.phase == .playing else {
            lastUpdate = currentTime
            return
        }

        if lastUpdate == 0 {
            lastUpdate = currentTime
        }

        let delta = min(currentTime - lastUpdate, 1.0 / 20.0)
        lastUpdate = currentTime

        movePlayer(delta: delta)
        updateTimers(delta: delta)
        updateBalance(delta: delta)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard model.phase == .playing else { return }
        let nodes = [contact.bodyA.node, contact.bodyB.node]

        if let token = nodes.compactMap({ $0 as? TokenNode }).first {
            collect(token)
        } else if let shadow = nodes.first(where: { $0?.name == "shadow" }) {
            hitShadow(shadow)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if model.phase == .ready {
            model.start()
        }
        targetPosition = touches.first?.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        targetPosition = touches.first?.location(in: self)
    }

    private func setupBackground() {
        removeAllChildren()

        let night = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        night.fillColor = SKColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1)
        night.strokeColor = .clear
        night.zPosition = -10
        addChild(night)

        for index in 0..<42 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.7))
            star.fillColor = .white.withAlphaComponent(CGFloat.random(in: 0.35...0.95))
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 10...max(20, size.width - 10)), y: CGFloat.random(in: size.height * 0.32...size.height - 20))
            star.zPosition = -5
            star.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: Double.random(in: 0.8...1.6)), .fadeAlpha(to: 0.9, duration: Double.random(in: 0.8...1.6))])))
            addChild(star)
            if index.isMultiple(of: 7) {
                makeRay(at: star.position)
            }
        }
    }

    private func makeRay(at point: CGPoint) {
        let ray = SKShapeNode(rectOf: CGSize(width: 2, height: CGFloat.random(in: 80...160)), cornerRadius: 1)
        ray.fillColor = SKColor(red: 1.0, green: 0.75, blue: 0.25, alpha: 0.18)
        ray.strokeColor = .clear
        ray.position = point
        ray.zRotation = CGFloat.random(in: -0.55...0.55)
        ray.zPosition = -4
        addChild(ray)
    }

    private func setupPlayer() {
        player.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.36, alpha: 1)
        player.strokeColor = .white
        player.lineWidth = 3
        player.glowWidth = 8
        player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.32)
        player.name = "player"
        player.physicsBody = SKPhysicsBody(circleOfRadius: 23)
        player.physicsBody?.categoryBitMask = Category.player
        player.physicsBody?.contactTestBitMask = Category.token | Category.shadow
        player.physicsBody?.collisionBitMask = 0
        player.zPosition = 10
        addChild(player)

        let label = SKLabelNode(text: "✹")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 27
        label.fontColor = SKColor(red: 0.04, green: 0.05, blue: 0.11, alpha: 1)
        label.verticalAlignmentMode = .center
        player.addChild(label)
    }

    private func movePlayer(delta: TimeInterval) {
        guard let targetPosition else { return }
        let dx = targetPosition.x - player.position.x
        let dy = targetPosition.y - player.position.y
        let distance = max(1, hypot(dx, dy))
        let step = min(distance, CGFloat(delta) * 620 * playerSpeed)
        player.position.x += dx / distance * step
        player.position.y += dy / distance * step
        player.position.x = min(max(player.position.x, 26), size.width - 26)
        player.position.y = min(max(player.position.y, 52), size.height - 28)
    }

    private func updateTimers(delta: TimeInterval) {
        tokenSpawnClock += delta
        shadowSpawnClock += delta
        secondClock += delta

        let spawnRate = bonusUntil > lastUpdate ? 0.42 : 0.72
        if tokenSpawnClock >= spawnRate {
            tokenSpawnClock = 0
            spawnToken()
            if !cipherTarget.isEmpty {
                spawnCipherPair()
            }
        }

        if shadowSpawnClock >= 1.35 {
            shadowSpawnClock = 0
            spawnShadow()
        }

        if secondClock >= 1 {
            secondClock -= 1
            gameTime -= 1
            Task { @MainActor in
                model.timeRemaining = max(0, gameTime)
                if gameTime <= 0 {
                    model.finish()
                }
                if !cipherTarget.isEmpty && lastUpdate > cipherUntil {
                    clearCipher(message: "The Turing cipher faded. Catch another signal.")
                }
            }
        }
    }

    private func updateBalance(delta: TimeInterval) {
        let drift = (model.dayBalance - 0.5) * 0.012 * delta
        let next = min(0.98, max(0.02, model.dayBalance + drift))
        Task { @MainActor in
            model.dayBalance = next
        }
    }

    private func spawnToken(kind forcedKind: TokenKind? = nil) {
        let pool = TokenKind.allCases.filter(\.canSpawnNaturally)
        let kind = forcedKind ?? pool.randomElement() ?? .solstice
        let token = TokenNode(kind: kind)
        token.position = CGPoint(x: CGFloat.random(in: 36...max(38, size.width - 36)), y: size.height + 40)
        token.physicsBody = SKPhysicsBody(circleOfRadius: 24)
        token.physicsBody?.categoryBitMask = Category.token
        token.physicsBody?.contactTestBitMask = Category.player
        token.physicsBody?.collisionBitMask = 0
        token.zPosition = 5
        addChild(token)

        let duration = TimeInterval(CGFloat.random(in: 4.2...6.8))
        let drift = CGFloat.random(in: -70...70)
        token.run(.sequence([
            .group([
                .moveBy(x: drift, y: -size.height - 110, duration: duration),
                .rotate(byAngle: CGFloat.pi * CGFloat.random(in: -1.5...1.5), duration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnCipherPair() {
        spawnToken(kind: .bitZero)
        spawnToken(kind: .bitOne)
    }

    private func spawnShadow() {
        let shadow = SKShapeNode(circleOfRadius: CGFloat.random(in: 16...28))
        shadow.name = "shadow"
        shadow.fillColor = SKColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 0.84)
        shadow.strokeColor = SKColor(red: 0.45, green: 0.48, blue: 0.70, alpha: 0.42)
        shadow.lineWidth = 2
        shadow.glowWidth = 3
        shadow.position = CGPoint(x: CGFloat.random(in: 32...max(34, size.width - 32)), y: size.height + 35)
        shadow.physicsBody = SKPhysicsBody(circleOfRadius: 22)
        shadow.physicsBody?.categoryBitMask = Category.shadow
        shadow.physicsBody?.contactTestBitMask = Category.player
        shadow.physicsBody?.collisionBitMask = 0
        shadow.zPosition = 4
        addChild(shadow)

        shadow.run(.sequence([
            .moveBy(x: CGFloat.random(in: -48...48), y: -size.height - 90, duration: TimeInterval(CGFloat.random(in: 4.6...7.2))),
            .removeFromParent()
        ]))
    }

    private func collect(_ token: TokenNode) {
        token.removeFromParent()
        burst(at: token.position, color: token.kind.color)

        if token.kind == .bitZero || token.kind == .bitOne {
            collectCipherBit(token.kind)
            return
        }

        let balanceBonus = 1.0 - min(1.0, abs(model.dayBalance - 0.5) * 2.0)
        let streakBonus = min(120, model.streak * 8)
        let earned = token.kind.score + Int(balanceBonus * 35) + streakBonus

        Task { @MainActor in
            model.score += earned
            model.streak += 1
            if token.kind == .juneteenth {
                model.dayBalance = 0.5
            } else {
                model.dayBalance = min(0.98, max(0.02, model.dayBalance + token.kind.dayShift))
            }
            model.activeToast = "\(token.kind.name): +\(earned). \(token.kind.message)"
        }

        switch token.kind {
        case .turing:
            startCipher()
        case .flipFlop:
            playerSpeed = 1.55
            run(.sequence([.wait(forDuration: 4), .run { [weak self] in self?.playerSpeed = 1.0 }]))
        default:
            break
        }
    }

    private func startCipher() {
        cipherTarget = (0..<4).map { _ in Bool.random() ? "1" : "0" }.joined()
        cipherProgress = ""
        cipherUntil = lastUpdate + 10
        bonusUntil = lastUpdate + 7
        spawnCipherPair()
        spawnCipherPair()
        Task { @MainActor in
            model.cipherTarget = cipherTarget
            model.cipherProgress = cipherProgress
            model.activeToast = "Turing cipher online. Collect bits in order: \(cipherTarget)."
        }
    }

    private func collectCipherBit(_ kind: TokenKind) {
        guard !cipherTarget.isEmpty else {
            return
        }

        let bit = kind == .bitOne ? "1" : "0"
        let expectedIndex = cipherTarget.index(cipherTarget.startIndex, offsetBy: cipherProgress.count)
        let expectedBit = String(cipherTarget[expectedIndex])

        if bit == expectedBit {
            cipherProgress += bit
            Task { @MainActor in
                model.score += 60 + model.streak * 6
                model.streak += 1
                model.cipherProgress = cipherProgress
                model.activeToast = "Correct bit \(bit). Cipher progress \(cipherProgress)/\(cipherTarget)."
            }
            if cipherProgress == cipherTarget {
                completeCipher()
            }
        } else {
            Task { @MainActor in
                model.score = max(0, model.score - 45)
                model.streak = 0
                model.activeToast = "Wrong bit. The cipher resets to the first symbol."
                model.cipherProgress = ""
            }
            cipherProgress = ""
        }
    }

    private func completeCipher() {
        let award = 320
        let target = cipherTarget
        cipherTarget = ""
        cipherProgress = ""
        cipherUntil = 0
        for _ in 0..<5 {
            spawnToken(kind: [.pride, .juneteenth, .solstice].randomElement())
        }
        Task { @MainActor in
            model.score += award
            model.cipherTarget = ""
            model.cipherProgress = ""
            model.activeToast = "Cipher \(target) cracked. +\(award) and a burst of June light."
        }
    }

    private func clearCipher(message: String) {
        cipherTarget = ""
        cipherProgress = ""
        cipherUntil = 0
        Task { @MainActor in
            model.cipherTarget = ""
            model.cipherProgress = ""
            model.activeToast = message
        }
    }

    private func hitShadow(_ shadow: SKNode?) {
        shadow?.removeFromParent()
        player.run(.sequence([.scale(to: 0.78, duration: 0.06), .scale(to: 1, duration: 0.12)]))
        Task { @MainActor in
            model.score = max(0, model.score - 55)
            model.streak = 0
            model.dayBalance = min(0.95, max(0.05, model.dayBalance + Double.random(in: -0.12...0.12)))
            model.activeToast = "A shadow scattered the lights. Recenter the celebration."
            model.cipherProgress = ""
        }
        cipherProgress = ""
    }

    private func burst(at point: CGPoint, color: SKColor) {
        for _ in 0..<13 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.position = point
            spark.zPosition = 20
            addChild(spark)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 28...74)
            spark.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: 0.1, duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }
}

private final class TokenNode: SKShapeNode {
    let kind: SolsticeScene.TokenKind

    init(kind: SolsticeScene.TokenKind) {
        self.kind = kind
        super.init()

        let path = CGMutablePath()
        path.addRoundedRect(in: CGRect(x: -24, y: -24, width: 48, height: 48), cornerWidth: 8, cornerHeight: 8)
        self.path = path
        fillColor = kind.color
        strokeColor = .white.withAlphaComponent(0.78)
        lineWidth = 2
        glowWidth = 7

        let label = SKLabelNode(text: kind.symbol)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = kind.symbol.count > 1 ? 15 : 24
        label.fontColor = kind == .bitZero ? .white : .black.withAlphaComponent(0.82)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
