using System;
using System.Collections.Generic;
using Poco.Models;
using Xunit;

namespace Poco.Tests;

public class PomodoroLogicTests
{
    [Theory]
    [InlineData(PocoPhase.Focus, 0, PocoPhase.Short)] // 专注未满 4 → 短休
    [InlineData(PocoPhase.Focus, 3, PocoPhase.Short)]
    [InlineData(PocoPhase.Focus, 4, PocoPhase.Long)]  // 第 4 个专注后 → 大休
    [InlineData(PocoPhase.Short, 2, PocoPhase.Focus)] // 休息后回到专注
    [InlineData(PocoPhase.Long, 4, PocoPhase.Focus)]
    public void NextPhase_FollowsCycleRules(PocoPhase current, int completed, PocoPhase expected)
        => Assert.Equal(expected, PomodoroLogic.NextPhase(current, completed));

    [Theory]
    [InlineData(PocoPhase.Long, 4, true)]   // 大休结束、计数已满 → 开启新一组
    [InlineData(PocoPhase.Short, 1, false)] // 短休不归零
    [InlineData(PocoPhase.Focus, 4, false)] // 专注阶段本身不开启新组
    public void StartsNewCycle_OnlyAfterCompletedLong(PocoPhase current, int completed, bool expected)
        => Assert.Equal(expected, PomodoroLogic.StartsNewCycle(current, completed));

    /// <summary>完整一组：4 个专注穿插 3 次短休，第 4 个专注后进大休，大休后归零开新组。</summary>
    [Fact]
    public void FullCycle_FourFocus_OneLong_ThenReset()
    {
        var phase = PocoPhase.Focus;
        var completed = 0;
        var sequence = new List<PocoPhase>();

        // 模拟 8 次「阶段自然结束 → 推进」，与 MainWindowViewModel 的规则一致：
        // 专注自然走完才计数 +1，再据此决定下一阶段。
        for (var i = 0; i < 8; i++)
        {
            if (phase == PocoPhase.Focus)
                completed = Math.Min(completed + 1, PomodoroLogic.FocusPerCycle);

            var newCycle = PomodoroLogic.StartsNewCycle(phase, completed);
            phase = PomodoroLogic.NextPhase(phase, completed);
            if (newCycle) completed = 0;

            sequence.Add(phase);
        }

        Assert.Equal(new[]
        {
            PocoPhase.Short, PocoPhase.Focus, PocoPhase.Short, PocoPhase.Focus,
            PocoPhase.Short, PocoPhase.Focus, PocoPhase.Long, PocoPhase.Focus,
        }, sequence);
        Assert.Equal(0, completed); // 大休后已归零，新一组从头开始
    }

    /// <summary>跳过专注不计入完成数：跳过第 4 个专注应进短休而非大休（#8 语义）。</summary>
    [Fact]
    public void SkippingFourthFocus_GoesToShort_NotLong()
    {
        // 已完成 3 个专注，正在第 4 个专注但选择「跳过」——跳过不 +1
        const int completedBeforeSkip = 3;
        Assert.Equal(PocoPhase.Short, PomodoroLogic.NextPhase(PocoPhase.Focus, completedBeforeSkip));
    }
}
