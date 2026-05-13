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
    case feedback

    var title: String {
        switch self {
        case .routine:
            return "Routine"
        case .sound:
            return "Âm thanh"
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
    /// Skin mèo (imageset `cat_sheet_1024x544`) đã mua trong phiên hiện tại.
    private var ownedCatSkinIds = Set<String>()

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
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func show(tab: BottomTab) {
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

    func applyHomeState(_ state: HomePanelState) {
        homeState = state
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

        // contentStack.addArrangedSubview(makeInfoLabel("Vật phẩm"))
        // contentStack.addArrangedSubview(
        //     makeShopAccessoryRow(title: "Bánh cá (+năng lượng)", cost: 25)
        // )
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
        case .feedback:
            renderDeviceSettingsContent()
        }
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
