import Foundation
import SwiftUI
import Combine

// MARK: - SpananiAlert Stub

final class SpananiAlert: ObservableObject {
    static let shared = SpananiAlert()

    @Published var message: String?

    private init() {}
}

// MARK: - SpananiEngine Stub

@MainActor
enum SpananiEngine {
    static var hasCertificate: Bool {
        true
    }

    static var certificateDate: Date? {
        Calendar.current.date(byAdding: .day, value: -3, to: Date())
    }

    static var storeEngineAvailable: Bool {
        true
    }

    static func openStoreEngine() {}

    static func importCertificateFromStoreEngine() -> String? {
        nil
    }

    @discardableResult
    static func importInstallerCertificateIfPending() -> String? {
        nil
    }

    static func removeCertificate() {}

    static var appExpiryDate: Date? {
        Calendar.current.date(byAdding: .day, value: 5, to: Date())
    }

    static let expiryReminderKey = "spanani.expiryReminder"

    static var expiryReminderEnabled: Bool {
        true
    }

    static func daysUntilExpiry() -> Int? {
        5
    }

    static func updateExpiryReminder() {}
}

// MARK: - DataManager & SharedModel Stubs

final class SharedModel: ObservableObject {
    init() {}
}

final class DataManager {
    static let shared = DataManager()
    let model = SharedModel()
    private init() {}
}

// MARK: - LCAppSortManager Stub

final class LCAppSortManager: ObservableObject {
    static let shared = LCAppSortManager()
    private init() {}
}

// MARK: - LCSettingsView & LCTweaksView Stubs

struct LCSettingsView: View {
    var body: some View {
        Text("LiveContainer Settings")
    }
}

struct LCTweaksView: View {
    var body: some View {
        Text("Tweaks")
    }
}
