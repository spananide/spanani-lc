//
//  SpananiEngine.swift
//  LiveContainer
//

import Foundation
import UIKit
import Combine
import Security

final class SpananiAlert: ObservableObject {
    static let shared = SpananiAlert()

    @Published var message: String?

    private init() {}
}

@MainActor
enum SpananiEngine {
    static var model: SharedModel {
        DataManager.shared.model
    }

    static func app(forBundleID id: String) -> LCAppModel? {
        if let found = model.apps.first(where: { $0.appInfo.bundleIdentifier() == id }) {
            return found
        }
        return model.hiddenApps.first(where: { $0.appInfo.bundleIdentifier() == id })
    }

    static func install(urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return
        }

        guard let testURL = URL(string: trimmed), testURL.scheme != nil else {
            SpananiAlert.shared.message = "Invalid URL"
            return
        }

        var c = URLComponents()
        c.scheme = "livecontainer"
        c.host = "install"
        c.queryItems = [URLQueryItem(name: "url", value: trimmed)]

        guard let url = c.url else {
            SpananiAlert.shared.message = "Invalid URL"
            return
        }

        model.selectedTab = .apps
        model.deepLink = url
    }

    static func launch(_ app: LCAppModel) {
        Task {
            do {
                try await app.runApp()
            } catch {
                await MainActor.run {
                    SpananiAlert.shared.message = error.localizedDescription
                }
            }
        }
    }

    static func remove(_ app: LCAppModel, deleteData: Bool) {
        do {
            guard let bundlePath = app.appInfo.bundlePath() else {
                throw CocoaError(.fileNoSuchFile)
            }

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: bundlePath) {
                try fileManager.removeItem(atPath: bundlePath)
            }

            model.apps.removeAll { $0 == app }
            model.hiddenApps.removeAll { $0 == app }

            if let schemes = app.appInfo.urlSchemes() as? [Any], !schemes.isEmpty {
                UserDefaults.lcShared().mutableArrayValue(forKey: "LCGuestURLSchemes").removeObjects(in: schemes)
            }

            if deleteData {
                for container in app.appInfo.containers {
                    let dataUUID = container.folderName
                    let containerURL = LCPath.dataPath.appendingPathComponent(dataUUID)
                    if fileManager.fileExists(atPath: containerURL.path) {
                        try fileManager.removeItem(at: containerURL)
                    }
                    LCUtils.removeAppKeychain(dataUUID: dataUUID)
                    model.appDataFolderNames.removeAll { $0 == dataUUID }
                }
            }
        } catch {
            SpananiAlert.shared.message = error.localizedDescription
        }
    }

    static func icon(for app: LCAppModel) -> UIImage? {
        app.appInfo.iconIsDarkIcon(false)
    }

    static var hasCertificate: Bool {
        LCUtils.appGroupUserDefault.data(forKey: "LCCertificateData") != nil
    }

    static var certificateDate: Date? {
        LCUtils.appGroupUserDefault.object(forKey: "LCCertificateUpdateDate") as? Date
    }

    static var storeEngineAvailable: Bool {
        UserDefaults.sideStoreExist()
    }

    static func openStoreEngine() {
        LCUtils.openSideStore()
    }

    static func importCertificateFromStoreEngine() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "signingCertificate",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrService as String: "com.kdt.livecontainer",
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return "No certificate found. Open the store engine, sign in with your Apple ID, then try again."
            } else {
                return "Keychain read error: \(status)"
            }
        }

        guard let data = item as? Data else {
            return "The certificate in the keychain is not valid."
        }

        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "signingCertificatePassword",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrService as String: "com.kdt.livecontainer",
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        var passwordItem: CFTypeRef?
        let passwordStatus = SecItemCopyMatching(passwordQuery as CFDictionary, &passwordItem)
        var password = ""
        if passwordStatus == errSecSuccess,
           let passwordData = passwordItem as? Data,
           let pwd = String(data: passwordData, encoding: .utf8) {
            password = pwd
        }

        guard LCUtils.getCertTeamId(withKeyData: data, password: password) != nil else {
            return "The certificate in the keychain is not valid."
        }

        LCUtils.appGroupUserDefault.set(data, forKey: "LCCertificateData")
        LCUtils.appGroupUserDefault.set(password, forKey: "LCCertificatePassword")
        LCUtils.appGroupUserDefault.set(NSDate.now, forKey: "LCCertificateUpdateDate")

        UserDefaults.standard.set(LCSharedUtils.appGroupID(), forKey: "LCAppGroupID")

        return nil
    }

    /// Imports the certificate the installer left for us: password(s) in Documents/spanani-cert.txt, p12 inside the embedded store framework.
    /// Returns nil when nothing was pending or the import worked, otherwise a short error text.
    @discardableResult
    static func importInstallerCertificateIfPending() -> String? {
        let txt = LCPath.docPath.appendingPathComponent("spanani-cert.txt")
        guard FileManager.default.fileExists(atPath: txt.path) else {
            return nil
        }

        defer {
            try? FileManager.default.removeItem(at: txt)
        }

        let contents = (try? String(contentsOf: txt, encoding: .utf8)) ?? ""
        let passwords = contents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let p12URL = Bundle.main.bundleURL.appendingPathComponent("Frameworks/SideStoreApp.framework/ALTCertificate.p12")
        guard FileManager.default.fileExists(atPath: p12URL.path),
              let data = try? Data(contentsOf: p12URL) else {
            return "The installer did not include a certificate. Import one in Advanced > LiveContainer settings."
        }

        for pw in passwords {
            if LCUtils.getCertTeamId(withKeyData: data, password: pw) != nil {
                LCUtils.appGroupUserDefault.set(data, forKey: "LCCertificateData")
                LCUtils.appGroupUserDefault.set(pw, forKey: "LCCertificatePassword")
                LCUtils.appGroupUserDefault.set(NSDate.now, forKey: "LCCertificateUpdateDate")
                UserDefaults.standard.set(LCSharedUtils.appGroupID(), forKey: "LCAppGroupID")
                return nil
            }
        }

        return "The certificate from the installer could not be opened. Import one in Advanced > LiveContainer settings."
    }

    static func removeCertificate() {
        LCUtils.appGroupUserDefault.set(nil, forKey: "LCCertificateData")
        LCUtils.appGroupUserDefault.set(nil, forKey: "LCCertificatePassword")
        LCUtils.appGroupUserDefault.set(nil, forKey: "LCCertificateUpdateDate")
        UserDefaults.standard.set(nil, forKey: "LCAppGroupID")
    }
}
