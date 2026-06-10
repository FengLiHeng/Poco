# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概况

Poco 是一个**常驻 macOS 菜单栏的极简番茄钟**，原生 Swift 实现（SwiftUI 内容 + AppKit 生命周期/托盘），**只做 macOS**，不再考虑跨平台。

**当前状态**：Swift 原生版（`src/macOS/`）已实现全部功能：主窗口（倒计时/圆点/控制区/设置面板，自定义设计语言 + 呼吸/过渡动画）、浅深双主题手动切换、菜单栏单槽位托盘（图标⇄倒计时文本）、阶段结束系统通知、关窗隐藏不退出。重写设计见 [docs/2026-06-10-swift原生重写-design.md](docs/2026-06-10-swift原生重写-design.md)，产品/交互设计见 [docs/2026-06-09-poco-番茄钟-design.md](docs/2026-06-09-poco-番茄钟-design.md)。

**历史**：项目最初用 Avalonia(.NET) 实现（git 历史中的 `src/Avalonia/`，已删除）；双主题色板与组件视觉规格源自该版的 `App.axaml` / `Styles/Poco.axaml`，现移植在 [Views/Theme.swift](src/macOS/Poco/Views/Theme.swift)。

**尚未实现**：Dock 图标跳动 / 角标。

## 常用命令

工程在 `src/macOS/`（现代格式 `.xcodeproj`，objectVersion 77 / fileSystemSynchronizedGroups——**增删源文件无需改工程文件**，目录即工程）。

```bash
cd src/macOS
xcodebuild -project Poco.xcodeproj -scheme Poco -configuration Debug build   # 构建
xcodebuild -project Poco.xcodeproj -scheme Poco test                         # 运行单测（Swift Testing）
open ~/Library/Developer/Xcode/DerivedData/Poco-*/Build/Products/Debug/Poco.app  # 运行
```

也可直接用 Xcode 打开 `Poco.xcodeproj` ⌘R / ⌘U。最低系统 macOS 14，Bundle ID `com.poco.pomodoro`，ad-hoc 签名。

- Debug 配置是**秒级测试时长**（专注 10s / 短休 5s / 大休 8s，`PomodoroEngine.phaseSeconds` 里 `#if DEBUG`）；真实时长用 Release。
- 系统通知在 Xcode/xcodebuild 构建的 .app 里直接可用（自带 bundle 身份），首次启动会弹授权。

## 架构与约定

```
src/macOS/
  Poco.xcodeproj/            # 工程 + 共享 scheme（Poco）
  Poco/
    main.swift               # AppKit 入口（不用 SwiftUI Window 场景——它关最后一个窗口会退出应用且接管 window delegate）
    AppDelegate.swift        # 自建 NSWindow（isReleasedWhenClosed=false，关窗 orderOut 隐藏）、主菜单、托盘/通知挂载
    PomodoroEngine.swift     # @MainActor ObservableObject：单一计时源（状态机/墙钟计时/设置读写/派生文本）
    Models/                  # 纯逻辑层，无 UI 依赖，单测覆盖——不要把计时或 UI 逻辑混入
      PocoModels.swift       #   PocoPhase / TimerState 枚举
      PomodoroLogic.swift    #   nextPhase / startsNewCycle（阶段推进规则，引擎只调用不内联）
      TrayTextFormat.swift   #   状态→菜单栏文本映射（Running=MM:SS，Paused=⏸ 前缀，其余 nil=图标态）
      SettingsStore.swift    #   UserDefaults 持久化（三时长 + isDark）
    Views/                   # SwiftUI，自定义设计语言（不用系统控件默认样式）
      Theme.swift            #   双主题色板（PocoTheme.light/.dark）+ 自定义 ButtonStyle（胶囊主按钮/幽灵圆钮/步进钮/文字链）
      MainView.swift         #   主界面 + 呼吸动画（运行 4.5s / 结束 1.15s 脉动）；isSettingsOpen 时滑入 SettingsView（同窗）
      SettingsView.swift     #   自定义分段主题切换 + 三个时长步进行 + 恢复默认/退出
    Tray/StatusItemController.swift   # NSStatusItem 单槽位：双击唤窗、右键菜单、单击不响应；订阅 engine.objectWillChange 刷新
    Notify/NotificationManager.swift  # UNUserNotificationCenter：阶段自然结束发横幅，点击唤窗
    Assets.xcassets          # AppIcon（tomato.png 各档）+ TrayTomato 托盘图
  PocoTests/                 # Swift Testing（@Test/#expect），宿主为 Poco.app；
                             # AppDelegate 检测 XCTest 环境变量时跳过托盘/通知初始化
```

要点：

- **计时以墙钟为准**：运行时记目标结束时刻 `endAt`，250ms tick 只刷新显示（向上取整到整秒），暂停按墙钟冻结——避免 Timer 抖动与睡眠漂移。
- **主题**：默认浅色，设置内手动切浅/深，**不跟随系统**；经 `NSApp.appearance` 覆盖（`PomodoroEngine.applyTheme`），选择持久化。
- 倒计时与托盘文本用 `monospacedDigit` 等宽数字，跳秒不抖动。
- Swift 语言模式 5（非严格并发）；UI 相关类标 `@MainActor`。

## 关键产品规则（实现时勿偏离）

- **阶段**：专注 25 / 短休 5 / 大休 15 分钟（设置可改 1–60）。每完成 4 个专注 → 1 次大休 → 计数归零循环。每组固定 4 轮（v1 不可配）。
- **手动推进**：倒计时归零后**不自动**进下一阶段；结束时发系统通知，等用户点「开始」才推进。
- **状态机**：Ready / Running / Paused / Finished。按钮：开始·暂停（主）、重置（回当前阶段满时长）、跳过（立即进下一阶段 Ready，**不弹通知**）。
- **跳过不计数**：只有自然走完的专注才 +1，跳过第 4 个专注进短休而非大休（有意为之）。
- **窗口行为**：关闭主窗口隐藏到菜单栏**不退出**；退出走托盘菜单/设置面板/⌘Q。菜单栏文本与主窗口倒计时共享同一计时源（`PomodoroEngine`），实时同步。
- **持久化**：只存设置（三时长 + 主题）到 UserDefaults；**不**持久化计时进度，重开从第一个专注阶段 Ready 开始。
- 所有交互内容、注释、文档一律用**简体中文**。
