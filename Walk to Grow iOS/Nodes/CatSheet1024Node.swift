//
//  CatSheet1024Node.swift
//  Walk to Grow iOS
//

import SpriteKit

/// Hướng trên lưới sprite: mỗi hướng chiếm **2 hàng** liên tiếp (hàng trên / hàng dưới).
enum Direction: Int {
    case bottom = 0
    case bottomLeft
    case left
    case topLeft
    case top
    case topRight
    case right
    case bottomRight

    var rows: [Int] {
        let start = rawValue * 2
        return [start, start + 1]
    }
}

/// Mèo **premium** / biến thể: sprite sheet 1024×544 trong nhóm `cat_sheet_1024x544` (tên imageset, ví dụ `orange_3`, `black_4`).
/// Hàng đầu là nhãn + khung (SITTING DOWN, …); **không** tính vào lưới frame.
/// Vùng sprite: 24×16 ô × 32px, bắt đầu dưới header 32px; 768px trái là 6 nhóm × 4 frame.
final class CatSheet1024Node: SKSpriteNode {

    /// Hành động = dải **cột** cố định trên sheet + số frame thật (có thể nhỏ hơn số ô trong dải).
    enum CatAction {
        case sitting
        case lookingAround
        case walking
        case running
        case running2
        /// Nằm: một hàng cố định trên sheet (không theo cặp `Direction.rows`).
        case laying

        var cols: Range<Int> {
            switch self {
            case .sitting: return Sheet.sittingCols
            case .lookingAround: return Sheet.lookingCols
            case .walking: return Sheet.walkingCols
            case .laying: return Sheet.layingCols
            case .running: return Sheet.runningCols
            case .running2: return Sheet.running2Cols
            }
        }

        func frameCount(for direction: Direction) -> Int {
            switch self {
                case .sitting:
                    switch direction {
                    case .bottom, .top: return 7
                    case .bottomLeft, .left, .topLeft, .topRight, .right, .bottomRight: return 6
                    }
                case .lookingAround, .running:
                    return 5
                case .laying, .running2:
                    return 8
                case .walking:
                return 4
            }
        }
        /// Hàng dùng khi ghép frame: mặc định theo hướng; đi bộ chỉ dùng **một** hàng mỗi hướng.
        func rowsFromTop(for direction: Direction) -> [Int] {
            switch self {
            case .sitting, .lookingAround, .laying, .running, .running2:
                return direction.rows
            case .walking:
                return [direction.rows[0]]
           
            }
        }
    }

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

    /// Ghép frame theo thứ tự: duyệt từng row trong `rowsFromTop`, trong mỗi row duyệt trái -> phải theo `cols`.
    /// Dùng `frameCount` để cắt đúng số frame thật (ví dụ 7 frame trên 2 rows x 4 cột).
    private func textures(cols: Range<Int>, rowsFromTop: [Int], frameCount: Int) -> [SKTexture] {
        let ordered = rowsFromTop.flatMap { row in
            cols.map { col in
                Self.frameTexture(sheet: sheetTexture, col: col, rowFromTop: row)
            }
        }
        return Array(ordered.prefix(max(0, frameCount)))
    }

    /// Dựng frame từ `action` + `direction`, chạy lặp `SKAction.animate`.
    func runAnimation(action: CatAction, direction: Direction, timePerFrame: TimeInterval) {
        removeAction(forKey: Self.animationKey)
        let rows = action.rowsFromTop(for: direction)
        let frameCount = action.frameCount(for: direction)
        let frames: [SKTexture]
        if rows.count == 1 {
            frames = Array(textures(cols: action.cols, rowFromTop: rows[0]).prefix(max(0, frameCount)))
        } else {
            frames = textures(cols: action.cols, rowsFromTop: rows, frameCount: frameCount)
        }
        let anim = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: true)
        run(SKAction.repeatForever(anim), withKey: Self.animationKey)
    }

    func runIdleAnimation(timePerFrame: TimeInterval = 0.2, direction: Direction = .bottom) {
        runAnimation(action: .sitting, direction: direction, timePerFrame: timePerFrame)
    }

    /// Mặc định `.left` để khớp hành vi cũ (trước đây cố định `rowFromTop: 2`).
    func runWalkAnimation(timePerFrame: TimeInterval = 0.08, direction: Direction = .bottomLeft) {
        runAnimation(action: .walking, direction: direction, timePerFrame: timePerFrame)
    }
    
    func runLayingAnimation(timePerFrame: TimeInterval = 0.18, direction: Direction = .bottom) {
        runAnimation(action: .laying, direction: direction, timePerFrame: timePerFrame)
    }

    func runLookingAroundAnimation(timePerFrame: TimeInterval = 0.28, direction: Direction = .bottom) {
        runAnimation(action: .lookingAround, direction: direction, timePerFrame: timePerFrame)
    }
    

    func stopSpriteAnimation() {
        removeAction(forKey: Self.animationKey)
    }

    private static let animationKey = "cat_sheet_1024_anim"
}
