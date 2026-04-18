//
//  GrassNode.swift
//  Walk to Grow iOS
//

import SpriteKit

/// Nền cỏ theo lưới, gồm:
/// - `grass-tileset-dark-grass`: nền cỏ tĩnh
/// - `grass-daisy-animated-light-grass`: strip 8 frame (mỗi frame 128x128 = 4x4 tiles)
final class GrassNode: SKNode {

    private enum DaisySheet {
        static let frameCount = 8
        static let framePixelSize: CGFloat = 128
    }

    private let columns: Int
    private let rows: Int
    private let tileSize: CGFloat
    private let daisyTextures: [SKTexture]

    init(columns: Int, rows: Int, tileSize: CGFloat) {
        precondition(columns > 0 && rows > 0 && tileSize > 0)
        self.columns = columns
        self.rows = rows
        self.tileSize = tileSize
        self.daisyTextures = Self.makeDaisyFrameTextures()
        super.init()
        name = "grass_background"
        buildTiles()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeDaisyFrameTextures() -> [SKTexture] {
        let sheet = SKTexture(imageNamed: "grass-daisy-animated-light-grass")
        sheet.filteringMode = .nearest
        let fullWidth = DaisySheet.framePixelSize * CGFloat(DaisySheet.frameCount)
        let fullHeight = DaisySheet.framePixelSize

        return (0..<DaisySheet.frameCount).map { idx in
            let x = CGFloat(idx) * DaisySheet.framePixelSize / fullWidth
            let rect = CGRect(
                x: x,
                y: 0,
                width: DaisySheet.framePixelSize / fullWidth,
                height: DaisySheet.framePixelSize / fullHeight
            )
            let frame = SKTexture(rect: rect, in: sheet)
            frame.filteringMode = .nearest
            return frame
        }
    }

    private func buildTiles() {
        let baseTexture = SKTexture(imageNamed: "grass-tileset-light-grass")
        baseTexture.filteringMode = .nearest

        let baseLayer = SKNode()
        baseLayer.name = "grass_base_layer"
        baseLayer.zPosition = 0

        for row in 0..<rows {
            for col in 0..<columns {
                let x = (CGFloat(col) + 0.5) * tileSize
                let y = (CGFloat(row) + 0.5) * tileSize
                let position = CGPoint(x: x, y: y)

                let base = SKSpriteNode(texture: baseTexture, size: CGSize(width: tileSize, height: tileSize))
                base.position = position
                baseLayer.addChild(base)
            }
        }

        addChild(baseLayer)
        addAnimatedDaisyPatches()
    }

    /// Phủ full map bằng các patch cỏ hoa (mỗi patch là 1 frame 128x128 tương ứng 4x4 tiles) và animate 8 frame.
    private func addAnimatedDaisyPatches() {
        guard let firstFrame = daisyTextures.first else { return }

        let daisyLayer = SKNode()
        daisyLayer.name = "grass_daisy_layer"
        daisyLayer.zPosition = 2.0

        let patchSize = CGSize(width: tileSize * 4, height: tileSize * 4)
        let patchCols = Int(ceil(CGFloat(columns) / 4.0))
        let patchRows = Int(ceil(CGFloat(rows) / 4.0))

        for patchRow in 0..<patchRows {
            for patchCol in 0..<patchCols {
                let center = CGPoint(
                    x: (CGFloat(patchCol) * 4.0 + 2.0) * tileSize,
                    y: (CGFloat(patchRow) * 4.0 + 2.0) * tileSize
                )
                let index = patchRow * patchCols + patchCol

                let patch = SKSpriteNode(texture: firstFrame, size: patchSize)
                patch.position = center
                patch.alpha = 0.7
                patch.zPosition = 2.0
                daisyLayer.addChild(patch)

                let anim = SKAction.animate(with: daisyTextures, timePerFrame: 0.12, resize: false, restore: false)
                let delay = SKAction.wait(forDuration: TimeInterval(index % DaisySheet.frameCount) * 0.04)
                patch.run(.repeatForever(.sequence([delay, anim])))
            }
        }

        addChild(daisyLayer)
    }
}
