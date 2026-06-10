namespace Poco.Models;

/// <summary>
/// 菜单栏倒计时文本的状态→文本映射（纯逻辑，无 UI 依赖）。
/// 设计：运行/暂停才显示，待开始/结束返回 null（菜单栏文字项隐藏）。
/// </summary>
public static class TrayTextFormat
{
    public static string? For(TimerState state, int remainingSeconds) => state switch
    {
        TimerState.Running => Clock(remainingSeconds),
        TimerState.Paused => $"⏸ {Clock(remainingSeconds)}",
        _ => null,
    };

    private static string Clock(int seconds) => $"{seconds / 60:D2}:{seconds % 60:D2}";
}
