using System;
using System.Collections.ObjectModel;
using Avalonia;
using Avalonia.Styling;
using Avalonia.Threading;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Poco.Models;

namespace Poco.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private const int FocusPerCycle = PomodoroLogic.FocusPerCycle;

    private readonly DispatcherTimer _timer;
    private readonly PocoSettings _settings;

    // 运行中阶段的目标结束时刻（墙钟）。计时以它为准，tick 仅用于刷新显示，
    // 避免 DispatcherTimer 间隔抖动与系统睡眠造成的累积漂移。
    private DateTime _endAtUtc;

    // —— 核心状态 ——
    [ObservableProperty] private PocoPhase _phase = PocoPhase.Focus;
    [ObservableProperty] private TimerState _state = TimerState.Ready;
    [ObservableProperty] private int _remainingSeconds;
    [ObservableProperty] private bool _isSettingsOpen;

    // 本组已完成的专注数（0..4），决定圆点与「4 专注 → 1 大休」
    private int _completedFocus;

    // —— 设置（分钟）——
    [ObservableProperty] private int _focusMinutes;
    [ObservableProperty] private int _shortMinutes;
    [ObservableProperty] private int _longMinutes;

    // —— 主题（默认浅色）——
    [ObservableProperty] private bool _isDarkTheme;

    public ObservableCollection<DotItem> Dots { get; } = new();

    public MainWindowViewModel()
    {
        _settings = SettingsService.Load();
        _focusMinutes = _settings.FocusMinutes;
        _shortMinutes = _settings.ShortMinutes;
        _longMinutes = _settings.LongMinutes;
        _isDarkTheme = _settings.IsDark;

        for (var i = 0; i < FocusPerCycle; i++)
            Dots.Add(new DotItem());

        // 250ms 刷新让墙钟显示更跟手；剩余时长仍按整秒展示
        _timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(250) };
        _timer.Tick += OnTick;

        ResetToPhase(PocoPhase.Focus, resetCycle: true);
        RaiseDerived(); // 初值与字段默认值相同不会触发属性变更，这里显式刷新一次派生属性与圆点（当前轮光晕）
    }

    /// <summary>阶段结束时触发（用于系统通知 / Dock 跳动等平台能力）。</summary>
    public event Action<PocoPhase>? PhaseFinished;

    // ============================================================
    // 计时
    // ============================================================
    private void OnTick(object? sender, EventArgs e)
    {
        RemainingSeconds = RemainingFromClock();

        if (RemainingSeconds <= 0)
        {
            _timer.Stop();
            if (Phase == PocoPhase.Focus)
                _completedFocus = Math.Min(_completedFocus + 1, FocusPerCycle);
            State = TimerState.Finished;
            PhaseFinished?.Invoke(Phase);
        }
    }

    /// <summary>按墙钟计算当前应显示的剩余秒数（向上取整，到点才归零）。</summary>
    private int RemainingFromClock()
        => Math.Max(0, (int)Math.Ceiling((_endAtUtc - DateTime.UtcNow).TotalSeconds));

    private int PhaseSeconds(PocoPhase phase)
    {
#if DEBUG
        // 调试模式：缩短为秒级，方便快速验证阶段轮回（专注 10s / 短休 5s / 大休 8s）
        return phase switch
        {
            PocoPhase.Focus => 10,
            PocoPhase.Short => 5,
            _ => 8,
        };
#else
        return phase switch
        {
            PocoPhase.Focus => Math.Max(1, FocusMinutes) * 60,
            PocoPhase.Short => Math.Max(1, ShortMinutes) * 60,
            _ => Math.Max(1, LongMinutes) * 60,
        };
#endif
    }

    private void ResetToPhase(PocoPhase phase, bool resetCycle)
    {
        _timer.Stop();
        if (resetCycle) _completedFocus = 0;
        Phase = phase;
        RemainingSeconds = PhaseSeconds(phase);
        State = TimerState.Ready;
    }

    private void AdvanceToNext()
    {
        var next = PomodoroLogic.NextPhase(Phase, _completedFocus);
        var newCycle = PomodoroLogic.StartsNewCycle(Phase, _completedFocus);
        ResetToPhase(next, resetCycle: newCycle);
    }

    // ============================================================
    // 命令（开始·暂停 / 重置 / 跳过）
    // ============================================================
    [RelayCommand]
    private void PrimaryAction()
    {
        switch (State)
        {
            case TimerState.Ready:
            case TimerState.Paused:
                StartRunning();
                break;
            case TimerState.Running:
                _timer.Stop();
                RemainingSeconds = RemainingFromClock(); // 暂停瞬间按墙钟校正一次，冻结精确剩余
                State = TimerState.Paused;
                break;
            case TimerState.Finished:
                // 已结束 → 用户点「开始」→ 进入下一阶段并开始计时
                AdvanceToNext();
                StartRunning();
                break;
        }
    }

    /// <summary>基于当前 <see cref="RemainingSeconds"/> 设定墙钟结束时刻并开始运行。</summary>
    private void StartRunning()
    {
        _endAtUtc = DateTime.UtcNow + TimeSpan.FromSeconds(RemainingSeconds);
        State = TimerState.Running;
        _timer.Start();
    }

    /// <summary>重置：当前阶段回到满时长（待开始）。</summary>
    [RelayCommand]
    private void Reset() => ResetToPhase(Phase, resetCycle: false);

    /// <summary>
    /// 跳过：立即结束当前阶段，进入下一阶段的待开始态（不弹通知）。
    /// 注意：跳过专注**不计入**本组已完成数（只有自然走完才算一次专注），
    /// 因此跳过第 4 个专注会进短休而非大休——这是有意为之。
    /// </summary>
    [RelayCommand]
    private void Skip() => AdvanceToNext();

    [RelayCommand] private void OpenSettings() => IsSettingsOpen = true;
    [RelayCommand] private void CloseSettings() => IsSettingsOpen = false;

    /// <summary>退出应用（由设置面板触发）。</summary>
    [RelayCommand] private void Quit() => Poco.App.ExitApp();

    // —— 主题切换 ——
    [RelayCommand] private void SelectLight() => IsDarkTheme = false;
    [RelayCommand] private void SelectDark() => IsDarkTheme = true;

    /// <summary>把当前主题应用到 Application（启动时由 App 调用，切换时自动调用）。</summary>
    public void ApplyTheme()
    {
        if (Application.Current is { } app)
            app.RequestedThemeVariant = IsDarkTheme ? ThemeVariant.Dark : ThemeVariant.Light;
    }

    partial void OnIsDarkThemeChanged(bool value)
    {
        _settings.IsDark = value;
        SettingsService.Save(_settings);
        ApplyTheme();
        OnPropertyChanged(nameof(IsLightTheme));
    }

    public bool IsLightTheme => !IsDarkTheme;

    // —— 步进器 ——
    [RelayCommand] private void FocusInc() => FocusMinutes = Math.Min(60, FocusMinutes + 1);
    [RelayCommand] private void FocusDec() => FocusMinutes = Math.Max(1, FocusMinutes - 1);
    [RelayCommand] private void ShortInc() => ShortMinutes = Math.Min(60, ShortMinutes + 1);
    [RelayCommand] private void ShortDec() => ShortMinutes = Math.Max(1, ShortMinutes - 1);
    [RelayCommand] private void LongInc() => LongMinutes = Math.Min(60, LongMinutes + 1);
    [RelayCommand] private void LongDec() => LongMinutes = Math.Max(1, LongMinutes - 1);

    [RelayCommand]
    private void RestoreDefaults()
    {
        FocusMinutes = 25;
        ShortMinutes = 5;
        LongMinutes = 15;
    }

    // ============================================================
    // 派生属性变更广播
    // ============================================================
    partial void OnPhaseChanged(PocoPhase value) => RaiseDerived();
    partial void OnStateChanged(TimerState value) => RaiseDerived();
    partial void OnRemainingSecondsChanged(int value)
    {
        OnPropertyChanged(nameof(MinutesText));
        OnPropertyChanged(nameof(SecondsText));
        OnPropertyChanged(nameof(TrayTooltip));
        OnPropertyChanged(nameof(TrayText));
    }

    partial void OnFocusMinutesChanged(int value)
    {
        _settings.FocusMinutes = value;
        PersistAndMaybeRefresh(PocoPhase.Focus);
    }

    partial void OnShortMinutesChanged(int value)
    {
        _settings.ShortMinutes = value;
        PersistAndMaybeRefresh(PocoPhase.Short);
    }

    partial void OnLongMinutesChanged(int value)
    {
        _settings.LongMinutes = value;
        PersistAndMaybeRefresh(PocoPhase.Long);
    }

    private void PersistAndMaybeRefresh(PocoPhase changed)
    {
        SettingsService.Save(_settings);
        // 处于「待开始」且正是该阶段时，实时反映新时长
        if (State == TimerState.Ready && Phase == changed)
            RemainingSeconds = PhaseSeconds(changed);
    }

    private void RaiseDerived()
    {
        OnPropertyChanged(nameof(PhaseCjk));
        OnPropertyChanged(nameof(IsFocus));
        OnPropertyChanged(nameof(IsRest));
        OnPropertyChanged(nameof(IsReady));
        OnPropertyChanged(nameof(IsRunning));
        OnPropertyChanged(nameof(IsPaused));
        OnPropertyChanged(nameof(IsFinished));
        OnPropertyChanged(nameof(HasHint));
        OnPropertyChanged(nameof(HintText));
        OnPropertyChanged(nameof(IsHintAccent));
        OnPropertyChanged(nameof(PrimaryLabel));
        OnPropertyChanged(nameof(ShowPauseIcon));
        OnPropertyChanged(nameof(ShowPlayIcon));
        OnPropertyChanged(nameof(TrayTooltip));
        OnPropertyChanged(nameof(TrayText));
        UpdateDots();
    }

    private void UpdateDots()
    {
        var onCount = _completedFocus;
        var currentIndex = (Phase == PocoPhase.Focus && State != TimerState.Finished && _completedFocus < FocusPerCycle)
            ? _completedFocus : -1;

        for (var i = 0; i < Dots.Count; i++)
        {
            Dots[i].Current = i == currentIndex;
            Dots[i].On = i < onCount || i == currentIndex;
        }
    }

    // —— 视图绑定 ——
    public string PhaseCjk => Phase switch { PocoPhase.Focus => "专注", PocoPhase.Short => "短休", _ => "大休" };

    public string MinutesText => (RemainingSeconds / 60).ToString("D2");
    public string SecondsText => (RemainingSeconds % 60).ToString("D2");

    public bool IsFocus => Phase == PocoPhase.Focus;
    public bool IsRest => Phase != PocoPhase.Focus;
    public bool IsReady => State == TimerState.Ready;
    public bool IsRunning => State == TimerState.Running;
    public bool IsPaused => State == TimerState.Paused;
    public bool IsFinished => State == TimerState.Finished;

    public bool HasHint => State is TimerState.Paused or TimerState.Finished;
    public bool IsHintAccent => State == TimerState.Finished;
    public string HintText => State switch
    {
        TimerState.Paused => "已暂停",
        TimerState.Finished => Phase == PocoPhase.Focus ? "专注结束，该休息了" : "休息结束，继续专注",
        _ => string.Empty,
    };

    public string PrimaryLabel => IsRunning ? "暂停" : "开始";
    public bool ShowPauseIcon => IsRunning;
    public bool ShowPlayIcon => !IsRunning;

    public string TrayTooltip => $"Poco · {PhaseCjk} {MinutesText}:{SecondsText}";

    /// <summary>菜单栏倒计时文本（运行/暂停才显示；null 隐藏文字项）。</summary>
    public string? TrayText => TrayTextFormat.For(State, RemainingSeconds);
}
