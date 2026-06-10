namespace Poco.Models;

/// <summary>番茄钟阶段类型。</summary>
public enum PocoPhase
{
    Focus, // 专注
    Short, // 短休
    Long,  // 大休
}

/// <summary>计时器状态机。</summary>
public enum TimerState
{
    Ready,    // 待开始：显示满时长，未走表
    Running,  // 运行中：递减
    Paused,   // 已暂停：冻结剩余
    Finished, // 已结束：归零，等待手动推进
}
