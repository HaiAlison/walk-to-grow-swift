//
//  ShopCatGridView.swift
//  Walk to Grow iOS
//

import SpriteKit
import UIKit

/// Lưới mèo SpriteKit (idle) cuộn trong panel cửa hàng.
final class ShopCatGridView: UIView {
    struct Model {
        var catSheetImageNames: [String]
        var pricePerCat: Int
        var coinsAvailable: Int
        var ownedCatIds: Set<String>
    }

    var onCatCellTapped: ((String) -> Void)?

    private let scrollView = UIScrollView()
    private let skView = SKView()
    private let gridScene = ShopGridScene()
    private let skViewHeightConstraint: NSLayoutConstraint
    private var lastModel: Model
    private var lastAppliedWidth: CGFloat = 0

    override init(frame: CGRect) {
        let initialModel = Model(
            catSheetImageNames: ShopCatalog.catSheetImageNames,
            pricePerCat: ShopCatalog.defaultCatPriceCoins,
            coinsAvailable: 0,
            ownedCatIds: []
        )
        lastModel = initialModel

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true

        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        skView.isMultipleTouchEnabled = false
        skView.isPaused = false

        skViewHeightConstraint = skView.heightAnchor.constraint(equalToConstant: 160)

        super.init(frame: frame)

        addSubview(scrollView)
        scrollView.addSubview(skView)

        gridScene.scaleMode = .resizeFill
        gridScene.backgroundColor = .clear
        gridScene.onCatCellTapped = { [weak self] id in
            self?.onCatCellTapped?(id)
        }
        skView.presentScene(gridScene)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            skView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            skView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            skView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            skViewHeightConstraint,
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModel(_ model: Model) {
        lastModel = model
        applyIfNeeded(force: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyIfNeeded(force: false)
    }

    private func applyIfNeeded(force: Bool) {
        let w = bounds.width
        guard w > 1 else { return }
        if !force, abs(w - lastAppliedWidth) < 0.5 { return }
        lastAppliedWidth = w

        let columns: Int
        if w >= 420 {
            columns = 4
        } else if w >= 300 {
            columns = 3
        } else {
            columns = 2
        }

        gridScene.configure(
            catNames: lastModel.catSheetImageNames,
            columnCount: columns,
            contentWidth: w,
            priceCoins: lastModel.pricePerCat,
            coinsAvailable: lastModel.coinsAvailable,
            ownedIds: lastModel.ownedCatIds
        )

        let h = gridScene.size.height
        skViewHeightConstraint.constant = max(h, 120)
        scrollView.layoutIfNeeded()
    }
}
