namespace Poco.Models;

/// <summary>
/// 番茄钟阶段推进的纯逻辑（无计时器、无 UI 依赖，便于单元测试）。
/// 规则：每完成 4 个专注 → 1 次大休 → 计数归零，循环往复。
/// </summary>
public static class PomodoroLogic
{
    /// <summary>每组固定 4 轮专注。</summary>
    public const int FocusPerCycle = 4;

    /// <summary>给定当前阶段与本组已完成专注数，返回下一阶段。</summary>
    public static PocoPhase NextPhase(PocoPhase current, int completedFocus)
    {
        if (current == PocoPhase.Focus)
            return completedFocus >= FocusPerCycle ? PocoPhase.Long : PocoPhase.Short;
        // 短休 / 大休结束后都回到专注
        return PocoPhase.Focus;
    }

    /// <summary>从某阶段推进到下一阶段时，是否应开启新一组（专注计数归零）。</summary>
    public static bool StartsNewCycle(PocoPhase current, int completedFocus)
    {
        var next = NextPhase(current, completedFocus);
        return current != PocoPhase.Focus && next == PocoPhase.Focus && completedFocus >= FocusPerCycle;
    }
}
