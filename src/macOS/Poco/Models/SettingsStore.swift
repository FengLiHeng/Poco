// 用户设置持久化（UserDefaults）：只存三个时长（分钟）与主题，不持久化计时进度。
import Foundation

enum SettingsStore {
    private static let focusKey = "focusMinutes"
    private static let shortKey = "shortMinutes"
    private static let longKey = "longMinutes"
    private static let darkKey = "isDarkTheme"

    static var focusMinutes: Int {
        get { minutes(forKey: focusKey, default: 25) }
        set { UserDefaults.standard.set(newValue, forKey: focusKey) }
    }

    static var shortMinutes: Int {
        get { minutes(forKey: shortKey, default: 5) }
        set { UserDefaults.standard.set(newValue, forKey: shortKey) }
    }

    static var longMinutes: Int {
        get { minutes(forKey: longKey, default: 15) }
        set { UserDefaults.standard.set(newValue, forKey: longKey) }
    }

    /// 主题：默认浅色（false），手动切换、不跟随系统。
    static var isDarkTheme: Bool {
        get { UserDefaults.standard.bool(forKey: darkKey) }
        set { UserDefaults.standard.set(newValue, forKey: darkKey) }
    }

    private static func minutes(forKey key: String, default def: Int) -> Int {
        let v = UserDefaults.standard.integer(forKey: key)
        return (1...60).contains(v) ? v : def
    }
}
