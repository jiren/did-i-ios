import CoreFoundation
import Foundation

/// Tells the app and the widget extension that the other one wrote to the shared store (a Darwin notification).
nonisolated enum StoreChangeSignal {
    static let name = "com.elo.Did-I.storeChanged"
    private static let writerKey = "lastStoreWriter"

    static func post() {
        AppGroup.defaults.set(Int(ProcessInfo.processInfo.processIdentifier), forKey: writerKey)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(name as CFString), nil, nil, true
        )
    }

    /// Darwin notifications also reach the process that posted them; this one ignores its own.
    static var lastWriteWasThisProcess: Bool {
        AppGroup.defaults.integer(forKey: writerKey) == Int(ProcessInfo.processInfo.processIdentifier)
    }
}

/// Calls `handler` on the main actor whenever another process posts `StoreChangeSignal`.
final class StoreChangeObserver {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let box = Unmanaged<StoreChangeObserver>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in box.receive() }
            },
            StoreChangeSignal.name as CFString,
            nil,
            .deliverImmediately
        )
    }

    isolated deinit {
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque()
        )
    }

    private func receive() {
        guard !StoreChangeSignal.lastWriteWasThisProcess else { return }
        handler()
    }
}
