# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概况

Poco 是一个**常驻 macOS 菜单栏的极简番茄钟**，用 Avalonia（.NET 跨平台 UI）实现，首发 macOS，技术选型保留将来上 Windows 的可能。

**当前状态**：主窗口 UI 与番茄钟核心逻辑已按 UI 设计稿实现（浅/深双主题、专注/短休/大休轮回、设置面板、托盘菜单）。产品 / 交互设计见 [docs/2026-06-09-poco-番茄钟-design.md](docs/2026-06-09-poco-番茄钟-design.md)，视觉设计稿原始 HTML/CSS 见 `/tmp/poco_design/`（来自 Claude Design 交付包）。

**已实现的 macOS 平台能力**：阶段自然结束的**系统原生通知**（Poco 自有图标 + 点击唤出主窗口）——需打包成 `.app` 运行；机制见下「macOS 打包与原生通知」。`MainWindowViewModel.PhaseFinished` 是挂载点（跳过不触发）。**菜单栏倒计时文本**——纯文本 `NSStatusItem`（双槽位方案，与 Avalonia TrayIcon 并存），运行/暂停时显示 `MM:SS`（暂停带 ⏸ 前缀），其余状态隐藏；状态→文本映射在 [Models/TrayTextFormat.cs](src/Poco/Models/TrayTextFormat.cs)（有单测），原生实现在 [native/PocoTray.swift](src/Poco/native/PocoTray.swift)，托管封装 [Platform/MacTrayText.cs](src/Poco/Platform/MacTrayText.cs)；macOS 下 `dotnet build` 会自动把 dylib 编进输出目录（csproj 的 `BuildPocoNativeDylib` 目标），故 `dotnet run` 即可见，点击文字唤出主窗口。设计文档见 [docs/2026-06-10-菜单栏倒计时文本-design.md](docs/2026-06-10-菜单栏倒计时文本-design.md)。

**尚未实现**：Dock 图标跳动 / 角标。

**已知问题**：`package-mac.sh` 末尾对外层 `.app` 的 ad-hoc 签名会因 .NET 托管 dll 未签名而失败（exit 1，历史遗留，非菜单栏功能引入）；应用仍可运行（.NET 发布产物自带 ad-hoc 签名）。

## 常用命令

工作目录在 `src/Poco/`（`.csproj` 与 `.sln` 都在此处，不在仓库根目录）。

```bash
cd src/Poco
dotnet restore          # 还原 NuGet 包
dotnet build            # 构建
dotnet run              # 运行（启动桌面应用）
```

- 目标框架 **net10.0**（本机 SDK 10.0.201），输出类型 `WinExe`。
- 运行测试（xUnit，测试项目在 `src/Poco.Tests/`，已加入 `Poco.sln`）：

```bash
cd src/Poco
dotnet test          # 运行全部测试
```

- 打 Windows 安装包时按全局约定默认用 x64。

### macOS 打包与原生通知

```bash
cd src/Poco
bash scripts/package-mac.sh           # 产出签名的 bin/mac/Poco.app（Release）
bash scripts/package-mac.sh Debug     # Debug 包：秒级测试时长（专注10s/短休5s/大休8s）
open bin/mac/Poco.app
```

- **系统原生通知**只在 `.app` 里生效（需要 bundle id + ad-hoc 签名）；`dotnet run` 下没有 bundle 身份，`MacNotifier.TryInit()` 失败，自动回退到 `osascript`（图标是「脚本编辑器」、点击不唤窗）。
- 原生实现：[native/PocoNotify.swift](src/Poco/native/PocoNotify.swift) 编译成 `libPocoNotify.dylib`（封装 `UNUserNotificationCenter` + 点击回调），[Platform/MacNotifier.cs](src/Poco/Platform/MacNotifier.cs) 经 P/Invoke 调用（`AllowUnsafeBlocks`，`[UnmanagedCallersOnly]` 回调切回 UI 线程显示窗口）。打包脚本负责编译 dylib、用 `Assets/tomato.png` 生成 `Poco.icns`、写 `Info.plist`、`codesign --sign -`。
- 首次启动会弹通知授权（现在归属「Poco」）。`#if DEBUG` 的秒级时长在 [MainWindowViewModel.PhaseSeconds](src/Poco/ViewModels/MainWindowViewModel.cs) 里。

## 架构与约定

标准 Avalonia MVVM 结构，配合 **CommunityToolkit.Mvvm**（源生成器）做 ViewModel，番茄钟核心逻辑与 UI 分层：

- **`Models/`**：无 UI 依赖的纯逻辑层。`PocoModels.cs` 定义 `PocoPhase`（Focus/Short/Long）和 `TimerState`（Ready/Running/Paused/Finished）枚举。`PomodoroLogic.cs` 是静态类，封装阶段推进规则（`NextPhase` / `StartsNewCycle`），此处有单元测试覆盖，**不要**把计时或 UI 逻辑混入。`SettingsService.cs` 负责三个时长的持久化读写。

- `Program.cs` → `App.axaml(.cs)`：`App.OnFrameworkInitializationCompleted` 里手动 new `MainWindow` 并赋 `DataContext`。新增窗口/视图在此或经 ViewLocator 接入。
- **`ViewLocator.cs`**：约定式 View 解析——把 ViewModel 类型全名里的 `ViewModel` 替换为 `View` 来定位视图。新增的 `XxxViewModel`（继承 `ViewModelBase`）会自动匹配到 `Views/XxxView`。
- `ViewModelBase` 继承 `ObservableObject`（CommunityToolkit.Mvvm）。可观察属性用 `[ObservableProperty]`、命令用 `[RelayCommand]`，依赖源生成器，类需声明为 `partial`。
- **编译绑定默认开启**（`AvaloniaUseCompiledBindingsByDefault=true`）：XAML 中需通过 `x:DataType` 指定数据类型，否则绑定不生效。
- 主题：`App.axaml` 用 `FluentTheme`，`RequestedThemeVariant="Default"`（跟随系统）。设计要求主窗口为**深色极简**风格。
- 资源（字体、图标）放 `Assets/`，已通过 `<AvaloniaResource Include="Assets\**"/>` 打包。字体：`Assets/Fonts/` 内只有 **HarmonyOS Sans SC**（`HarmonyOS_SansSC_Regular.ttf` + `_Bold.ttf`，两个字重）。通过 [PocoFontCollection.cs](src/Poco/PocoFontCollection.cs) 注册为内嵌字体集合，XAML 里统一用 `fonts:Poco#HarmonyOS Sans SC` 引用（**不是** `avares://...#族名`，也没有 `MonoFont`/`CjkFont` 资源键）。倒计时数字的等宽对齐靠 `FontFeatures="+tnum"`（tabular numerals），并非单独的 JetBrains Mono 字体。样式中用到的 `Light`/`Medium`/`SemiBold` 字重由引擎从 Regular/Bold 合成（仓库未内置这些字重文件）。

### 双主题 + 阶段语义色（关键设计）

颜色分两条正交的轴，别混淆：

1. **主题轴（浅/深）** → `App.axaml` 的 `ThemeDictionaries`（`Light` / `Dark`）里定义为 `SolidColorBrush` 资源（`BgBrush`/`InkBrush`/`FocusBrush`/`RestBrush` 等，OKLCH 已转 sRGB hex）。**一律用 `DynamicResource` 引用**，主题切换自动生效。**默认浅色**（`App.axaml` `RequestedThemeVariant="Light"`），用户可在设置内的分段控件切换深色；选择经 `SettingsService` 持久化，启动时由 `MainWindowViewModel.ApplyTheme()` 按持久化值设置 `Application.Current.RequestedThemeVariant`。
2. **阶段轴（专注=暖橙 / 休息=薄荷青）** → 用 **style class** 切换：根 `Border.poco-win` 上 `Classes.focus="{Binding IsFocus}"` / `Classes.rest="{Binding IsRest}"`，[Styles/Poco.axaml](src/Poco/Styles/Poco.axaml) 里用后代选择器 `Border.poco-win.focus Ellipse.accent-fill` 之类把语义色喂给具体元素。状态（`ready/running/paused/finished`）同样走根 Border 的 class，驱动倒计时变色、提示行等。

所有组件样式集中在 `Styles/Poco.axaml`（经 `App.axaml` 的 `StyleInclude` 引入），视图里只挂 class 不写内联样式。

### 计时状态机

`MainWindowViewModel`（`DispatcherTimer` 每秒 tick）是单一计时源：`Phase` × `TimerState`，`_completedFocus` 计数驱动 4 颗圆点（`Dots` 集合 + `DotItem`）。**阶段推进规则委托给 `PomodoroLogic.NextPhase` / `StartsNewCycle`**，ViewModel 只做调用，不内联规则。命令：`PrimaryAction`（开始↔暂停；Finished 时推进到下一阶段并开始）、`Reset`、`Skip`（跳过不计入完成数，不触发通知）。设置面板与主窗口共用同一 VM（`IsSettingsOpen` 切换面板，时长步进命令实时改 `RemainingSeconds` 并经 `SettingsService` 持久化）。托盘菜单（`App.axaml.cs` 里 `TrayIcon` + `NativeMenu`）复用这些命令。
- `AvaloniaUI.DiagnosticsSupport`（开发者工具/DevTools）仅 Debug 配置引入，Release 自动排除。

## Avalonia 开发硬性要求

写任何 Avalonia XAML / 控件 / 绑定 / 样式 / 动画 / 资源 URI **之前**，必须先用 Context7 MCP 查官方文档（库 ID `/avaloniaui/avalonia` 或 `/avaloniaui/avalonia-docs`），避免把 WPF 写法误用为 Avalonia。本仓库也配有 `avalonia-docs` MCP（`lookup_avalonia_api` / `search_avalonia_docs`）可用。

实现前**尤其需要先核实**的 macOS 平台能力（设计文档第 11 节列出）：
- 菜单栏（TrayIcon / `NSStatusItem`）显示**动态倒计时文本**的方式与可行性；
- 系统原生通知；
- Dock 图标跳动 / 角标。

## 关键产品规则（来自设计文档，实现时勿偏离）

- **阶段**：专注 25 / 短休 5 / 大休 15 分钟（三者可在设置中改）。每完成 4 个专注 → 1 次大休 → 计数归零循环。每组固定 4 轮（v1 不可配）。
- **手动推进**：阶段倒计时归零后**不自动**进下一阶段；结束时发系统通知 + Dock 跳动，等用户点「开始」才推进。
- **计时状态机**：待开始 / 运行 / 暂停 / 结束。按钮：开始·暂停（主）、重置（回当前阶段满时长）、跳过（立即进下一阶段 Ready，**不弹通知**）。
- **窗口行为**：关闭主窗口隐藏到菜单栏**不退出**；退出走菜单栏图标的菜单。菜单栏文本与主窗口倒计时**共享同一计时源**，实时同步。
- **持久化**：只存设置（三个时长）到本地配置文件；**不**持久化计时进度，重开从第一个专注阶段 Ready 开始。
- 所有交互内容、注释、文档一律用**简体中文**。
