using System;
using Avalonia.Media.Fonts;

namespace Poco;

/// <summary>
/// 把 Assets/Fonts 目录注册为内嵌字体集合，可在 XAML 里用
/// <c>fonts:Poco#字体族名</c> 直接按族名引用，避免 Application.Resources
/// 里 FontFamily 资源因字典合并而静默失效的问题。
/// </summary>
public sealed class PocoFontCollection : EmbeddedFontCollection
{
    public PocoFontCollection() : base(
        new Uri("fonts:Poco", UriKind.Absolute),
        new Uri("avares://Poco/Assets/Fonts", UriKind.Absolute))
    {
    }
}
