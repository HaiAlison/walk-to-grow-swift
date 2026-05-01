//
//  GameViewController.swift
//  Walk to Grow iOS
//
//  Created by Dzy on 30/3/26.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    private let panelView = BottomPanelsView()
    private let menuView = BottomMenuView()
    private weak var gameScene: GameScene?
    private var backgroundTapGesture: UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = GameScene(size: CGSize(width: 1536, height: 2048))
        scene.scaleMode = .aspectFill
        gameScene = scene

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        skView.presentScene(scene)

        setupOverlayUI()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func setupOverlayUI() {
        panelView.translatesAutoresizingMaskIntoConstraints = false
        menuView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(panelView)
        view.addSubview(menuView)

        NSLayoutConstraint.activate([
            menuView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 12
            ),
            menuView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -12
            ),
            menuView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),

            panelView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 12
            ),
            panelView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -12
            ),
            panelView.bottomAnchor.constraint(
                equalTo: menuView.topAnchor,
                constant: -8
            ),
            panelView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 180
            ),
        ])

        menuView.onTabSelected = { [weak self] tab, isReselect in
            guard let self else { return }
            if isReselect {
                self.panelView.isHidden.toggle()
                return
            }
            self.panelView.isHidden = false
            self.panelView.show(tab: tab)
        }

        panelView.onMusicEnabledChanged = { [weak self] enabled in
            self?.gameScene?.applyMusicEnabled(enabled)
        }
        panelView.onSoundEffectsEnabledChanged = { [weak self] enabled in
            self?.gameScene?.applySoundEffectsEnabled(enabled)
        }

        menuView.select(tab: .home)
        panelView.isHidden = false
        panelView.show(tab: .home)
        setupCollapseGesture()
    }

    private func setupCollapseGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        backgroundTapGesture = tapGesture
    }

    @objc
    private func handleBackgroundTap() {
        panelView.isHidden = true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        if panelView.frame.contains(touchPoint) || menuView.frame.contains(touchPoint) {
            return false
        }
        return !panelView.isHidden
    }
}
