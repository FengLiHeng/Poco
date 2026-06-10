using Poco.Models;
using Xunit;

namespace Poco.Tests;

/// <summary>菜单栏倒计时文本的状态→文本映射（设计：运行/暂停才显示，其余隐藏）。</summary>
public class TrayTextFormatTests
{
    [Theory]
    [InlineData(1471, "24:31")] // 24 分 31 秒
    [InlineData(59, "00:59")]
    [InlineData(3600, "60:00")] // 上限 60 分钟，不进位到小时
    public void Running_ShowsMmSs(int remainingSeconds, string expected)
        => Assert.Equal(expected, TrayTextFormat.For(TimerState.Running, remainingSeconds));

    [Fact]
    public void Paused_ShowsPauseMarkWithTime()
        => Assert.Equal("⏸ 24:31", TrayTextFormat.For(TimerState.Paused, 1471));

    [Theory]
    [InlineData(TimerState.Ready)]
    [InlineData(TimerState.Finished)]
    public void ReadyAndFinished_Hidden(TimerState state)
        => Assert.Null(TrayTextFormat.For(state, 1500));
}
