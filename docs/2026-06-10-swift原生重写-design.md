# Poco Swift 原生重写设计

日期：2026-06-10
状态：已确认（用户批准）

## 背景与目标

Poco 不再考虑跨平台，只做 macOS 桌面应用。将 `src/Avalonia/` 下的 Avalonia(.NET) 实现整体重写为原生 Swift 应用，**功能保持不变**，UI 改用 macOS 原生控件与系统风格。Avalonia 版暂留在 `src/Avalonia/` 作为功能对照，Swift 版验收后删除。

## 已确认的关键决策

| 决策点 | 结论 |
|---|---|
| UI 框架 | SwiftUI（主窗口）+ AppKit（托盘 NSStatusItem） |
| 视觉风格 | 原生 macOS 风格：系统控件、系统字体；阶段语义色（专注暖橙/休息薄荷青）仅作点缀保留 |
| 主题 | **默认浅色，设置内手动切浅/深，不跟随系统**（经 `NSApp.appearance` 覆盖，选择持久化） |
| 工程形态 | 手写现代格式 `.xcodeproj`（objectVersion 77 / fileSystemSynchronizedGroups），增删文件无需改工程文件；Xcode ⌘R 与 `xcodebuild` 均可构建 |
| 旧代码 | `src/Avalonia/` 暂留，验收后删 |
| 最低系统 | macOS 14 |
| Bundle ID | `com.poco.pomodoro`（沿用） |

## 目录结构

```
src/macOS/
  Poco.xcodeproj/            # 现代格式工程 + 共享 scheme
  Poco/
    PocoApp.swift            # @main SwiftUI App + AppDelegate（窗口隐藏式关闭、激活策略）
    PomodoroEngine.swift     # @MainActor ObservableObject：单一计时源（对应原 MainWindowViewModel）
    Models/
      PocoModels.swift       # PocoPhase / TimerState 枚举
      PomodoroLogic.swift    # nextPhase / startsNewCycle 纯函数
      TrayTextFormat.swift   # 状态→菜单栏文本映射纯函数
      SettingsStore.swift    # UserDefaults 持久化（三时长 + isDark）
    Views/
      MainView.swift         # 倒计时 + 圆点 + 控制区（原生控件）
      SettingsView.swift     # 主题分段控件 + 三个时长 Stepper + 恢复默认/退出
    Tray/StatusItemController.swift   # NSStatusItem：图标⇄倒计时文本、双击唤窗、右键菜单
    Notify/NotificationManager.swift  # UNUserNotificationCenter + 点击唤窗
    Assets.xcassets          # AppIcon（由 tomato.png 生成）+ 托盘番茄图
  PocoTests/
    PomodoroLogicTests.swift # 移植自 C# 版 xUnit 测试（Swift Testing）
    TrayTextFormatTests.swift
```

## 产品规则（不变）

- 专注 25 / 短休 5 / 大休 15 分钟，设置可改（1–60）；每完成 4 个专注 → 1 次大休 → 计数归零；每组固定 4 轮。
- 倒计时归零**不自动推进**：发原生通知（点击唤窗），等用户点「开始」进下一阶段。
- 状态机：Ready / Running / Paused / Finished。命令：开始·暂停、重置（回满时长）、跳过（进下一阶段 Ready，不计数、不通知）。
- 计时以墙钟结束时刻为准（250ms tick 仅刷新显示），避免漂移；暂停按墙钟冻结剩余。
- 托盘单槽位：Ready/Finished 显示番茄图标，Running 显示 `MM:SS`，Paused 带 `⏸ ` 前缀；双击唤窗、右键菜单、单击不响应。
- 关窗隐藏不退出（orderOut，不销毁窗口）；退出走托盘菜单或设置面板「退出」。
- 只持久化设置（三时长 + 主题），不持久化计时进度。
- `#if DEBUG` 秒级时长（专注 10s / 短休 5s / 大休 8s）保留。

## 与 Avalonia 版的差异（有意为之）

- 设置持久化从 `~/.config/Poco/settings.json` 改为 UserDefaults（原生惯例；默认值相同，不做迁移）。
- 不再需要 dylib / P/Invoke / osascript 回退：通知直接在 app 内调 UNUserNotificationCenter；Xcode 运行即是 .app，自带 bundle 身份。
- 自定义内嵌字体（HarmonyOS Sans）去除，用系统字体；倒计时用 `monospacedDigit` 系统字体。
- 测试在运行 app 宿主时跳过通知授权请求（检测 XCTest 环境变量）。

## 范围外

Dock 跳动/角标（原本就未实现）、Windows 支持、设置 JSON 迁移。
