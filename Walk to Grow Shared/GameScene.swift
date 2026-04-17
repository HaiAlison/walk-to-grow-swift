//
//  GameScene.swift
//  Walk to Grow Shared
//
//  Created by Dzy on 30/3/26.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //MARK - Properties
    private let worldNode = SKNode()
    private var bgNode: SKSpriteNode!
    private var grassNode: GrassNode?
    private weak var wanderingCat: CatSheet1024Node?

    let tileSize: CGFloat = 54
    let mapWidth = 20
    let mapHeight = 20
    
    //MARK - Lifecycle
    override func didMove(to view: SKView) {
        self.setupNodes()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else { return }

         let position = touch.location(in: self)

         print("x:", position.x, "y:", position.y)
         
        let scenePosition = touch.location(in: self)
        guard let cat = wanderingCat else { return }
        if nodes(at: scenePosition).contains(where: { $0 === cat }) {
           handleCatTapped(cat)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
 
}

#if os(iOS) || os(tvOS)

//MARK - setup
extension GameScene{
    private func setupNodes(){
        backgroundColor = .blue

        // Căn giữa lưới map trong scene (gốc mặc định scene ở góc dưới-trái;
        // với aspectFill, nội dung gần (0,0) thường bị lệch ra ngoài vùng nhìn thấy).
        let mapW = CGFloat(mapWidth) * tileSize
        let mapH = CGFloat(mapHeight) * tileSize
        worldNode.position = CGPoint(x: size.width / 2 - mapW / 2, y: size.height / 2 - mapH / 2)
        addChild(worldNode)

        addBG()
        addGrass()
        spawnPets()
    }
}


//MARK - Background

extension GameScene{



    private func addBG(){
        bgNode = SKSpriteNode(imageNamed: "bg")
        bgNode.zPosition = -1.0
        bgNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        // Phủ full scene (aspectFill của riêng sprite để không méo)
        let scale = max(size.width / bgNode.size.width * 1.05, size.height / bgNode.size.height * 1.05)
        bgNode.setScale(scale)
        addChild(bgNode)
    }

    private func addGrass() {
        let node = GrassNode(columns: mapWidth, rows: mapHeight, tileSize: tileSize)
        node.zPosition = 0
        worldNode.addChild(node)
        grassNode = node
    }
 

    /// Mặc định: `normal_cat` (`CatNode`). Premium / skin: 1024×544 (`CatSheet1024Node`).
    func spawnPets() {
        let s = tileSize * 3
        let anchor = CGPoint(x: 0.5, y: 0.35)

        // let normalCat = CatNode(displaySize: CGSize(width: s, height: s))
        // normalCat.anchorPoint = anchor
        // normalCat.position = CGPoint(x: tileSize * 3.5, y: tileSize * 4.5)
        // normalCat.zPosition = 1
        // normalCat.runIdleAnimation()
        // worldNode.addChild(normalCat)

        let premiumCat = CatSheet1024Node(sheetImageName: "black_4", displaySize: CGSize(width: s, height: s))
        premiumCat.anchorPoint = anchor
        premiumCat.position = CGPoint(x: tileSize * 5.5, y: tileSize * 4.5)
        premiumCat.zPosition = 10.0
        premiumCat.runIdleAnimation()
        worldNode.addChild(premiumCat)
        wanderingCat = premiumCat
        scheduleNextWanderStep()
    }


}
#endif

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
  static let emojiKey = "cat_tap_emoji"
      static let resumeAfterTap: TimeInterval = 1.2
  static let emojis = ["😺", "😸", "😻", "😽", "😼", "🐾", "✨", "💤", "🍖", "💛"]

    }

    private func scheduleNextWanderStep() {
        guard let cat = wanderingCat else { return }

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
                    cat.runLayingAnimation(direction: moveDirection.spriteDirection)
                } else {
                    // "sitdown" tạm dùng idle hiện tại để tạo cảm giác ngồi nghỉ.
                    cat.runIdleAnimation()
                }
            }
            let restWait = SKAction.wait(forDuration: TimeInterval.random(in: CatWander.minRestDuration...CatWander.maxRestDuration))
            pause = SKAction.sequence([rest, restWait])
        } else {
            let shortPause = SKAction.wait(forDuration: TimeInterval.random(in: CatWander.minPause...CatWander.maxPause))
            let idle = SKAction.run { [weak cat] in
                cat?.runIdleAnimation()
            }
            pause = SKAction.sequence([shortPause, idle])
        }

        let next = SKAction.run { [weak self, weak cat] in
            guard let self, let cat else { return }
            self.scheduleNextWanderStep()
        }

        cat.removeAction(forKey: CatWander.movementKey)
        cat.run(SKAction.sequence([move, pause, next]), withKey: CatWander.movementKey)
    }

    private func randomWanderPoint(for cat: SKSpriteNode) -> (CGPoint, CatWander.WanderDirection) {
        let mapW = CGFloat(mapWidth) * tileSize
        let mapH = CGFloat(mapHeight) * tileSize

        let halfW = cat.size.width * 0.5
        let halfH = cat.size.height * 0.5

        let minX = halfW
        let maxX = mapW - halfW
        let minY = halfH
        let maxY = mapH - halfH

        let stepDistance = tileSize * CGFloat.random(in:  CatWander.minStepTiles...CatWander.maxStepTiles)
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

            if hypot(target.x - cat.position.x, target.y - cat.position.y) > 0.01 {
                return (target, direction)
            }
        }

        return (cat.position, .bottom)
    }
    private func handleCatTapped(_ cat: CatSheet1024Node) {
  cat.removeAction(forKey: CatWander.movementKey)
  cat.removeAction(forKey: CatWander.tapPauseKey)
  cat.runIdleAnimation()
  showRandomEmoji(above: cat)
  let resume = SKAction.run { [weak self] in
      self?.scheduleNextWanderStep()
  }
  cat.run(SKAction.sequence([SKAction.wait(forDuration: CatWander.resumeAfterTap), resume]), withKey: CatWander.tapPauseKey)
}
private func showRandomEmoji(above cat: SKSpriteNode) {
  cat.childNode(withName: CatWander.emojiKey)?.removeFromParent()
  let emojiNode = SKLabelNode(fontNamed: "AppleColorEmoji")
  emojiNode.name = CatWander.emojiKey
  emojiNode.text = CatWander.emojis.randomElement() ?? "😺"
  emojiNode.fontSize = max(28, tileSize * 0.7)
  emojiNode.verticalAlignmentMode = .center
  emojiNode.horizontalAlignmentMode = .center
  emojiNode.position = CGPoint(x: 0, y: cat.size.height * 0.9)
  emojiNode.zPosition = cat.zPosition + 1
  cat.addChild(emojiNode)
  let popIn = SKAction.scale(to: 1.08, duration: 0.1)
  let settle = SKAction.scale(to: 1.0, duration: 0.1)
  let floatUp = SKAction.moveBy(x: 0, y: tileSize * 0.6, duration: 0.8)
  let fadeOut = SKAction.fadeOut(withDuration: 0.8)
  let group = SKAction.group([floatUp, fadeOut])
  emojiNode.setScale(0.6)
  emojiNode.alpha = 0
  emojiNode.run(
      SKAction.sequence([
          SKAction.group([SKAction.fadeIn(withDuration: 0.12), popIn]),
          settle,
          group,
          SKAction.removeFromParent()
      ])
  )
}
}




