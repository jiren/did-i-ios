import Foundation
import UIKit

/// Whether this device has an Action Button. There's no API, so it goes by model: iPhone 15 Pro (iPhone16,1)
/// and every iPhone since have one.
enum ActionButtonSupport {
    static var isAvailable: Bool {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        return hasActionButton(modelIdentifier: modelIdentifier)
    }

    static func hasActionButton(modelIdentifier: String) -> Bool {
        guard modelIdentifier.hasPrefix("iPhone") else { return false }
        let numbers = modelIdentifier.dropFirst("iPhone".count).split(separator: ",")
        guard let major = numbers.first.flatMap({ Int($0) }) else { return false }
        return major >= 16
    }

    private static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
