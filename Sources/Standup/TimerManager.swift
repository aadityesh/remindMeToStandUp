import Foundation
import Combine

enum ReminderType {
    case standup, water
}

class TimerManager: ObservableObject {
    static let shared = TimerManager()

    @Published var standupInterval: Double = 30
    @Published var waterInterval: Double = 20
    @Published var isRunning = false
    @Published var nextStandupIn: TimeInterval = 0
    @Published var nextWaterIn: TimeInterval = 0
    @Published var isExpanded = false
    @Published var showExpandedContent = false

    var onReminder: ((ReminderType) -> Void)?

    private var standupTimer: Timer?
    private var waterTimer: Timer?
    private var countdownTimer: Timer?
    private var standupFireDate: Date?
    private var waterFireDate: Date?

    private init() {}

    func start() {
        stop()
        isRunning = true
        scheduleStandup()
        scheduleWater()
        startCountdown()
    }

    func stop() {
        isRunning = false
        standupTimer?.invalidate()
        waterTimer?.invalidate()
        countdownTimer?.invalidate()
        standupTimer = nil
        waterTimer = nil
        countdownTimer = nil
        nextStandupIn = 0
        nextWaterIn = 0
    }

    private func scheduleStandup() {
        let interval = standupInterval * 60
        standupFireDate = Date().addingTimeInterval(interval)
        standupTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onReminder?(.standup)
            self.standupFireDate = Date().addingTimeInterval(self.standupInterval * 60)
        }
    }

    private func scheduleWater() {
        let interval = waterInterval * 60
        waterFireDate = Date().addingTimeInterval(interval)
        waterTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onReminder?(.water)
            self.waterFireDate = Date().addingTimeInterval(self.waterInterval * 60)
        }
    }

    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.nextStandupIn = max(0, self.standupFireDate?.timeIntervalSinceNow ?? 0)
            self.nextWaterIn = max(0, self.waterFireDate?.timeIntervalSinceNow ?? 0)
        }
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
