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
    private var routineService = RoutineStreakService(stepGoal: GameProgressCalculator.dailyStepTarget)
    private var checkinService = DailyCheckinService()
    private let streakRepository: StreakPersistenceRepository = UserDefaultsStreakRepository()
    private var routineState = RoutineStreakState.default()
    private var checkinState = DailyCheckinState.default()
    private var latestSteps = 0
    private var weeklySteps = 0
    private var checkinRewardText: String?
    /// Xu thưởng tạm (demo); sau này thay bằng ví thật / server.
    private let trialWalletBonusCoins = 100
    /// Xu đã chi trong cửa hàng (phiên), đồng bộ với `BottomPanelsView` qua `onShopCoinsSpent`.
    private var shopSessionCoinsSpent = 0

    private func displayWalletCoins() -> Int {
        let fromSteps = GameProgressCalculator.coin(from: latestSteps)
        return max(0, fromSteps + trialWalletBonusCoins - shopSessionCoinsSpent)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = GameScene(size: CGSize(width: 1536, height: 2048))
        scene.scaleMode = .aspectFill
        scene.onTodayStepsUpdated = { [weak self] steps in
            self?.handleStepsUpdated(steps)
        }
        gameScene = scene

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        skView.presentScene(scene)

        loadStreakStates()
        refreshStreakStatesForToday()
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
        panelView.onCheckinClaimTapped = { [weak self] in
            self?.claimDailyCheckin()
        }
        panelView.onRoutineWeekdaysChanged = { [weak self] weekdays in
            self?.updateRoutineWeekdays(weekdays)
        }
        panelView.onShopCoinsSpent = { [weak self] amount in
            guard let self, amount > 0 else { return }
            self.shopSessionCoinsSpent += amount
            self.updatePanelStates()
        }
        panelView.onCatSkinPurchased = { [weak self] sheetImageName in
            self?.gameScene?.addWanderingCatFromShop(sheetImageName)
        }

        menuView.select(tab: .home)
        panelView.isHidden = false
        updatePanelStates()
        panelView.show(tab: .home)
        setupCollapseGesture()
    }

    private func claimDailyCheckin() {
        let now = Date()
        let claim = checkinService.claim(on: now, state: &checkinState)
        switch claim {
        case .claimed(let reward):
            checkinRewardText = "Nhận \(reward.coins) xu"
        case .alreadyClaimedToday:
            checkinRewardText = "Đã điểm danh hôm nay"
        }
        saveStreakStates()
        updatePanelStates()
    }

    private func handleStepsUpdated(_ steps: Int) {
        latestSteps = max(steps, 0)
        weeklySteps = max(weeklySteps, latestSteps)
        refreshStreakStatesForToday()
        let update = routineService.recordProgressIfNeeded(
            steps: latestSteps,
            on: Date(),
            state: &routineState
        )
        if case .increased = update {
            saveStreakStates()
        }
        updatePanelStates()
    }

    private func refreshStreakStatesForToday() {
        let oldRoutine = routineState
        let oldCheckin = checkinState
        let now = Date()
        routineService.evaluateForCurrentDate(now, state: &routineState)
        checkinService.evaluateForCurrentDate(now, state: &checkinState)
        if oldRoutine.currentStreak != routineState.currentStreak
            || oldRoutine.lastQualifiedDate != routineState.lastQualifiedDate
            || oldCheckin.currentStreak != checkinState.currentStreak
        {
            saveStreakStates()
        }
    }

    private func loadStreakStates() {
        guard let snapshot = streakRepository.load() else { return }
        routineState = snapshot.routine
        checkinState = snapshot.checkin
    }

    private func saveStreakStates() {
        let snapshot = StreakPersistenceSnapshot(routine: routineState, checkin: checkinState)
        streakRepository.save(snapshot)
    }

    private func updatePanelStates() {
        panelView.applyHomeState(
            HomePanelState(
                todaySteps: latestSteps,
                stepGoal: GameProgressCalculator.dailyStepTarget,
                activePetName: "Mèo đen",
                coins: displayWalletCoins(),
                routineStreak: routineState.currentStreak,
                checkinStreak: checkinState.currentStreak,
                isCheckinClaimedToday: isCheckinClaimedToday,
                latestCheckinRewardText: checkinRewardText
            )
        )
        panelView.applyProfileState(
            ProfilePanelState(
                playerName: "Dzy",
                level: 3,
                routineStreak: routineState.currentStreak,
                checkinStreak: checkinState.currentStreak,
                weeklySteps: weeklySteps
            )
        )
        panelView.applySettingsState(
            SettingsPanelState(
                selectedWeekdays: routineState.selectedWeekdays,
                stepGoal: GameProgressCalculator.dailyStepTarget
            )
        )
    }

    private var isCheckinClaimedToday: Bool {
        guard let lastCheckin = checkinState.lastCheckinDate else { return false }
        return Calendar.current.isDateInToday(lastCheckin)
    }

    private func updateRoutineWeekdays(_ weekdays: Set<Int>) {
        routineState.selectedWeekdays = weekdays
        refreshStreakStatesForToday()
        saveStreakStates()
        updatePanelStates()
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
