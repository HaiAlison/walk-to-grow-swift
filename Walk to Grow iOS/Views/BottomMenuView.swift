//
//  BottomMenuView.swift
//  Walk to Grow iOS
//

import UIKit

enum BottomTab: CaseIterable {
    case home
    case shop
    case profile
    case settings


    var imageName: String {
        switch self {
        case .home:
            return "homepage"
        case .shop:
            return "shop"
        case .profile:
            return "profile"
        case .settings:
            return "setting"
        }
    }
}

final class BottomMenuView: UIView {
    var onTabSelected: ((BottomTab, Bool) -> Void)?

    private let stackView = UIStackView()
    private var buttons: [BottomTab: UIButton] = [:]
    private var originalIcons: [BottomTab: UIImage] = [:]
    private var selectedTab: BottomTab = .home
    private let iconBorderWidth: CGFloat = 1.5
    private let iconCornerRadius: CGFloat = 6

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func select(tab: BottomTab) {
        selectedTab = tab
        updateSelectionState()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyAdaptiveIconSize()
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.72)
        layer.cornerRadius = 18
        layer.masksToBounds = true

        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            heightAnchor.constraint(equalToConstant: 72)
        ])

        BottomTab.allCases.forEach { tab in
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            let icon = UIImage(named: tab.imageName)
            originalIcons[tab] = icon
            config.image = icon
            config.imagePlacement = .top
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            config.baseForegroundColor = .lightGray
            button.configuration = config
            button.tag = BottomTab.allCases.firstIndex(of: tab) ?? 0
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons[tab] = button
        }

        updateSelectionState()
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        let tabs = BottomTab.allCases
        guard sender.tag >= 0, sender.tag < tabs.count else { return }
        let tab = tabs[sender.tag]
        let isReselect = (tab == selectedTab)
        select(tab: tab)
        onTabSelected?(tab, isReselect)
    }

    private func updateSelectionState() {
        for (tab, button) in buttons {
            var config = button.configuration
            let isSelected = (tab == selectedTab)
            config?.baseForegroundColor = isSelected ? .systemGreen : .lightGray
            config?.background.backgroundColor = isSelected ? UIColor.white.withAlphaComponent(0.1) : .clear
            config?.background.cornerRadius = 12
            button.configuration = config
        }
    }

    private func applyAdaptiveIconSize() {
        let iconSide = max(28, min(42, bounds.height * 0.5))
        let targetSize = CGSize(width: iconSide, height: iconSide)

        for (tab, button) in buttons {
            guard let originalIcon = originalIcons[tab] else { continue }
            var config = button.configuration
            config?.image = resizedImage(from: originalIcon, targetSize: targetSize)
            button.configuration = config
        }
    }

    private func resizedImage(from image: UIImage, targetSize: CGSize) -> UIImage {
        guard image.size.width > 0, image.size.height > 0 else { return image }
        let scaleRatio = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scaleRatio, height: image.size.height * scaleRatio)
        let drawOrigin = CGPoint(
            x: (targetSize.width - drawSize.width) * 0.5,
            y: (targetSize.height - drawSize.height) * 0.5
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            let drawRect = CGRect(origin: drawOrigin, size: drawSize)
            image.draw(in: drawRect)

            let borderPath = UIBezierPath(
                roundedRect: drawRect.insetBy(dx: iconBorderWidth * 0.5, dy: iconBorderWidth * 0.5),
                cornerRadius: iconCornerRadius
            )
            UIColor.white.withAlphaComponent(0.8).setStroke()
            borderPath.lineWidth = iconBorderWidth
            borderPath.stroke()
        }.withRenderingMode(.alwaysOriginal)
    }

 
}
