//
//  CatNode.swift
//  Walk to Grow iOS
//

import SpriteKit

/// Mèo **mặc định** (normal): sprite sheet `normal_cat` (256×320, lưới 8×10, mỗi ô 32×32).
final class CatNode: SKSpriteNode {

    private static let sheetImageName = "normal_cat"
    private static let columns = 8
    private static let rows = 10

    private let sheetTexture: SKTexture

    /// - Parameters:
    ///   - displaySize: Kích thước hiển thị (mặc định gần bằng một ô tile 32pt).
    init(displaySize: CGSize = CGSize(width: 32, height: 32)) {
        let sheet = SKTexture(imageNamed: Self.sheetImageName)
        sheet.filteringMode = .nearest
        sheetTexture = sheet
        let first = Self.frameTexture(sheet: sheet, col: 0, rowFromTop: 0)
        super.init(texture: first, color: .white, size: displaySize)
        name = "cat"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Cắt một ô trong sheet. `rowFromTop`: 0 = hàng trên cùng (idle).
    private static func frameTexture(sheet: SKTexture, col: Int, rowFromTop: Int) -> SKTexture {
        let w = 1.0 / CGFloat(columns)
        let h = 1.0 / CGFloat(rows)
        let yFromBottom = rows - 1 - rowFromTop
        let rect = CGRect(x: CGFloat(col) * w, y: CGFloat(yFromBottom) * h, width: w, height: h)
        let t = SKTexture(rect: rect, in: sheet)
        t.filteringMode = .nearest
        return t
    }

    private func textures(cols: Range<Int>, rowFromTop: Int) -> [SKTexture] {
        cols.map { Self.frameTexture(sheet: sheetTexture, col: $0, rowFromTop: rowFromTop) }
    }

    /// Hàng 1: ngồi idle (4 frame).
    func runIdleAnimation(timePerFrame: TimeInterval = 0.18) {
        removeAction(forKey: CatNode.animationKey)
        let frames = textures(cols: 0..<4, rowFromTop: 0)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: CatNode.animationKey)
    }

    /// Hàng 5: đi / chạy nhẹ (8 frame).
    func runWalkAnimation(timePerFrame: TimeInterval = 0.08) {
        removeAction(forKey: CatNode.animationKey)
        let frames = textures(cols: 0..<8, rowFromTop: 4)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: CatNode.animationKey)
    }

    func stopSpriteAnimation() {
        removeAction(forKey: CatNode.animationKey)
    }

    private static let animationKey = "cat_sheet_anim"
}
