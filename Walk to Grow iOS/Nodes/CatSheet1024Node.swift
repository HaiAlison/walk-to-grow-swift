//
//  CatSheet1024Node.swift
//  Walk to Grow iOS
//

import SpriteKit

/// Mèo **premium** / biến thể: sprite sheet 1024×544 trong nhóm `cat_sheet_1024x544` (tên imageset, ví dụ `orange_3`, `black_4`).
/// Hàng đầu là nhãn + khung (SITTING DOWN, …); **không** tính vào lưới frame.
/// Vùng sprite: 24×16 ô × 32px, bắt đầu dưới header 32px; 768px trái là 6 nhóm × 4 frame.
final class CatSheet1024Node: SKSpriteNode {

    private static let texturePixelWidth: CGFloat = 1024
    private static let texturePixelHeight: CGFloat = 544
    private static let headerHeight: CGFloat = 32
    private static let cell: CGFloat = 32
    private static let spriteColumns = 24
    private static let spriteRows = 16

    private enum Sheet {
        static let sittingCols = 0..<4
        static let lookingCols = 4..<8
        static let layingCols = 8..<12
        static let walkingCols = 12..<16
        static let runningCols = 16..<20
        static let running2Cols = 20..<23
    }

    private let sheetTexture: SKTexture

    /// - Parameters:
    ///   - sheetImageName: Tên imageset trong catalog (ví dụ `orange_3`).
    ///   - nodeName: `SKNode.name`; mặc định trùng `sheetImageName`.
    init(sheetImageName: String, displaySize: CGSize = CGSize(width: 32, height: 32), nodeName: String? = nil) {
        let sheet = SKTexture(imageNamed: sheetImageName)
        sheet.filteringMode = .nearest
        sheetTexture = sheet
        let first = Self.frameTexture(sheet: sheet, col: Sheet.sittingCols.lowerBound, rowFromTop: 0)
        super.init(texture: first, color: .white, size: displaySize)
        name = nodeName ?? sheetImageName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func frameTexture(sheet: SKTexture, col: Int, rowFromTop: Int) -> SKTexture {
        precondition((0..<spriteColumns).contains(col))
        precondition((0..<spriteRows).contains(rowFromTop))

        let px = CGFloat(col) * cell
        let py = headerHeight + CGFloat(rowFromTop) * cell
        let W = texturePixelWidth
        let H = texturePixelHeight

        let nx = px / W
        let nw = cell / W
        let nh = cell / H
        let ny = (H - py - cell) / H

        let rect = CGRect(x: nx, y: ny, width: nw, height: nh)
        let t = SKTexture(rect: rect, in: sheet)
        t.filteringMode = .nearest
        return t
    }

    private func textures(cols: Range<Int>, rowFromTop: Int) -> [SKTexture] {
        cols.map { Self.frameTexture(sheet: sheetTexture, col: $0, rowFromTop: rowFromTop) }
    }

    func runIdleAnimation(timePerFrame: TimeInterval = 0.18) {
        removeAction(forKey: Self.animationKey)
        let frames = textures(cols: Sheet.sittingCols, rowFromTop: 0)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: Self.animationKey)
    }

    func runWalkAnimation(timePerFrame: TimeInterval = 0.08) {
        removeAction(forKey: Self.animationKey)
        let frames = textures(cols: Sheet.walkingCols, rowFromTop: 2)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: Self.animationKey)
    }

    func runLayingAnimation(timePerFrame: TimeInterval = 0.18) {
        removeAction(forKey: Self.animationKey)
        let frames = textures(cols: Sheet.layingCols, rowFromTop: 15)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: Self.animationKey)
    }
    func runLookingAroundAnimation(timePerFrame: TimeInterval = 0.28) {
        removeAction(forKey: Self.animationKey)
        let frames = textures(cols: Sheet.lookingCols, rowFromTop: 0)
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: Self.animationKey)
    }

    func stopSpriteAnimation() {
        removeAction(forKey: Self.animationKey)
    }

    private static let animationKey = "cat_sheet_1024_anim"
}
