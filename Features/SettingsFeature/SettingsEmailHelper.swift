import Localization
import UIKit

@MainActor
func openSupportEmail() {
    let email = "hmkannada@gmail.com"
    let ticketId = Int.random(in: 100_000 ... 999_999)
    let subject = "Pavitra Qur'an App Support | #\(ticketId)"

    // Get debug metrics
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    let package = Bundle.main.bundleIdentifier ?? "com.quran.kannada"
    let systemName = UIDevice.current.systemName
    let systemVersion = UIDevice.current.systemVersion

    // Get hardware model (e.g. iPhone16,1)
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let deviceModel = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }

    let locale = AppLanguage.rawValue

    let body = """
    (Write your message here)

    --- Debug info ---
    App: \(appVersion) (\(appBuild))
    Package: \(package)
    OS: \(systemName) \(systemVersion)
    Device: \(UIDevice.current.model) (\(deviceModel))
    Locale: \(locale)
    """

    var components = URLComponents()
    components.scheme = "mailto"
    components.path = email
    components.queryItems = [
        URLQueryItem(name: "subject", value: subject),
        URLQueryItem(name: "body", value: body),
    ]

    if let url = components.url {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                // Fallback: Copy email to clipboard if mail client is not configured
                UIPasteboard.general.string = email
            }
        }
    }
}
