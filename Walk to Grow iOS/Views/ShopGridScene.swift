//
//  ShopGridScene.swift
//  Walk to Grow iOS
//

import SpriteKit
import UIKit

final class ShopGridScene: SKScene {
    var onCatCellTapped: ((String) -> Void)?

    func configure(
        catNames: [String],
        columnCount: Int,
        contentWidth: CGFloat,
        priceCoins: Int,
        coinsAvailable: Int,
        ownedIds: Set<String>
    ) {
        removeAllChildren()
        backgroundColor = .clear

        let columns = max(1, columnCount)
        let colWidth = contentWidth / CGFloat(columns)
        let catDisplay = min(56, colWidth * 0.62)
        let rowHeight: CGFloat = catDisplay + 44
        let topPad: CGFloat = 8
        let bottomPad: CGFloat = 12
        let rows = (catNames.count + columns - 1) / columns
        let sceneH = topPad + CGFloat(rows) * rowHeight + bottomPad
        size = CGSize(width: contentWidth, height: sceneH)

        let fontName = GameTypography.skPixelFontName

        for (index, sheetName) in catNames.enumerated() {
            let col = index % columns
            let row = index / columns
            let cx = colWidth * (CGFloat(col) + 0.5)
            let cy = sceneH - topPad - CGFloat(row) * rowHeight - rowHeight * 0.5

            let root = SKNode()
            root.name = "shopcat.\(sheetName)"
            root.position = CGPoint(x: cx, y: cy)

            guard UIImage(named: sheetName) != nil else { continue }

            let cat = CatSheet1024Node(
                sheetImageName: sheetName,
                displaySize: CGSize(width: catDisplay, height: catDisplay)
            )
            cat.anchorPoint = CGPoint(x: 0.5, y: 0.35)
            cat.position = CGPoint(x: 0, y: rowHeight * 0.08)
            let owned = ownedIds.contains(sheetName)
            cat.alpha = owned ? 0.45 : 1.0
            cat.runIdleAnimation(timePerFrame: 0.22, direction: .bottom)
            root.addChild(cat)

            let price = SKLabelNode(fontNamed: fontName)
            price.fontSize = 9
            price.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            price.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
            price.position = CGPoint(x: 0, y: -rowHeight * 0.38)

            if owned {
                price.text = "Đã có"
                price.fontColor = SKColor(white: 0.75, alpha: 1)
            } else if coinsAvailable < priceCoins {
                price.text = "\(priceCoins) xu"
                price.fontColor = SKColor.systemRed.withAlphaComponent(0.9)
            } else {
                price.text = "\(priceCoins) xu"
                price.fontColor = SKColor.white
            }
            root.addChild(price)
            addChild(root)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            if let name = current.name, name.hasPrefix("shopcat.") {
                let id = String(name.dropFirst("shopcat.".count))
                onCatCellTapped?(id)
                return
            }
            node = current.parent
        }
    }
}
