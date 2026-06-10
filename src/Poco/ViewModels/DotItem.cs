using CommunityToolkit.Mvvm.ComponentModel;

namespace Poco.ViewModels;

/// <summary>一颗轮次圆点：On＝点亮（已完成/进行中），Current＝当前轮（带光晕外圈）。</summary>
public partial class DotItem : ObservableObject
{
    [ObservableProperty] private bool _on;
    [ObservableProperty] private bool _current;
}
