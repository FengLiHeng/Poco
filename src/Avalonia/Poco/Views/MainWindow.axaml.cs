using Avalonia.Controls;
using System.ComponentModel;

namespace Poco.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    /// <summary>关闭主窗口隐藏到菜单栏，不退出应用（除非由菜单栏「退出」触发）。</summary>
    protected override void OnClosing(WindowClosingEventArgs e)
    {
        if (!App.IsExiting)
        {
            e.Cancel = true;
            Hide();
        }
        base.OnClosing(e);
    }
}
