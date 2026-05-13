//
//  GameScene.swift
//  Walk to Grow Shared
//
//  Created by Dzy on 30/3/26.
//

import AVFoundation
import GameplayKit
import SpriteKit

#if os(iOS) || os(tvOS)
    import UIKit
#endif

class GameScene: SKScene {

    //MARK - Properties
    var onTodayStepsUpdated: ((Int) -> Void)?
    /// Callback khi trạng thái đói thay đổi: `true` = đói, `false` = no đủ.
    var onHungerStateChanged: ((Bool) -> Void)?
    private let worldNode = SKNode()
    private var bgNode: SKSpriteNode!
    private var grassNode: GrassNode?
    private var wanderCats: [CatSheet1024Node] = []
    private let hudNode = SKNode()
    private let hudBackgroundNode = SKShapeNode()
    private let stepsLabel = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
    private let percentLabel = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
    private let coinLabel = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
    private let energyLabel = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
    private let progressTrackNode = SKShapeNode()
    private let progressFillNode = SKShapeNode()
    private var foregroundObserver: NSObjectProtocol?
    private var bgMusicPlayer: AVAudioPlayer?
    private var meowPlayer: AVAudioPlayer?
    private let normalBackgroundMusicVolume: Float = 0.35
    /// Trạng thái đói toàn cục — khi `true`, mèo nằm bẹp và không wander.
    private var isHungry = false

    let tileSize: CGFloat = 54
    let mapWidth = 20
    let mapHeight = 20

    //MARK - Lifecycle
    override func didMove(to view: SKView) {
        self.setupNodes()
        self.setupAudio()
        self.setupTopHUD()
        #if os(iOS)
            self.refreshTodaySteps()
        #endif
        self.observeAppForegroundIfNeeded()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
            self.foregroundObserver = nil
        }
        bgMusicPlayer?.stop()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        #if os(iOS) || os(tvOS)
            layoutTopHUD()
            layoutGrassAndWorldForSceneSize()
        #endif
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else { return }

        let position = touch.location(in: self)

        print("x:", position.x, "y:", position.y)

        let scenePosition = touch.location(in: self)
        for node in nodes(at: scenePosition) {
            var current: SKNode? = node
            while let c = current {
                if let cat = c as? CatSheet1024Node, wanderCats.contains(where: { $0 === cat }) {
                    handleCatTapped(cat)
                    return
                }
                current = c.parent
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

}

#if os(iOS) || os(tvOS)
    //MARK - setup
    extension GameScene {
        private func setupNodes() {
            backgroundColor = .blue

            // Nền cỏ phủ full `size`; map mèo (worldNode) căn giữa scene.
            addChild(worldNode)
            worldNode.zPosition = 1

            layoutGrassAndWorldForSceneSize()

            addBG()
            spawnPets()
            scheduleAutoTipLoop()
            scheduleHungerTimer()
        }
    }

    //MARK - HUD
    extension GameScene {
        private enum HUDMetrics {
            static let originX: CGFloat = 300
            static let originY: CGFloat = 1620
            static func width(in sceneWidth: CGFloat) -> CGFloat {
                return sceneWidth * 0.6  // Trừ đi lề trái phải (mỗi bên 30)
            }
            static let height: CGFloat = 132
            static let cornerRadius: CGFloat = 20
            static let progressHeight: CGFloat = 18
            static let progressInset: CGFloat = 16
            static let horizontalInset: CGFloat = 20
            /// Khoảng cách từ đáy HUD tới thanh tiến độ (SpriteKit y tăng lên trên).
            static let progressBarBottomInset: CGFloat = 56
            /// Khoảng cách từ đỉnh HUD xuống dòng Steps / %.
            static let topLabelsInsetFromTop: CGFloat = 38
        }

        private func setupTopHUD() {
            guard hudNode.parent == nil else { return }

            hudNode.zPosition = 10_000
            addChild(hudNode)

            hudBackgroundNode.fillColor = UIColor.black.withAlphaComponent(0.28)
            hudBackgroundNode.strokeColor = UIColor.white.withAlphaComponent(
                0.18
            )
            hudBackgroundNode.lineWidth = 1
            hudNode.addChild(hudBackgroundNode)

            stepsLabel.fontSize = 20
            stepsLabel.fontColor = .white
            stepsLabel.horizontalAlignmentMode = .left
            stepsLabel.verticalAlignmentMode = .center
            hudNode.addChild(stepsLabel)

            percentLabel.fontSize = 18
            percentLabel.fontColor = UIColor.white.withAlphaComponent(0.9)
            percentLabel.horizontalAlignmentMode = .right
            percentLabel.verticalAlignmentMode = .center
            hudNode.addChild(percentLabel)

            progressTrackNode.fillColor = UIColor.white.withAlphaComponent(0.2)
            progressTrackNode.strokeColor = .clear
            hudNode.addChild(progressTrackNode)

            progressFillNode.fillColor = UIColor.systemGreen
            progressFillNode.strokeColor = .clear
            hudNode.addChild(progressFillNode)

            coinLabel.fontSize = 14
            coinLabel.fontColor = .white
            coinLabel.horizontalAlignmentMode = .left
            coinLabel.verticalAlignmentMode = .center
            hudNode.addChild(coinLabel)

            energyLabel.fontSize = 14
            energyLabel.fontColor = .white
            energyLabel.horizontalAlignmentMode = .right
            energyLabel.verticalAlignmentMode = .center
            hudNode.addChild(energyLabel)

            layoutTopHUD()
            updateHUD(steps: 0)
        }

        private func layoutTopHUD() {
            let hudWidth = HUDMetrics.width(in: size.width)
            let hudHeight = HUDMetrics.height
            let origin = CGPoint(x: HUDMetrics.originX, y: HUDMetrics.originY)
            let rect = CGRect(
                origin: origin,
                size: CGSize(width: hudWidth, height: hudHeight)
            )

            hudBackgroundNode.path = CGPath(
                roundedRect: rect,
                cornerWidth: HUDMetrics.cornerRadius,
                cornerHeight: HUDMetrics.cornerRadius,
                transform: nil
            )

            stepsLabel.position = CGPoint(
                x: rect.minX + HUDMetrics.horizontalInset,
                y: rect.maxY - HUDMetrics.topLabelsInsetFromTop
            )
            percentLabel.position = CGPoint(
                x: rect.maxX - HUDMetrics.horizontalInset,
                y: rect.maxY - HUDMetrics.topLabelsInsetFromTop
            )

            let trackY = rect.minY + HUDMetrics.progressBarBottomInset
            let trackRect = CGRect(
                x: rect.minX + HUDMetrics.progressInset,
                y: trackY,
                width: rect.width - HUDMetrics.progressInset * 2,
                height: HUDMetrics.progressHeight
            )
            progressTrackNode.path = CGPath(
                roundedRect: trackRect,
                cornerWidth: HUDMetrics.progressHeight / 2,
                cornerHeight: HUDMetrics.progressHeight / 2,
                transform: nil
            )

            coinLabel.position = CGPoint(
                x: rect.minX + HUDMetrics.horizontalInset,
                y: rect.minY + 24
            )
            energyLabel.position = CGPoint(
                x: rect.maxX - HUDMetrics.horizontalInset,
                y: rect.minY + 24
            )
        }

        private func updateHUD(steps: Int) {
            let progress = GameProgressCalculator.progress(for: steps)
            let target = GameProgressCalculator.dailyStepTarget
            let coin = GameProgressCalculator.coin(from: steps)
            let energy = GameProgressCalculator.energy(from: steps)

            stepsLabel.text = "Steps: \(steps)/\(target)"
            percentLabel.text = "\(Int(progress * 100))%"
            coinLabel.text = "Coin: \(coin)"
            energyLabel.text = "Energy: \(energy)"
            onTodayStepsUpdated?(steps)

            let hudWidth = HUDMetrics.width(in: size.width)
            let originX = HUDMetrics.originX
            let barMaxWidth = hudWidth - HUDMetrics.progressInset * 2
            let fillWidth = min(barMaxWidth * progress, barMaxWidth)
            if fillWidth <= 0 {
                progressFillNode.path = nil
            } else {
                let fillRect = CGRect(
                    x: originX + HUDMetrics.progressInset,
                    y: HUDMetrics.originY + HUDMetrics.progressBarBottomInset,
                    width: fillWidth,
                    height: HUDMetrics.progressHeight
                )

                progressFillNode.path = CGPath(
                    roundedRect: fillRect,
                    cornerWidth: HUDMetrics.progressHeight / 2,
                    cornerHeight: HUDMetrics.progressHeight / 2,
                    transform: nil
                )
            }
        }

        #if os(iOS)
            private func refreshTodaySteps() {
                HealthKitStepService.shared.requestAuthorizationIfNeeded {
                    [weak self] success in
                    guard let self else { return }
                    guard success else {
                        DispatchQueue.main.async {
                            self.updateHUD(steps: 0)
                        }
                        return
                    }
                    HealthKitStepService.shared.fetchTodayStepCount { steps in
                        DispatchQueue.main.async {
                            self.updateHUD(steps: steps)
                        }
                    }
                }
            }
        #endif

        private func observeAppForegroundIfNeeded() {
            #if os(iOS)
                guard foregroundObserver == nil else { return }
                foregroundObserver = NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    self?.refreshTodaySteps()
                }
            #endif
        }
    }

    //MARK - Background

    extension GameScene {

        private func addBG() {
            bgNode = SKSpriteNode(imageNamed: "bg")
            bgNode.zPosition = -1.0
            bgNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
            // Phủ full scene (aspectFill của riêng sprite để không méo)
            let scale = max(
                size.width / bgNode.size.width * 1.05,
                size.height / bgNode.size.height * 1.05
            )
            bgNode.setScale(scale)
            addChild(bgNode)
        }

        /// Căn map chơi (mèo) giữa scene; nền cỏ phủ toàn bộ `size` (tọa độ scene, góc dưới-trái).
        func layoutGrassAndWorldForSceneSize() {
            let mapW = CGFloat(mapWidth) * tileSize
            let mapH = CGFloat(mapHeight) * tileSize
            worldNode.position = CGPoint(
                x: size.width / 2 - mapW / 2,
                y: size.height / 2 - mapH / 2
            )
            rebuildFullScreenGrass()
        }

        private func rebuildFullScreenGrass() {
            grassNode?.removeFromParent()
            let columns = max(1, Int(ceil(size.width / tileSize)))
            let rows = max(1, Int(ceil(size.height / tileSize)))
            let node = GrassNode(columns: columns, rows: rows, tileSize: tileSize)
            node.position = .zero
            node.zPosition = 0
            insertChild(node, at: 0)
            grassNode = node
        }

        /// Mặc định: mèo đầu tiên trên map.
        func spawnPets() {
            guard wanderCats.isEmpty else { return }
            addPetCat(sheetImageName: "black_4", at: defaultSpawnPoint())
        }

        /// Thêm một mèo mới (skin từ cửa hàng), không xóa mèo cũ.
        func addWanderingCatFromShop(_ sheetImageName: String) {
            let idx = wanderCats.count
            addPetCat(sheetImageName: sheetImageName, at: spawnPointForCatIndex(idx))
        }

        private func defaultSpawnPoint() -> CGPoint {
            CGPoint(x: tileSize * 5.5, y: tileSize * 4.5)
        }

        /// Vị trí spawn theo số mèo hiện có (tránh chồng lên nhau).
        private func spawnPointForCatIndex(_ index: Int) -> CGPoint {
            let base = defaultSpawnPoint()
            let mapW = CGFloat(mapWidth) * tileSize
            let mapH = CGFloat(mapHeight) * tileSize
            let margin = tileSize * 2
            guard index > 0 else {
                return CGPoint(
                    x: min(max(base.x, margin), mapW - margin),
                    y: min(max(base.y, margin), mapH - margin)
                )
            }
            let k = index
            let angle = CGFloat(k) * 0.72
            let radius = tileSize * (1.15 + CGFloat(min(k, 10)) * 0.42)
            var p = CGPoint(
                x: base.x + cos(angle) * radius,
                y: base.y + sin(angle) * radius
            )
            p.x = min(max(p.x, margin), mapW - margin)
            p.y = min(max(p.y, margin), mapH - margin)
            return p
        }

        private func addPetCat(sheetImageName: String, at position: CGPoint) {
            let s = tileSize * 3
            let anchor = CGPoint(x: 0.5, y: 0.35)
            let cat = CatSheet1024Node(
                sheetImageName: sheetImageName,
                displaySize: CGSize(width: s, height: s)
            )
            cat.anchorPoint = anchor
            cat.position = position
            cat.zPosition = 10 + CGFloat(wanderCats.count) * 0.02
            cat.runIdleAnimation()
            worldNode.addChild(cat)
            wanderCats.append(cat)
            scheduleNextWanderStep(for: cat)
        }

    }

    //MARK - Cat wander
    extension GameScene {
        private enum CatWander {
            enum WanderDirection: CaseIterable {
                case top
                case bottom
                case left
                case right
                case topLeft
                case topRight
                case bottomLeft
                case bottomRight

                var spriteDirection: Direction {
                    switch self {
                    case .top: return .top
                    case .bottom: return .bottom
                    case .left: return .left
                    case .right: return .right
                    case .topLeft: return .topLeft
                    case .topRight: return .topRight
                    case .bottomLeft: return .bottomLeft
                    case .bottomRight: return .bottomRight
                    }
                }
            }

            static let movementKey = "cat_wander_movement"
            static let minPause: TimeInterval = 0.35
            static let maxPause: TimeInterval = 1.1
            static let restChance: CGFloat = 0.35
            static let minRestDuration: TimeInterval = 1.0
            static let maxRestDuration: TimeInterval = 5.0
            static let speedTilesPerSecond: CGFloat = 1.8
            static let minStepTiles: CGFloat = 1.0
            static let maxStepTiles: CGFloat = 4.0
            static let tapPauseKey = "cat_wander_tap_pause"
            static let tipBubbleKey = "cat_tap_tip_bubble"
            static let resumeAfterTap: TimeInterval = 3.5
            static let autoTipActionKey = "cat_auto_tip_loop"
            static let hungerActionKey = "cat_hunger_timer"
            static let hungerBubbleKey = "cat_hunger_bubble"
            static let hungerMinInterval: TimeInterval = 45
            static let hungerMaxInterval: TimeInterval = 90
            static let autoTipMinInterval: TimeInterval = 8
            static let autoTipMaxInterval: TimeInterval = 15
            static let walkingTips: [String] = [
                "Giữ lưng thẳng\nkhi đi bộ nhé! 🐾",
                "Hít thở đều đặn,\nhít vào bằng mũi! 🌬️",
                "Uống nước trước\nkhi đi bộ nha! 💧",
                "Khởi động nhẹ\ntrước khi đi! 🤸",
                "Đi bộ 30 phút\nmỗi ngày là đủ! ⏱️",
                "Mắt nhìn thẳng,\nkhông cúi đầu! 👀",
                "Bước chân vừa phải,\nkhông quá dài! 👟",
                "Thả lỏng vai\nkhi đi bộ nhé! 😌",
                "Đi bộ buổi sáng\ntốt cho sức khỏe! 🌅",
                "Nghỉ ngơi nếu\ncảm thấy mệt! 💤",
                "Chọn giày thoải mái\nđể bảo vệ chân! 👟",
                "Đi bộ sau ăn\ngiúp tiêu hóa tốt! 🍽️",
                "Tay vung tự nhiên\ntheo nhịp bước! 💪",
                "Đặt mục tiêu nhỏ,\ntăng dần mỗi ngày! 📈",
                "Đi cùng bạn bè\nsẽ vui hơn! 🐱‍👤",
            ]

            static func movementActionKey(for cat: CatSheet1024Node) -> String {
                "\(movementKey).\(ObjectIdentifier(cat))"
            }

            static func tapPauseActionKey(for cat: CatSheet1024Node) -> String {
                "\(tapPauseKey).\(ObjectIdentifier(cat))"
            }

        }

        private func scheduleNextWanderStep(for cat: CatSheet1024Node) {
            guard !isHungry else { return }
            let moveKey = CatWander.movementActionKey(for: cat)

            let (target, moveDirection) = randomWanderPoint(for: cat)
            let dx = target.x - cat.position.x
            cat.runWalkAnimation(direction: moveDirection.spriteDirection)

            let distance = hypot(dx, target.y - cat.position.y)
            let speed = tileSize * CatWander.speedTilesPerSecond
            let duration = max(0.25, TimeInterval(distance / speed))

            let move = SKAction.move(to: target, duration: duration)
            move.timingMode = .easeInEaseOut
            let shouldRest = CGFloat.random(in: 0...1) < CatWander.restChance
            let pause: SKAction
            if shouldRest {
                let rest = SKAction.run { [weak cat] in
                    guard let cat else { return }
                    if Bool.random() {
                        cat.runLayingAnimation(
                            direction: moveDirection.spriteDirection
                        )
                    } else {
                        cat.runIdleAnimation()
                    }
                }
                let restWait = SKAction.wait(
                    forDuration: TimeInterval.random(
                        in: CatWander
                            .minRestDuration...CatWander.maxRestDuration
                    )
                )
                pause = SKAction.sequence([rest, restWait])
            } else {
                let shortPause = SKAction.wait(
                    forDuration: TimeInterval.random(
                        in: CatWander.minPause...CatWander.maxPause
                    )
                )
                let idle = SKAction.run { [weak cat] in
                    cat?.runIdleAnimation()
                }
                pause = SKAction.sequence([shortPause, idle])
            }

            let next = SKAction.run { [weak self, weak cat] in
                guard let self, let cat else { return }
                self.scheduleNextWanderStep(for: cat)
            }

            cat.removeAction(forKey: moveKey)
            cat.run(
                SKAction.sequence([move, pause, next]),
                withKey: moveKey
            )
        }

        private func randomWanderPoint(for cat: SKSpriteNode) -> (
            CGPoint, CatWander.WanderDirection
        ) {
            let mapW = CGFloat(mapWidth) * tileSize
            let mapH = CGFloat(mapHeight) * tileSize

            let halfW = cat.size.width * 0.5
            let halfH = cat.size.height * 0.5

            let minX = halfW
            let maxX = mapW - halfW
            let minY = halfH
            let maxY = mapH - halfH

            let stepDistance =
                tileSize
                * CGFloat.random(
                    in: CatWander.minStepTiles...CatWander.maxStepTiles
                )
            let directions = CatWander.WanderDirection.allCases.shuffled()

            for direction in directions {
                var target = cat.position
                switch direction {
                case .top:
                    target.y += stepDistance
                case .bottom:
                    target.y -= stepDistance
                case .left:
                    target.x -= stepDistance
                case .right:
                    target.x += stepDistance
                case .topLeft:
                    target.x -= stepDistance
                    target.y += stepDistance
                case .topRight:
                    target.x += stepDistance
                    target.y += stepDistance
                case .bottomLeft:
                    target.x -= stepDistance
                    target.y -= stepDistance
                case .bottomRight:
                    target.x += stepDistance
                    target.y -= stepDistance
                }

                target.x = min(max(target.x, minX), maxX)
                target.y = min(max(target.y, minY), maxY)

                if hypot(target.x - cat.position.x, target.y - cat.position.y)
                    > 0.01
                {
                    return (target, direction)
                }
            }

            return (cat.position, .bottom)
        }
        private func handleCatTapped(_ cat: CatSheet1024Node) {
            #if os(iOS)
                if GameAudioSettings.isVibrationEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            #endif
            // Khi đói, tap mèo chỉ hiện lại bubble đói, không resume wander
            if isHungry {
                self.playMeowSound()
                showHungerBubble(above: cat)
                return
            }
            let moveKey = CatWander.movementActionKey(for: cat)
            let pauseKey = CatWander.tapPauseActionKey(for: cat)
            cat.removeAction(forKey: moveKey)
            cat.removeAction(forKey: pauseKey)
            cat.runIdleAnimation()
            self.playMeowSound()
            showWalkingTip(above: cat)
            let resume = SKAction.run { [weak self, weak cat] in
                guard let self, let cat else { return }
                self.scheduleNextWanderStep(for: cat)
            }
            cat.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: CatWander.resumeAfterTap),
                    resume,
                ]),
                withKey: pauseKey
            )
        }
        private func showWalkingTip(above cat: SKSpriteNode) {
            cat.childNode(withName: CatWander.tipBubbleKey)?.removeFromParent()

            let tipText = CatWander.walkingTips.randomElement() ?? "Đi bộ vui vẻ nhé! 🐾"

            // --- Bubble container ---
            let bubbleNode = SKNode()
            bubbleNode.name = CatWander.tipBubbleKey
            bubbleNode.zPosition = cat.zPosition + 2

            // --- Text label ---
            let fontSize: CGFloat = max(14, tileSize * 0.32)
            let label = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
            label.text = tipText
            label.fontSize = fontSize
            label.fontColor = SKColor(red: 0.18, green: 0.14, blue: 0.12, alpha: 1)
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = tileSize * 3.2
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.lineBreakMode = .byWordWrapping

            // --- Measure text for bubble size ---
            let textFrame = label.frame
            let paddingH: CGFloat = tileSize * 0.35
            let paddingV: CGFloat = tileSize * 0.25
            let bubbleWidth = max(textFrame.width + paddingH * 2, tileSize * 2.6)
            let bubbleHeight = max(textFrame.height + paddingV * 2, tileSize * 0.9)
            let cornerRadius: CGFloat = tileSize * 0.2

            // --- Rounded-rect body ---
            let bodyRect = CGRect(
                x: -bubbleWidth / 2,
                y: 0,
                width: bubbleWidth,
                height: bubbleHeight
            )
            let bodyPath = CGPath(
                roundedRect: bodyRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            let bodyShape = SKShapeNode(path: bodyPath)
            bodyShape.fillColor = SKColor(red: 1, green: 0.98, blue: 0.92, alpha: 0.95)
            bodyShape.strokeColor = SKColor(red: 0.82, green: 0.72, blue: 0.55, alpha: 1)
            bodyShape.lineWidth = 1.5
            bubbleNode.addChild(bodyShape)

            // --- Small triangle pointer ---
            let triSize: CGFloat = tileSize * 0.18
            let triPath = CGMutablePath()
            triPath.move(to: CGPoint(x: -triSize, y: 0))
            triPath.addLine(to: CGPoint(x: 0, y: -triSize))
            triPath.addLine(to: CGPoint(x: triSize, y: 0))
            triPath.closeSubpath()
            let triShape = SKShapeNode(path: triPath)
            triShape.fillColor = bodyShape.fillColor
            triShape.strokeColor = bodyShape.strokeColor
            triShape.lineWidth = 1.5
            bubbleNode.addChild(triShape)

            // --- Center label in bubble ---
            label.position = CGPoint(x: 0, y: bubbleHeight / 2)
            bubbleNode.addChild(label)

            // --- Position bubble above cat ---
            bubbleNode.position = CGPoint(x: 0, y: cat.size.height * 0.85)
            cat.addChild(bubbleNode)

            // --- Animate: pop-in → hold → fade-out ---
            bubbleNode.setScale(0.3)
            bubbleNode.alpha = 0
            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.scale(to: 1.05, duration: 0.15),
            ])
            let settle = SKAction.scale(to: 1.0, duration: 0.08)
            let hold = SKAction.wait(forDuration: 2.5)
            let fadeOut = SKAction.group([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.moveBy(x: 0, y: tileSize * 0.3, duration: 0.5),
            ])
            bubbleNode.run(
                SKAction.sequence([popIn, settle, hold, fadeOut, SKAction.removeFromParent()])
            )
        }

        // MARK: - Auto-tip loop
        private func scheduleAutoTipLoop() {
            let key = CatWander.autoTipActionKey
            removeAction(forKey: key)

            let delay = SKAction.wait(
                forDuration: TimeInterval.random(
                    in: CatWander.autoTipMinInterval...CatWander.autoTipMaxInterval
                )
            )
            let showTip = SKAction.run { [weak self] in
                guard let self, !self.wanderCats.isEmpty, !self.isHungry else { return }
                // Pick a random cat that doesn't already have a tip bubble
                let candidates = self.wanderCats.filter {
                    $0.childNode(withName: CatWander.tipBubbleKey) == nil
                }
                guard let cat = candidates.randomElement() else { return }
                self.showWalkingTip(above: cat)
            }
            let reschedule = SKAction.run { [weak self] in
                self?.scheduleAutoTipLoop()
            }

            run(SKAction.sequence([delay, showTip, reschedule]), withKey: key)
        }

        // MARK: - Hunger system
        private func scheduleHungerTimer() {
            let key = CatWander.hungerActionKey
            removeAction(forKey: key)

            let delay = SKAction.wait(
                forDuration: TimeInterval.random(
                    in: CatWander.hungerMinInterval...CatWander.hungerMaxInterval
                )
            )
            let trigger = SKAction.run { [weak self] in
                self?.triggerHunger()
            }
            run(SKAction.sequence([delay, trigger]), withKey: key)
        }

        private func triggerHunger() {
            guard !isHungry, !wanderCats.isEmpty else {
                scheduleHungerTimer()
                return
            }
            isHungry = true

            // Dừng wander + chuyển laying cho tất cả mèo
            for cat in wanderCats {
                let moveKey = CatWander.movementActionKey(for: cat)
                let pauseKey = CatWander.tapPauseActionKey(for: cat)
                cat.removeAction(forKey: moveKey)
                cat.removeAction(forKey: pauseKey)
                cat.runLayingAnimation()
            }

            // Hiện hunger bubble trên mèo đầu tiên
            if let firstCat = wanderCats.first {
                showHungerBubble(above: firstCat)
            }

            onHungerStateChanged?(true)
        }

        private func showHungerBubble(above cat: SKSpriteNode) {
            cat.childNode(withName: CatWander.hungerBubbleKey)?.removeFromParent()

            let tipText = "Mèo đói rồi! 🍽️\nMua thức ăn nhé!"

            // --- Bubble container ---
            let bubbleNode = SKNode()
            bubbleNode.name = CatWander.hungerBubbleKey
            bubbleNode.zPosition = cat.zPosition + 2

            // --- Text label ---
            let fontSize: CGFloat = max(14, tileSize * 0.32)
            let label = SKLabelNode(fontNamed: GameTypography.skPixelFontName)
            label.text = tipText
            label.fontSize = fontSize
            label.fontColor = SKColor(red: 0.55, green: 0.12, blue: 0.12, alpha: 1)
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = tileSize * 3.2
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.lineBreakMode = .byWordWrapping

            // --- Measure text for bubble size ---
            let textFrame = label.frame
            let paddingH: CGFloat = tileSize * 0.35
            let paddingV: CGFloat = tileSize * 0.25
            let bubbleWidth = max(textFrame.width + paddingH * 2, tileSize * 2.6)
            let bubbleHeight = max(textFrame.height + paddingV * 2, tileSize * 0.9)
            let cornerRadius: CGFloat = tileSize * 0.2

            // --- Rounded-rect body (warm red tint) ---
            let bodyRect = CGRect(
                x: -bubbleWidth / 2,
                y: 0,
                width: bubbleWidth,
                height: bubbleHeight
            )
            let bodyPath = CGPath(
                roundedRect: bodyRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            let bodyShape = SKShapeNode(path: bodyPath)
            bodyShape.fillColor = SKColor(red: 1, green: 0.92, blue: 0.88, alpha: 0.95)
            bodyShape.strokeColor = SKColor(red: 0.85, green: 0.35, blue: 0.25, alpha: 1)
            bodyShape.lineWidth = 1.5
            bubbleNode.addChild(bodyShape)

            // --- Small triangle pointer ---
            let triSize: CGFloat = tileSize * 0.18
            let triPath = CGMutablePath()
            triPath.move(to: CGPoint(x: -triSize, y: 0))
            triPath.addLine(to: CGPoint(x: 0, y: -triSize))
            triPath.addLine(to: CGPoint(x: triSize, y: 0))
            triPath.closeSubpath()
            let triShape = SKShapeNode(path: triPath)
            triShape.fillColor = bodyShape.fillColor
            triShape.strokeColor = bodyShape.strokeColor
            triShape.lineWidth = 1.5
            bubbleNode.addChild(triShape)

            // --- Center label in bubble ---
            label.position = CGPoint(x: 0, y: bubbleHeight / 2)
            bubbleNode.addChild(label)

            // --- Position bubble above cat ---
            bubbleNode.position = CGPoint(x: 0, y: cat.size.height * 0.85)
            cat.addChild(bubbleNode)

            // --- Animate: pop-in + gentle pulse (stays visible) ---
            bubbleNode.setScale(0.3)
            bubbleNode.alpha = 0
            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.scale(to: 1.05, duration: 0.15),
            ])
            let settle = SKAction.scale(to: 1.0, duration: 0.08)
            let pulseUp = SKAction.scale(to: 1.04, duration: 0.8)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.scale(to: 0.97, duration: 0.8)
            pulseDown.timingMode = .easeInEaseOut
            let pulse = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
            bubbleNode.run(SKAction.sequence([popIn, settle, pulse]))
        }

        /// Cho mèo ăn — gọi từ `GameViewController` khi người chơi mua thức ăn.
        func feedCats() {
            guard isHungry else { return }
            isHungry = false

            // Xóa hunger bubble + resume wander cho tất cả mèo
            for cat in wanderCats {
                cat.childNode(withName: CatWander.hungerBubbleKey)?.removeFromParent()
                scheduleNextWanderStep(for: cat)
            }

            onHungerStateChanged?(false)
            scheduleHungerTimer()
        }
    }

    //MARK - Audio
    extension GameScene {
        private func prepareAudioPlayersIfNeeded() {
            if bgMusicPlayer == nil {
                bgMusicPlayer = makeAudioPlayer(
                    resource: "bg-cat-purr",
                    fileExtension: "mp3"
                )
                bgMusicPlayer?.numberOfLoops = -1
                bgMusicPlayer?.volume = normalBackgroundMusicVolume
                bgMusicPlayer?.prepareToPlay()
            }
            if meowPlayer == nil {
                meowPlayer = makeAudioPlayer(
                    resource: "cat-meow",
                    fileExtension: "mp3"
                )
                meowPlayer?.volume = 1.0
                meowPlayer?.prepareToPlay()
            }
        }

        private func syncBackgroundMusicPlaybackState() {
            guard let player = bgMusicPlayer else { return }
            player.volume = normalBackgroundMusicVolume
            if GameAudioSettings.isMusicEnabled {
                if !player.isPlaying { player.play() }
            } else {
                player.pause()
            }
        }

        private func setupAudio() {
            prepareAudioPlayersIfNeeded()
            syncBackgroundMusicPlaybackState()
        }

        func applyMusicEnabled(_ enabled: Bool) {
            GameAudioSettings.isMusicEnabled = enabled
            prepareAudioPlayersIfNeeded()
            syncBackgroundMusicPlaybackState()
        }

        func applySoundEffectsEnabled(_ enabled: Bool) {
            GameAudioSettings.isSoundEffectsEnabled = enabled
        }

        private func playMeowSound() {
            guard GameAudioSettings.isSoundEffectsEnabled else { return }
            prepareAudioPlayersIfNeeded()
            meowPlayer?.currentTime = 0
            meowPlayer?.play()
        }

        private func makeAudioPlayer(resource: String, fileExtension: String)
            -> AVAudioPlayer?
        {
            let url =
                Bundle.main.url(
                    forResource: resource,
                    withExtension: fileExtension,
                    subdirectory: "Sounds"
                )
                ?? Bundle.main.url(
                    forResource: resource,
                    withExtension: fileExtension
                )

            guard let url else {
                print("Khong tim thay file audio: \(resource).\(fileExtension)")
                return nil
            }

            do {
                return try AVAudioPlayer(contentsOf: url)
            } catch {
                print("Khong tao duoc audio player cho \(resource): \(error)")
                return nil
            }
        }
    }
#endif
