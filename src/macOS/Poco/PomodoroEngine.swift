// 番茄钟单一计时源（对应 Avalonia 版 MainWindowViewModel）：
// Phase × TimerState 状态机 + 墙钟计时 + 设置读写。
// 阶段推进规则委托给 PomodoroLogic，这里只做调用，不内联规则。
import AppKit
import Combine

@MainActor
final class PomodoroEngine: ObservableObject {
    static let focusPerCycle = PomodoroLogic.focusPerCycle

    // —— 核心状态 ——
    @Published private(set) var phase: PocoPhase = .focus
    @Published private(set) var state: TimerState = .ready
    @Published private(set) var remainingSeconds = 0
    @Published var isSettingsOpen = false

    /// 本组已完成的专注数（0..4），决定圆点与「4 专注 → 1 大休」
    @Published private(set) var completedFocus = 0

    // —— 设置（分钟）——
    @Published var focusMinutes: Int { didSet { persistDuration(.focus, oldValue: oldValue) } }
    @Published var shortMinutes: Int { didSet { persistDuration(.short, oldValue: oldValue) } }
    @Published var longMinutes: Int { didSet { persistDuration(.long, oldValue: oldValue) } }

    // —— 主题（默认浅色，手动切换、不跟随系统）——
    @Published var isDarkTheme: Bool {
        didSet {
            SettingsStore.isDarkTheme = isDarkTheme
            applyTheme()
        }
    }

    /// 阶段自然结束时触发（系统通知挂载点；跳过不触发）。
    var onPhaseFinished: ((PocoPhase) -> Void)?

    // 运行中阶段的目标结束时刻（墙钟）。计时以它为准，tick 仅用于刷新显示，
    // 避免 Timer 间隔抖动与系统睡眠造成的累积漂移。
    private var endAt = Date.distantPast
    private var timer: Timer?

    init() {
        focusMinutes = SettingsStore.focusMinutes
        shortMinutes = SettingsStore.shortMinutes
        longMinutes = SettingsStore.longMinutes
        isDarkTheme = SettingsStore.isDarkTheme
        resetToPhase(.focus, resetCycle: true)
    }

    /// 把当前主题应用到 NSApp（启动时调用一次，切换时自动调用）。
    func applyTheme() {
        NSApp.appearance = NSAppearance(named: isDarkTheme ? .darkAqua : .aqua)
    }

    // ============================================================
    // 计时
    // ============================================================
    private func startTimer() {
        // 250ms 刷新让墙钟显示更跟手；剩余时长仍按整秒展示
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            // 挂在主 RunLoop 上必然在主线程回调，直接断言隔离避免每 tick 派发一次 Task
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        remainingSeconds = remainingFromClock()
        if remainingSeconds <= 0 {
            stopTimer()
            if phase == .focus {
                completedFocus = min(completedFocus + 1, Self.focusPerCycle)
            }
            state = .finished
            onPhaseFinished?(phase)
        }
    }

    /// 按墙钟计算当前应显示的剩余秒数（向上取整，到点才归零）。
    private func remainingFromClock() -> Int {
        max(0, Int(endAt.timeIntervalSinceNow.rounded(.up)))
    }

    private func phaseSeconds(_ phase: PocoPhase) -> Int {
        #if DEBUG
        // 调试模式：缩短为秒级，方便快速验证阶段轮回（专注 10s / 短休 5s / 大休 8s）
        switch phase {
        case .focus: return 10
        case .short: return 5
        case .long: return 8
        }
        #else
        switch phase {
        case .focus: return max(1, focusMinutes) * 60
        case .short: return max(1, shortMinutes) * 60
        case .long: return max(1, longMinutes) * 60
        }
        #endif
    }

    private func resetToPhase(_ phase: PocoPhase, resetCycle: Bool) {
        stopTimer()
        if resetCycle { completedFocus = 0 }
        self.phase = phase
        remainingSeconds = phaseSeconds(phase)
        state = .ready
    }

    private func advanceToNext() {
        let next = PomodoroLogic.nextPhase(phase, completedFocus: completedFocus)
        let newCycle = PomodoroLogic.startsNewCycle(phase, completedFocus: completedFocus)
        resetToPhase(next, resetCycle: newCycle)
    }

    // ============================================================
    // 命令（开始·暂停 / 重置 / 跳过）
    // ============================================================
    func primaryAction() {
        switch state {
        case .ready, .paused:
            startRunning()
        case .running:
            stopTimer()
            remainingSeconds = remainingFromClock() // 暂停瞬间按墙钟校正一次，冻结精确剩余
            state = .paused
        case .finished:
            // 已结束 → 用户点「开始」→ 进入下一阶段并开始计时
            advanceToNext()
            startRunning()
        }
    }

    /// 基于当前 remainingSeconds 设定墙钟结束时刻并开始运行。
    private func startRunning() {
        endAt = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        state = .running
        startTimer()
    }

    /// 重置：当前阶段回到满时长（待开始）。
    func reset() { resetToPhase(phase, resetCycle: false) }

    /// 跳过：立即结束当前阶段，进入下一阶段的待开始态（不弹通知）。
    /// 注意：跳过专注**不计入**本组已完成数（只有自然走完才算一次专注），
    /// 因此跳过第 4 个专注会进短休而非大休——这是有意为之。
    func skip() { advanceToNext() }

    func restoreDefaults() {
        focusMinutes = 25
        shortMinutes = 5
        longMinutes = 15
    }

    // ============================================================
    // 设置持久化
    // ============================================================
    private func persistDuration(_ changed: PocoPhase, oldValue: Int) {
        let newValue: Int
        switch changed {
        case .focus: newValue = focusMinutes
        case .short: newValue = shortMinutes
        case .long: newValue = longMinutes
        }
        guard newValue != oldValue else { return } // 步进到边界后重复点击不再触发写盘
        switch changed {
        case .focus: SettingsStore.focusMinutes = newValue
        case .short: SettingsStore.shortMinutes = newValue
        case .long: SettingsStore.longMinutes = newValue
        }
        // 处于「待开始」且正是该阶段时，实时反映新时长
        if state == .ready && phase == changed {
            remainingSeconds = phaseSeconds(changed)
        }
    }

    // ============================================================
    // 派生属性（视图与托盘共用）
    // ============================================================
    var phaseCjk: String {
        switch phase {
        case .focus: return "专注"
        case .short: return "短休"
        case .long: return "大休"
        }
    }

    var minutesText: String { String(format: "%02d", remainingSeconds / 60) }
    var secondsText: String { String(format: "%02d", remainingSeconds % 60) }

    var isFocus: Bool { phase == .focus }

    var hintText: String? {
        switch state {
        case .paused: return "已暂停"
        case .finished: return phase == .focus ? "专注结束，该休息了" : "休息结束，继续专注"
        default: return nil
        }
    }

    var primaryLabel: String { state == .running ? "暂停" : "开始" }

    /// 当前正在进行的专注轮次下标（高亮圆点）；非专注或已结束为 nil。
    var currentDotIndex: Int? {
        (phase == .focus && state != .finished && completedFocus < Self.focusPerCycle)
            ? completedFocus : nil
    }

    var trayTooltip: String { "Poco · \(phaseCjk) \(minutesText):\(secondsText)" }

    /// 菜单栏倒计时文本（运行/暂停才显示；nil 时托盘切回图标态）。
    var trayText: String? { TrayTextFormat.text(for: state, remainingSeconds: remainingSeconds) }
}
