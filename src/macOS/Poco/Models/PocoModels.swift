// 番茄钟核心枚举（纯逻辑，无 UI 依赖）
import Foundation

/// 番茄钟阶段类型。
enum PocoPhase {
    case focus // 专注
    case short // 短休
    case long  // 大休
}

/// 计时器状态机。
enum TimerState {
    case ready    // 待开始：显示满时长，未走表
    case running  // 运行中：递减
    case paused   // 已暂停：冻结剩余
    case finished // 已结束：归零，等待手动推进
}
