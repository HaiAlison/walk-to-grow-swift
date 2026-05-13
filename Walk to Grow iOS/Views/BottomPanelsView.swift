//
//  BottomPanelsView.swift
//  Walk to Grow iOS
//

import UIKit

struct HomePanelState {
    var todaySteps: Int
    var stepGoal: Int
    var activePetName: String
    var coins: Int
    var routineStreak: Int
    var checkinStreak: Int
    var isCheckinClaimedToday: Bool
    var latestCheckinRewardText: String?
}

struct ProfilePanelState {
    var playerName: String
    var level: Int
    var routineStreak: Int
    var checkinStreak: Int
    var weeklySteps: Int
}

struct SettingsPanelState {
    var selectedWeekdays: Set<Int>
    var stepGoal: Int
}

private enum SettingsSubTab: CaseIterable {
    case routine
    case sound
    case walkingTips
    case feedback

    var title: String {
        switch self {
        case .routine:
            return "Routine"
        case .sound:
            return "Âm thanh"
        case .walkingTips:
            return "Học tập"
        case .feedback:
            return "Thiết bị"
        }
    }

    var iconName: String {
        switch self {
        case .routine:
            return "figure.walk"
        case .sound:
            return "speaker.wave.2.fill"
        case .walkingTips:
            return "book.fill"
        case .feedback:
            return "iphone.radiowaves.left.and.right"
        }
    }
}

final class BottomPanelsView: UIView {
    var onMusicEnabledChanged: ((Bool) -> Void)?
    var onSoundEffectsEnabledChanged: ((Bool) -> Void)?
    var onCheckinClaimTapped: (() -> Void)?
    var onRoutineWeekdaysChanged: ((Set<Int>) -> Void)?
    /// Báo số xu đã chi (mua mèo / vật phẩm) để `GameViewController` cập nhật ví.
    var onShopCoinsSpent: ((Int) -> Void)?
    /// Gọi sau khi mua thành công skin mèo (`imageset` trong `cat_sheet_1024x544`).
    var onCatSkinPurchased: ((String) -> Void)?
    /// Mở URL (YouTube, web) trong trình duyệt trong app (`SFSafariViewController`).
    var onOpenExternalURL: ((URL) -> Void)?
    /// Chuyển sang Cài đặt → thẻ Học tập (thư viện mẹo đi bộ).
    var onRequestOpenTipLibrary: (() -> Void)?
    /// Người chơi mua thức ăn cho mèo đói.
    var onBuyFoodTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let contentStack = UIStackView()
    private var currentTab: BottomTab = .home
    private var selectedSettingsSubTab: SettingsSubTab = .routine

    private var musicOn = GameAudioSettings.isMusicEnabled
    private var soundOn = GameAudioSettings.isSoundEffectsEnabled
    private var vibrationOn = GameAudioSettings.isVibrationEnabled
    private var homeState = HomePanelState(
        todaySteps: 0,
        stepGoal: 0,
        activePetName: "Mèo đen",
        coins: 120,
        routineStreak: 0,
        checkinStreak: 0,
        isCheckinClaimedToday: false,
        latestCheckinRewardText: nil
    )
    private var profileState = ProfilePanelState(
        playerName: "Dzy",
        level: 3,
        routineStreak: 0,
        checkinStreak: 0,
        weeklySteps: 0
    )
    private var settingsState = SettingsPanelState(
        selectedWeekdays: [2, 3, 4, 5, 6],
        stepGoal: 8000
    )
    /// Nội dung serious game (đi bộ an toàn); nil nếu không đọc được JSON bundle.
    private let seriousWalkingTipsDocument: WalkingTipsDocument?
    /// Mẹo đang xem chi tiết trong Cài đặt → Học tập; nil = danh sách.
    private var seriousGameLibrarySelectionId: String?
    private var seriousWalkingTips: [WalkingTip] { seriousWalkingTipsDocument?.tips ?? [] }
    private var seriousDisclaimer: String {
        seriousWalkingTipsDocument?.disclaimer
            ?? "Nội dung chỉ mang tính tham khảo, không thay thế tư vấn y tế hay huấn luyện cá nhân."
    }
    /// Skin mèo (imageset `cat_sheet_1024x544`) đã mua trong phiên hiện tại.
    private var ownedCatSkinIds = Set<String>()
    /// Mèo đang đói — hiển thị nút mua thức ăn nổi bật.
    private var isCatHungry = false
    /// Chi phí thức ăn (xu).
    private let foodCost = 10

    /// Nền cửa hàng: lặp tile ảnh 32×32 (`UIColor(patternImage:)`).
    private let shopBackgroundPatternView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        v.clipsToBounds = true
        if let tile = UIImage(named: "cat-store-wall-cozy-wood") {
            v.backgroundColor = UIColor(patternImage: tile)
        }
        return v
    }()

    override init(frame: CGRect) {
        seriousWalkingTipsDocument = SeriousGameTipsRepository.loadDocument()
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        seriousWalkingTipsDocument = SeriousGameTipsRepository.loadDocument()
        super.init(coder: coder)
        setupUI()
    }

    func show(tab: BottomTab) {
        if tab != .settings {
            seriousGameLibrarySelectionId = nil
        }
        currentTab = tab
        switch tab {
        case .home:
            renderHomePanel()
        case .shop:
            renderShopPanel()
        case .profile:
            renderProfilePanel()
        case .settings:
            renderSettingsPanel()
        }
    }

    /// Mở Cài đặt tại thẻ Học tập (thư viện mẹo đi bộ). `GameViewController` nên gọi kèm `menuView.select(tab: .settings)`.
    func presentWalkingTipsLibrary() {
        seriousGameLibrarySelectionId = nil
        selectedSettingsSubTab = .walkingTips
        show(tab: .settings)
    }

    func applyHomeState(_ state: HomePanelState) {
        homeState = state
        if currentTab == .home {
            renderHomePanel()
        } else if currentTab == .shop {
            renderShopPanel()
        }
    }

    /// Cập nhật trạng thái đói và re-render panel hiện tại.
    func setCatHungry(_ hungry: Bool) {
        isCatHungry = hungry
        if currentTab == .home {
            renderHomePanel()
        } else if currentTab == .shop {
            renderShopPanel()
        }
    }

    func applyProfileState(_ state: ProfilePanelState) {
        profileState = state
        if currentTab == .profile {
            renderProfilePanel()
        }
    }

    func applySettingsState(_ state: SettingsPanelState) {
        settingsState = state
        if currentTab == .settings {
            renderSettingsPanel()
        }
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.66)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        isUserInteractionEnabled = true

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = GameTypography.uiFont(ofSize: 15)
        titleLabel.textColor = .white

        headerStack.addArrangedSubview(titleLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(shopBackgroundPatternView)
        addSubview(headerStack)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            shopBackgroundPatternView.topAnchor.constraint(equalTo: topAnchor),
            shopBackgroundPatternView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shopBackgroundPatternView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shopBackgroundPatternView.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            contentStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }

    private func applyShopBackgroundStyle(isShop: Bool) {
        shopBackgroundPatternView.isHidden = !isShop
        backgroundColor =
            isShop
            ? .clear
            : UIColor.black.withAlphaComponent(0.66)
    }

    private func clearContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func renderHomePanel() {
        titleLabel.text = "Trang chủ"
        applyShopBackgroundStyle(isShop: false)
        clearContent()
        contentStack.addArrangedSubview(
            makeInfoLabel("Nhiệm vụ hôm nay: đi bộ \(homeState.stepGoal.formatted()) bước")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Tiến độ hôm nay: \(homeState.todaySteps.formatted())/\(homeState.stepGoal.formatted()) bước")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Thú cưng đang hoạt động: \(homeState.activePetName)")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Số xu hiện có: \(homeState.coins.formatted())")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Chuỗi vận động: \(homeState.routineStreak) ngày")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Chuỗi điểm danh: \(homeState.checkinStreak) ngày")
        )
        contentStack.addArrangedSubview(makeSeriousGameHomeSection())
        if isCatHungry {
            contentStack.addArrangedSubview(makeHungerWarningBanner())
        }
        if homeState.isCheckinClaimedToday {
            let rewardText = homeState.latestCheckinRewardText ?? "Đã nhận thưởng hôm nay"
            contentStack.addArrangedSubview(makeInfoLabel("Điểm danh: \(rewardText)"))
        } else {
            contentStack.addArrangedSubview(makeCheckinButton())
        }
    }

    private func renderShopPanel() {
        titleLabel.text = "Cửa hàng"
        applyShopBackgroundStyle(isShop: true)
        clearContent()

        if isCatHungry {
            contentStack.addArrangedSubview(makeHungerFoodRow())
        }
        contentStack.addArrangedSubview(
            makeInfoLabel(
                "Mỗi skin mèo \(ShopCatalog.defaultCatPriceCoins) xu. Chạm mèo để mua."
            )
        )

        let grid = ShopCatGridView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.heightAnchor.constraint(equalToConstant: 360).isActive = true
        grid.onCatCellTapped = { [weak self] sheetId in
            self?.purchaseCatSkinIfPossible(sheetId: sheetId)
        }
        grid.setModel(
            ShopCatGridView.Model(
                catSheetImageNames: ShopCatalog.catSheetImageNames,
                pricePerCat: ShopCatalog.defaultCatPriceCoins,
                coinsAvailable: homeState.coins,
                ownedCatIds: ownedCatSkinIds
            )
        )
        contentStack.addArrangedSubview(grid)

        contentStack.addArrangedSubview(makeInfoLabel("Vật phẩm"))
        contentStack.addArrangedSubview(
            makeShopAccessoryRow(title: "Bánh cá (+năng lượng)", cost: 25)
        )
        // contentStack.addArrangedSubview(
        //     makeShopAccessoryRow(title: "Nơ cổ cao cấp", cost: 80)
        // )
        contentStack.addArrangedSubview(
            makeInfoLabel("Xu còn lại: \(homeState.coins)")
        )
    }

    private func purchaseCatSkinIfPossible(sheetId: String) {
        let price = ShopCatalog.defaultCatPriceCoins
        guard !ownedCatSkinIds.contains(sheetId) else { return }
        guard homeState.coins >= price else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        ownedCatSkinIds.insert(sheetId)
        onShopCoinsSpent?(price)
        onCatSkinPurchased?(sheetId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Hunger UI helpers

    /// Banner cảnh báo đói trên Home panel.
    private func makeHungerWarningBanner() -> UIView {
        let banner = UIView()
        banner.backgroundColor = UIColor.systemRed.withAlphaComponent(0.25)
        banner.layer.cornerRadius = 10
        banner.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.6).cgColor
        banner.layer.borderWidth = 1

        let label = UILabel()
        label.text = "🍽️ Mèo đang đói! Vào cửa hàng mua thức ăn!"
        label.textColor = .white
        label.font = GameTypography.uiFont(ofSize: 12)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -10),
        ])
        return banner
    }

    /// Hàng mua thức ăn nổi bật khi mèo đói — hiện ở đầu Shop panel.
    private func makeHungerFoodRow() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        container.layer.cornerRadius = 12
        container.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.6).cgColor
        container.layer.borderWidth = 1.5

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let emoji = UILabel()
        emoji.text = "🍽️"
        emoji.font = .systemFont(ofSize: 28)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let title = UILabel()
        title.text = "Mèo đang đói!"
        title.textColor = .systemOrange
        title.font = GameTypography.uiFont(ofSize: 13)

        let subtitle = UILabel()
        subtitle.text = "Mua thức ăn để mèo hoạt động lại"
        subtitle.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitle.font = GameTypography.uiFont(ofSize: 10)

        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)

        let canAfford = homeState.coins >= foodCost

        var buyConfig = UIButton.Configuration.filled()
        buyConfig.title = canAfford ? "Mua \(foodCost) xu" : "Thiếu xu"
        buyConfig.baseBackgroundColor = canAfford ? .systemOrange : .systemGray
        buyConfig.baseForegroundColor = .white
        buyConfig.cornerStyle = .medium
        applyPixelButtonTitle(&buyConfig, fontSize: 11)

        let buyButton = UIButton(type: .system)
        buyButton.configuration = buyConfig
        buyButton.isEnabled = canAfford
        buyButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onBuyFoodTapped?()
        }, for: .touchUpInside)
        buyButton.setContentHuggingPriority(.required, for: .horizontal)

        stack.addArrangedSubview(emoji)
        stack.addArrangedSubview(textStack)
        stack.addArrangedSubview(buyButton)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])
        return container
    }

    /// Hàng vật phẩm: ô icon để trống (chưa có asset), tên + nút mua.
    private func makeShopAccessoryRow(title: String, cost: Int) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        let iconSlot = UIView()
        iconSlot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconSlot.widthAnchor.constraint(equalToConstant: 48),
            iconSlot.heightAnchor.constraint(equalToConstant: 48),
        ])

        let nameLabel = UILabel()
        nameLabel.text = title
        nameLabel.textColor = .white
        nameLabel.font = GameTypography.uiFont(ofSize: 11)
        nameLabel.numberOfLines = 0
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(iconSlot)
        row.addArrangedSubview(nameLabel)

        let buy = makeItemBuyButton(cost: cost)
        buy.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(buy)
        return row
    }

    private func makeItemBuyButton(cost: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Mua \(cost) xu"
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        applyPixelButtonTitle(&config, fontSize: 10)

        let button = UIButton(type: .system)
        button.configuration = config
        button.contentHorizontalAlignment = .center
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            guard self.homeState.coins >= cost else { return }
            self.onShopCoinsSpent?(cost)
            self.profileState.level = min(self.profileState.level + 1, 99)
        }, for: .touchUpInside)
        return button
    }

    private func renderProfilePanel() {
        titleLabel.text = "Hồ sơ"
        applyShopBackgroundStyle(isShop: false)
        clearContent()
        contentStack.addArrangedSubview(makeInfoLabel("Tên người chơi: \(profileState.playerName)"))
        contentStack.addArrangedSubview(makeInfoLabel("Cấp độ: \(profileState.level)"))
        contentStack.addArrangedSubview(
            makeInfoLabel("Chuỗi vận động (Routine): \(profileState.routineStreak) ngày")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Chuỗi điểm danh (Daily Check-in): \(profileState.checkinStreak) ngày")
        )
        contentStack.addArrangedSubview(
            makeInfoLabel("Tổng bước tuần này: \(profileState.weeklySteps.formatted())")
        )
    }

    private func renderSettingsPanel() {
        titleLabel.text = "Cài đặt"
        applyShopBackgroundStyle(isShop: false)
        clearContent()
        contentStack.addArrangedSubview(makeSettingsSubTabBar())
        musicOn = GameAudioSettings.isMusicEnabled
        soundOn = GameAudioSettings.isSoundEffectsEnabled
        vibrationOn = GameAudioSettings.isVibrationEnabled
        switch selectedSettingsSubTab {
        case .routine:
            renderRoutineSettingsContent()
        case .sound:
            renderSoundSettingsContent()
        case .walkingTips:
            renderWalkingTipsSettingsContent()
        case .feedback:
            renderDeviceSettingsContent()
        }
    }

    private func renderWalkingTipsSettingsContent() {
        contentStack.addArrangedSubview(makeDisclaimerLabel(seriousDisclaimer))
        if seriousWalkingTips.isEmpty {
            contentStack.addArrangedSubview(
                makeInfoLabel("Không tải được danh sách mẹo. Kiểm tra file WalkingTips.json trong bundle.")
            )
            return
        }
        if let selId = seriousGameLibrarySelectionId,
           let tip = seriousWalkingTips.first(where: { $0.id == selId }) {
            contentStack.addArrangedSubview(makeWalkingTipDetailColumn(for: tip))
        } else {
            contentStack.addArrangedSubview(makeWalkingTipsLibraryScroll())
        }
    }

    private func makeWalkingTipsLibraryScroll() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        for tip in seriousWalkingTips {
            stack.addArrangedSubview(makeTipTitleRowButton(tip: tip))
        }

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.heightAnchor.constraint(equalToConstant: 280),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])
        return scroll
    }

    private func makeTipTitleRowButton(tip: WalkingTip) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = tip.title
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.15)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.titleAlignment = .leading
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        applyPixelButtonTitle(&config, fontSize: 11)
        let button = UIButton(type: .system)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            self?.seriousGameLibrarySelectionId = tip.id
            self?.renderSettingsPanel()
        }, for: .touchUpInside)
        return button
    }

    private func makeWalkingTipDetailColumn(for tip: WalkingTip) -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 10

        var backConfig = UIButton.Configuration.tinted()
        backConfig.title = "← Danh sách"
        backConfig.baseBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        backConfig.baseForegroundColor = .white
        backConfig.cornerStyle = .medium
        applyPixelButtonTitle(&backConfig, fontSize: 11)
        let back = UIButton(type: .system)
        back.configuration = backConfig
        back.contentHorizontalAlignment = .leading
        back.addAction(UIAction { [weak self] _ in
            self?.seriousGameLibrarySelectionId = nil
            self?.renderSettingsPanel()
        }, for: .touchUpInside)
        column.addArrangedSubview(back)

        let title = makeInfoLabel(tip.title)
        title.font = GameTypography.uiFont(ofSize: 13)
        column.addArrangedSubview(title)

        let body = makeInfoLabel(tip.body)
        body.font = GameTypography.uiFont(ofSize: 12)
        column.addArrangedSubview(body)

        if let s = tip.youtubeURL, let url = URL(string: s) {
            column.addArrangedSubview(makeOpenURLButton(title: "Mở video trên YouTube", url: url))
        } else {
            column.addArrangedSubview(
                makeInfoLabel("Mục này chưa gắn video — bạn có thể xem các mục khác có nút YouTube.")
            )
        }
        return column
    }

    private func makeOpenURLButton(title: String, url: URL) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        applyPixelButtonTitle(&config, fontSize: 11)
        let button = UIButton(type: .system)
        button.configuration = config
        button.contentHorizontalAlignment = .center
        button.addAction(UIAction { [weak self] _ in
            self?.onOpenExternalURL?(url)
        }, for: .touchUpInside)
        return button
    }

    private func makeDisclaimerLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = UIColor.white.withAlphaComponent(0.55)
        label.font = GameTypography.uiFont(ofSize: 9)
        return label
    }

    private func makeSeriousGameHomeSection() -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 8

        let heading = UILabel()
        heading.text = "Mẹo hôm nay (đi bộ / vận động nhẹ)"
        heading.font = GameTypography.uiFont(ofSize: 13)
        heading.textColor = .systemYellow
        column.addArrangedSubview(heading)

        guard let tip = SeriousGameTipsRepository.dailyTip(from: seriousWalkingTips) else {
            column.addArrangedSubview(
                makeInfoLabel("Chưa có nội dung. Thêm file WalkingTips.json vào bundle để hiển thị mẹo.")
            )
            return column
        }

        column.addArrangedSubview(makeInfoLabel(tip.title))
        let body = makeInfoLabel(tip.body)
        body.font = GameTypography.uiFont(ofSize: 11)
        column.addArrangedSubview(body)

        if let s = tip.youtubeURL, let url = URL(string: s) {
            column.addArrangedSubview(makeOpenURLButton(title: "Xem video gợi ý", url: url))
        }

        column.addArrangedSubview(makeOpenLibraryFromHomeButton())
        column.addArrangedSubview(makeDisclaimerLabel(seriousDisclaimer))
        return column
    }

    private func makeOpenLibraryFromHomeButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Mở thư viện mẹo đi bộ"
        config.baseBackgroundColor = UIColor.systemTeal
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        applyPixelButtonTitle(&config, fontSize: 11)
        let button = UIButton(type: .system)
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.onRequestOpenTipLibrary?()
        }, for: .touchUpInside)
        return button
    }

    private func renderRoutineSettingsContent() {
        contentStack.addArrangedSubview(
            makeInfoLabel("Thiết lập ngày chạy để tính chuỗi vận động. Mục tiêu: \(settingsState.stepGoal.formatted()) bước/ngày.")
        )

        let rowOne = UIStackView()
        rowOne.axis = .horizontal
        rowOne.spacing = 8
        rowOne.distribution = .fillEqually
        rowOne.addArrangedSubview(makeWeekdayButton(2, title: "T2"))
        rowOne.addArrangedSubview(makeWeekdayButton(3, title: "T3"))
        rowOne.addArrangedSubview(makeWeekdayButton(4, title: "T4"))
        rowOne.addArrangedSubview(makeWeekdayButton(5, title: "T5"))
        contentStack.addArrangedSubview(rowOne)

        let rowTwo = UIStackView()
        rowTwo.axis = .horizontal
        rowTwo.spacing = 8
        rowTwo.distribution = .fillEqually
        rowTwo.addArrangedSubview(makeWeekdayButton(6, title: "T6"))
        rowTwo.addArrangedSubview(makeWeekdayButton(7, title: "T7"))
        rowTwo.addArrangedSubview(makeWeekdayButton(1, title: "CN"))
        let spacer = UIView()
        rowTwo.addArrangedSubview(spacer)
        contentStack.addArrangedSubview(rowTwo)
    }

    private func renderSoundSettingsContent() {
        contentStack.addArrangedSubview(makeSwitchRow(title: "Nhạc nền", isOn: musicOn) { [weak self] value in
            self?.musicOn = value
            GameAudioSettings.isMusicEnabled = value
            self?.onMusicEnabledChanged?(value)
        })
        contentStack.addArrangedSubview(makeSwitchRow(title: "Hiệu ứng âm thanh", isOn: soundOn) { [weak self] value in
            self?.soundOn = value
            GameAudioSettings.isSoundEffectsEnabled = value
            self?.onSoundEffectsEnabledChanged?(value)
        })
    }

    private func renderDeviceSettingsContent() {
        contentStack.addArrangedSubview(makeSwitchRow(title: "Rung", isOn: vibrationOn) { [weak self] value in
            self?.vibrationOn = value
            GameAudioSettings.isVibrationEnabled = value
        })
    }

    private func makeInfoLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = .white
        label.font = GameTypography.uiFont(ofSize: 12)
        return label
    }

    private func applyPixelButtonTitle(
        _ config: inout UIButton.Configuration,
        fontSize: CGFloat = 11
    ) {
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            incoming in
            var out = incoming
            out.font = GameTypography.uiFont(ofSize: fontSize)
            return out
        }
    }

    private func makeCheckinButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "Điểm danh nhận thưởng"
        config.baseBackgroundColor = .systemOrange
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        applyPixelButtonTitle(&config, fontSize: 11)

        let button = UIButton(type: .system)
        button.configuration = config
        button.contentHorizontalAlignment = .center
        button.addAction(UIAction { [weak self] _ in
            self?.onCheckinClaimTapped?()
        }, for: .touchUpInside)
        return button
    }

    private func makeSwitchRow(title: String, isOn: Bool, changed: @escaping (Bool) -> Void) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = GameTypography.uiFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = .systemGreen
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addAction(UIAction { _ in
            changed(toggle.isOn)
        }, for: .valueChanged)

        container.addSubview(label)
        container.addSubview(toggle)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: toggle.centerYAnchor),

            toggle.topAnchor.constraint(equalTo: container.topAnchor),
            toggle.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toggle.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            label.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),
        ])
        return container
    }

    private func makeSettingsSubTabBar() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually

        SettingsSubTab.allCases.forEach { subTab in
            stack.addArrangedSubview(makeSettingsSubTabButton(for: subTab))
        }
        return stack
    }

    private func makeSettingsSubTabButton(for subTab: SettingsSubTab) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.tinted()
        config.title = subTab.title
        config.image = UIImage(systemName: subTab.iconName)
        config.imagePlacement = .top
        config.imagePadding = 6
        config.cornerStyle = .medium
        let isSelected = subTab == selectedSettingsSubTab
        config.baseBackgroundColor = isSelected ? .systemGreen : UIColor.white.withAlphaComponent(0.12)
        config.baseForegroundColor = .white
        applyPixelButtonTitle(&config, fontSize: 9)
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.selectedSettingsSubTab = subTab
            self?.renderSettingsPanel()
        }, for: .touchUpInside)
        return button
    }

    private func makeWeekdayButton(_ weekday: Int, title: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        let isSelected = settingsState.selectedWeekdays.contains(weekday)
        config.baseBackgroundColor = isSelected ? .systemGreen : UIColor.white.withAlphaComponent(0.2)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        applyPixelButtonTitle(&config, fontSize: 10)
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.toggleWeekday(weekday)
        }, for: .touchUpInside)
        return button
    }

    private func toggleWeekday(_ weekday: Int) {
        var selected = settingsState.selectedWeekdays
        if selected.contains(weekday) {
            if selected.count == 1 {
                return
            }
            selected.remove(weekday)
        } else {
            selected.insert(weekday)
        }
        settingsState.selectedWeekdays = selected
        onRoutineWeekdaysChanged?(selected)
        renderSettingsPanel()
    }
}
