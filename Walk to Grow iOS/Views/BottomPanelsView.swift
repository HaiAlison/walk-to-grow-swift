//
//  BottomPanelsView.swift
//  Walk to Grow iOS
//

import UIKit

final class BottomPanelsView: UIView {
    var onMusicEnabledChanged: ((Bool) -> Void)?
    var onSoundEffectsEnabledChanged: ((Bool) -> Void)?

    private let titleLabel = UILabel()
    private let contentStack = UIStackView()

    private var coins: Int = 120
    private var playerLevel: Int = 3
    private var musicOn = GameAudioSettings.isMusicEnabled
    private var soundOn = GameAudioSettings.isSoundEffectsEnabled
    private var vibrationOn = GameAudioSettings.isVibrationEnabled

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func show(tab: BottomTab) {
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

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white

        headerStack.addArrangedSubview(titleLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerStack)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            contentStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }

    private func clearContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func renderHomePanel() {
        titleLabel.text = "Trang chủ"
        clearContent()
        contentStack.addArrangedSubview(makeInfoLabel("Nhiệm vụ hôm nay: đi bộ 2,000 bước"))
        contentStack.addArrangedSubview(makeInfoLabel("Thú cưng đang hoạt động: Mèo đen"))
        contentStack.addArrangedSubview(makeInfoLabel("Số xu hiện có: \(coins)"))
    }

    private func renderShopPanel() {
        titleLabel.text = "Cửa hàng"
        clearContent()
        contentStack.addArrangedSubview(makeInfoLabel("Mua vật phẩm để nâng cấp thú cưng"))
        contentStack.addArrangedSubview(makeBuyButton(title: "Bánh cá (+năng lượng) - 25 xu", cost: 25))
        contentStack.addArrangedSubview(makeBuyButton(title: "Đệm ngủ (nghỉ nhanh) - 40 xu", cost: 40))
        contentStack.addArrangedSubview(makeBuyButton(title: "Nơ cổ cao cấp - 80 xu", cost: 80))
        contentStack.addArrangedSubview(makeInfoLabel("Xu còn lại: \(coins)"))
    }

    private func renderProfilePanel() {
        titleLabel.text = "Hồ sơ"
        clearContent()
        contentStack.addArrangedSubview(makeInfoLabel("Tên người chơi: Dzy"))
        contentStack.addArrangedSubview(makeInfoLabel("Cấp độ: \(playerLevel)"))
        contentStack.addArrangedSubview(makeInfoLabel("Chuỗi ngày vận động: 4 ngày"))
        contentStack.addArrangedSubview(makeInfoLabel("Tổng bước tuần này: 12,450"))
    }

    private func renderSettingsPanel() {
        titleLabel.text = "Cài đặt"
        clearContent()
        musicOn = GameAudioSettings.isMusicEnabled
        soundOn = GameAudioSettings.isSoundEffectsEnabled
        vibrationOn = GameAudioSettings.isVibrationEnabled
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
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }

    private func makeBuyButton(title: String, cost: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .medium

        let button = UIButton(type: .system)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if self.coins >= cost {
                self.coins -= cost
                self.playerLevel = min(self.playerLevel + 1, 99)
            }
            self.renderShopPanel()
        }, for: .touchUpInside)
        return button
    }

    private func makeSwitchRow(title: String, isOn: Bool, changed: @escaping (Bool) -> Void) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
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
}
