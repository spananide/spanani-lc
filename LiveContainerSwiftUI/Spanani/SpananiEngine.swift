//
//  SpananiEngine.swift
//  LiveContainer
//

import Foundation
import UIKit
import Combine

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
}
