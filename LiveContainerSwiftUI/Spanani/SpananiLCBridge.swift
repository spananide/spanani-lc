//
//  SpananiLCBridge.swift
//  LiveContainer
//

import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class SpananiLCBridge: StoreActions {
    static let shared = SpananiLCBridge()

    let model: StoreModel

    private var cancellables = Set<AnyCancellable>()
    private var downloadURLs: [String: URL] = [:]
    private let defaultSourceURL = "https://raw.githubusercontent.com/spananide/spanani-store/develop/source/source.json"

    private init() {
        let storeModel = StoreModel(
            activeLimit: 3,
            remindersEnabled: false,
            actions: nil
        )
        self.model = storeModel
        storeModel.actions = self
        storeModel.account = AccountInfo(appleID: nil, isPaired: false, vpnOn: false, widgetsReady: true)

        // Observe LiveContainer installed app changes and rebuild installed list
        DataManager.shared.model.$apps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildInstalled()
            }
            .store(in: &cancellables)

        rebuildInstalled()

        Task {
            await refreshSources()
        }
    }

    // MARK: - Installed Apps Synchronization

    private func rebuildInstalled() {
        let lcApps = DataManager.shared.model.apps
        var seenIDs = Set<String>()
        var newInstalled: [InstalledItem] = []

        for lcApp in lcApps {
            let bundleID = lcApp.appInfo.bundleIdentifier() ?? lcApp.bundleIdentifier
            guard !bundleID.isEmpty, !seenIDs.contains(bundleID) else { continue }
            seenIDs.insert(bundleID)

            let displayName = lcApp.appInfo.displayName() ?? lcApp.displayName
            let version = lcApp.appInfo.version() ?? lcApp.version
            let localIcon = SpananiEngine.icon(for: lcApp)

            var hasUpdate = false
            var latestVersion: String? = nil

            if let catalogApp = model.apps.first(where: { $0.id == bundleID }) {
                if catalogApp.versionString.compare(version, options: .numeric) == .orderedDescending {
                    hasUpdate = true
                    latestVersion = catalogApp.versionString
                }
            }

            let item = InstalledItem(
                id: bundleID,
                name: displayName,
                versionString: version,
                tint: .accent,
                symbol: "app.fill",
                iconURL: nil,
                expiresAt: .distantFuture,
                isActive: true,
                hasUpdate: hasUpdate,
                latestVersion: latestVersion,
                iconImage: localIcon
            )
            newInstalled.append(item)
        }

        model.installed = newInstalled
    }

    // MARK: - Sources Management

    private func userSourceURLs() -> [String] {
        UserDefaults.standard.stringArray(forKey: "spanani.sources") ?? []
    }

    private func allSourceURLs() -> [String] {
        var urls = [defaultSourceURL]
        for url in userSourceURLs() {
            let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed != defaultSourceURL && !urls.contains(trimmed) {
                urls.append(trimmed)
            }
        }
        return urls
    }

    func refreshSources() async {
        let sourceURLs = allSourceURLs()
        var fetchedSources: [String: Result<ParsedSource, Error>] = [:]

        // Fetch all sources concurrently with a 20s timeout
        await withTaskGroup(of: (String, Result<ParsedSource, Error>).self) { group in
            for urlString in sourceURLs {
                group.addTask {
                    do {
                        guard let url = URL(string: urlString) else {
                            throw NSError(
                                domain: "SpananiLCBridge",
                                code: 400,
                                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
                            )
                        }
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 20.0
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
                            throw NSError(
                                domain: "SpananiLCBridge",
                                code: code,
                                userInfo: [NSLocalizedDescriptionKey: "HTTP \(code) error"]
                            )
                        }
                        let parsed = try Self.parseSource(data: data)
                        return (urlString, .success(parsed))
                    } catch {
                        return (urlString, .failure(error))
                    }
                }
            }

            for await (urlString, result) in group {
                fetchedSources[urlString] = result
            }
        }

        var finalApps: [StoreItem] = []
        var seenAppIDs = Set<String>()
        var finalSources: [SpSourceItem] = []
        var allChanges: [ChangeItem] = []
        var newDownloadURLs: [String: URL] = [:]

        var isFirstAppOfFirstSource = true

        for urlString in sourceURLs {
            guard let result = fetchedSources[urlString] else { continue }
            switch result {
            case .success(let parsedSource):
                finalSources.append(SpSourceItem(
                    id: urlString,
                    name: parsedSource.name,
                    url: urlString,
                    appCount: parsedSource.apps.count,
                    tint: .accent
                ))

                for app in parsedSource.apps {
                    // this app already is the store: the standalone spanani Store makes no sense inside it
                    if app.bundleIdentifier == "de.spanani.store" { continue }
                    let appTint = Self.parseColor(app.tintColor)

                    // Collect changelog entries
                    for v in app.versions {
                        allChanges.append(ChangeItem(
                            id: "\(app.bundleIdentifier)@\(v.version)",
                            appID: app.bundleIdentifier,
                            appName: app.name,
                            tint: appTint,
                            symbol: "app.fill",
                            iconURL: app.iconURL,
                            version: v.version,
                            date: Self.parseDate(v.date),
                            notes: v.localizedDescription ?? ""
                        ))
                    }

                    // Save latest download URL
                    let latestDL = app.versions.first?.downloadURL ?? app.downloadURL
                    if let latestDL = latestDL, newDownloadURLs[app.bundleIdentifier] == nil {
                        newDownloadURLs[app.bundleIdentifier] = latestDL
                    }

                    // Deduplicate apps by bundleIdentifier: first source wins
                    guard !seenAppIDs.contains(app.bundleIdentifier) else { continue }
                    seenAppIDs.insert(app.bundleIdentifier)

                    let isFeatured = isFirstAppOfFirstSource
                    let heroTagline = isFeatured ? (app.subtitle ?? "") : ""
                    if isFirstAppOfFirstSource {
                        isFirstAppOfFirstSource = false
                    }

                    let catRaw = app.category?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let category = (catRaw?.isEmpty == false ? catRaw!.capitalized : "Other")
                    let size = app.versions.first?.size ?? app.size ?? 0
                    let version = app.version ?? app.versions.first?.version ?? "1.0"
                    let whatsNew = app.versions.first?.localizedDescription ?? ""

                    let storeItem = StoreItem(
                        id: app.bundleIdentifier,
                        name: app.name,
                        subtitle: app.subtitle ?? "",
                        developer: app.developerName,
                        description: app.localizedDescription ?? "",
                        category: category,
                        versionString: version,
                        sizeBytes: size,
                        sourceName: parsedSource.name,
                        tint: appTint,
                        symbol: "app.fill",
                        iconURL: app.iconURL,
                        screenshotURLs: app.screenshotURLs,
                        whatsNew: whatsNew,
                        permissions: app.permissions,
                        isFeatured: isFeatured,
                        heroTagline: heroTagline
                    )
                    finalApps.append(storeItem)
                }

            case .failure:
                let fallback = URL(string: urlString)?.host?.capitalized ?? "Source"
                finalSources.append(SpSourceItem(
                    id: urlString,
                    name: fallback,
                    url: urlString,
                    appCount: 0,
                    tint: .accent
                ))
            }
        }

        allChanges.sort { $0.date > $1.date }
        let finalChanges = Array(allChanges.prefix(40))

        self.downloadURLs = newDownloadURLs
        self.model.apps = finalApps
        self.model.sources = finalSources
        self.model.changes = finalChanges

        self.rebuildInstalled()
    }

    func addSource(urlString: String) async throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let host = url.host, !host.isEmpty else {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL. Enter a complete address."]
            )
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20.0
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Could not reach source: \(error.localizedDescription)"]
            )
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(
                domain: "SpananiLCBridge",
                code: code,
                userInfo: [NSLocalizedDescriptionKey: "Source returned HTTP \(code)."]
            )
        }

        _ = try Self.parseSource(data: data)

        var sources = userSourceURLs()
        if !sources.contains(trimmed) && trimmed != defaultSourceURL {
            sources.append(trimmed)
            UserDefaults.standard.set(sources, forKey: "spanani.sources")
        }

        await refreshSources()
    }

    func removeSource(_ source: SpSourceItem) async throws {
        if source.url == defaultSourceURL || source.id == defaultSourceURL {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "The default source cannot be removed."]
            )
        }

        var sources = userSourceURLs()
        sources.removeAll { $0 == source.url || $0 == source.id }
        UserDefaults.standard.set(sources, forKey: "spanani.sources")

        await refreshSources()
    }

    // MARK: - StoreActions Implementation

    func install(_ app: StoreItem, progress: @escaping (Double) -> Void) async throws {
        guard let downloadURL = downloadURLs[app.id] else {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No download URL available for \(app.name)."]
            )
        }

        SpananiAlert.shared.message = nil
        let startError = model.lastError

        let existingApp = SpananiEngine.app(forBundleID: app.id)
        let initialInstallDate = existingApp?.appInfo.installationDate
        let initialAppInfo = existingApp?.appInfo

        SpananiEngine.install(urlString: downloadURL.absoluteString)

        let startTime = Date()
        let timeout: TimeInterval = 600.0 // 10 minutes

        while true {
            try await Task.sleep(nanoseconds: 500_000_000)

            if let alertMsg = SpananiAlert.shared.message {
                SpananiAlert.shared.message = nil
                throw NSError(
                    domain: "SpananiLCBridge",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: alertMsg]
                )
            }

            // SpananiRootView moves engine errors into model.lastError, so watch that too
            if let err = model.lastError, err != startError {
                throw NSError(domain: "SpananiLCBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: err])
            }

            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > timeout {
                throw NSError(
                    domain: "SpananiLCBridge",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: "Installation timed out."]
                )
            }

            progress(min(0.9, elapsed / 90.0))

            if existingApp == nil {
                if SpananiEngine.app(forBundleID: app.id) != nil {
                    progress(1.0)
                    return
                }
            } else {
                // If the app was already installed, detect completion by installationDate change or LCAppInfo object identity change.
                // Limitation: If replacement installation fails silently without updating installationDate or appInfo, the poll times out after 10 minutes.
                if let currentApp = SpananiEngine.app(forBundleID: app.id) {
                    let currentDate = currentApp.appInfo.installationDate
                    if let initialDate = initialInstallDate {
                        if let currentDate = currentDate, currentDate > initialDate {
                            progress(1.0)
                            return
                        }
                    } else if currentDate != nil || currentApp.appInfo !== initialAppInfo {
                        progress(1.0)
                        return
                    }
                }
            }
        }
    }

    func installIPA(_ url: URL, progress: @escaping (Double) -> Void) async throws {
        SpananiAlert.shared.message = nil
        let startError = model.lastError

        let initialCount = DataManager.shared.model.apps.count + DataManager.shared.model.hiddenApps.count

        var initialDates: [String: Date] = [:]
        for app in DataManager.shared.model.apps + DataManager.shared.model.hiddenApps {
            let id = app.appInfo.bundleIdentifier() ?? app.bundleIdentifier
            if let date = app.appInfo.installationDate as Date? {
                initialDates[id] = date
            }
        }

        SpananiEngine.install(urlString: url.absoluteString)

        let startTime = Date()
        let timeout: TimeInterval = 600.0 // 10 minutes

        while true {
            try await Task.sleep(nanoseconds: 500_000_000)

            if let alertMsg = SpananiAlert.shared.message {
                SpananiAlert.shared.message = nil
                throw NSError(
                    domain: "SpananiLCBridge",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: alertMsg]
                )
            }

            // SpananiRootView moves engine errors into model.lastError, so watch that too
            if let err = model.lastError, err != startError {
                throw NSError(domain: "SpananiLCBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: err])
            }

            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > timeout {
                throw NSError(
                    domain: "SpananiLCBridge",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: "IPA installation timed out."]
                )
            }

            progress(min(0.9, elapsed / 90.0))

            let currentCount = DataManager.shared.model.apps.count + DataManager.shared.model.hiddenApps.count
            if currentCount > initialCount {
                progress(1.0)
                return
            }

            for app in DataManager.shared.model.apps + DataManager.shared.model.hiddenApps {
                let id = app.appInfo.bundleIdentifier() ?? app.bundleIdentifier
                if let newDate = app.appInfo.installationDate as Date?,
                   let oldDate = initialDates[id],
                   newDate > oldDate {
                    progress(1.0)
                    return
                }
            }
        }
    }

    func open(_ app: InstalledItem) {
        if let lcApp = SpananiEngine.app(forBundleID: app.id) {
            SpananiEngine.launch(lcApp)
        }
    }

    func deleteApp(_ app: InstalledItem) async throws {
        guard let lcApp = SpananiEngine.app(forBundleID: app.id) else {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "App not found."]
            )
        }
        SpananiEngine.remove(lcApp, deleteData: true)
    }

    func refresh(_ app: InstalledItem) async throws {
        throw NSError(
            domain: "SpananiLCBridge",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Not available for LiveContainer apps"]
        )
    }

    func refreshAll(progress: @escaping (Double) -> Void) async throws {
        // Not applicable for LiveContainer apps
        return
    }

    func deactivate(_ app: InstalledItem) async throws {
        throw NSError(
            domain: "SpananiLCBridge",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Not available for LiveContainer apps"]
        )
    }

    func signOut() async {}

    func setAutoRefresh(_ enabled: Bool) async {}

    func setReminders(_ enabled: Bool) async -> Bool { false }

    // MARK: - Parsing Helpers

    private static func parseColor(_ hex: String?) -> Color {
        guard var cleaned = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !cleaned.isEmpty else {
            return Color.accent
        }
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }
        if cleaned.count == 6 {
            if let val = UInt32(cleaned, radix: 16) {
                return Color(uiColor: UIColor(hex: val))
            }
        } else if cleaned.count == 8 {
            if let val = UInt32(cleaned.prefix(6), radix: 16) {
                return Color(uiColor: UIColor(hex: val))
            }
        }
        return Color.accent
    }

    private nonisolated static func parseDate(_ string: String?) -> Date {
        guard let string = string, !string.isEmpty else { return Date() }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: string) {
            return d
        }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: string) {
            return d
        }
        return Date()
    }

    private nonisolated static func parseSource(data: Data) throws -> ParsedSource {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "SpananiLCBridge",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format: expected dictionary at root."]
            )
        }

        let sourceName = (json["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = (json["identifier"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        var parsedApps: [ParsedApp] = []
        if let appsArray = json["apps"] as? [[String: Any]] {
            for appDict in appsArray {
                guard let name = appDict["name"] as? String,
                      let bundleID = (appDict["bundleIdentifier"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !bundleID.isEmpty else {
                    continue
                }

                let devName = appDict["developerName"] as? String ?? ""
                let subtitle = appDict["subtitle"] as? String
                let locDesc = appDict["localizedDescription"] as? String
                let iconURL = (appDict["iconURL"] as? String).flatMap { URL(string: $0) }
                let tintColor = appDict["tintColor"] as? String
                let category = appDict["category"] as? String
                let version = appDict["version"] as? String
                let date = appDict["date"] as? String
                let downloadURL = (appDict["downloadURL"] as? String).flatMap { URL(string: $0) }
                let size = parseSize(appDict["size"])

                var versions: [ParsedVersion] = []
                if let versArray = appDict["versions"] as? [[String: Any]] {
                    for vDict in versArray {
                        if let vStr = vDict["version"] as? String {
                            let vDate = vDict["date"] as? String
                            let vDesc = vDict["localizedDescription"] as? String
                            let vURL = (vDict["downloadURL"] as? String).flatMap { URL(string: $0) }
                            let vSize = parseSize(vDict["size"])
                            versions.append(ParsedVersion(
                                version: vStr,
                                date: vDate,
                                localizedDescription: vDesc,
                                downloadURL: vURL,
                                size: vSize
                            ))
                        }
                    }
                }

                var permissions: [String] = []
                if let permsDict = appDict["appPermissions"] as? [String: Any] {
                    if let entitlements = permsDict["entitlements"] as? [String] {
                        permissions.append(contentsOf: entitlements)
                    }
                    if let privacy = permsDict["privacy"] as? [String: Any] {
                        for key in privacy.keys.sorted() {
                            permissions.append(humanReadablePermission(key))
                        }
                    }
                }

                var screenshotURLs: [URL] = []
                if let screenshotsArray = appDict["screenshots"] as? [Any] {
                    for item in screenshotsArray {
                        if let str = item as? String, let u = URL(string: str) {
                            screenshotURLs.append(u)
                        } else if let dict = item as? [String: Any],
                                  let str = (dict["imageURL"] ?? dict["url"]) as? String,
                                  let u = URL(string: str) {
                            screenshotURLs.append(u)
                        }
                    }
                } else if let screenshotsDict = appDict["screenshots"] as? [String: Any] {
                    let list = (screenshotsDict["iphone"] as? [Any]) ?? (screenshotsDict["ipad"] as? [Any]) ?? []
                    for item in list {
                        if let str = item as? String, let u = URL(string: str) {
                            screenshotURLs.append(u)
                        } else if let dict = item as? [String: Any],
                                  let str = (dict["imageURL"] ?? dict["url"]) as? String,
                                  let u = URL(string: str) {
                            screenshotURLs.append(u)
                        }
                    }
                }

                parsedApps.append(ParsedApp(
                    name: name,
                    bundleIdentifier: bundleID,
                    developerName: devName,
                    subtitle: subtitle,
                    localizedDescription: locDesc,
                    iconURL: iconURL,
                    tintColor: tintColor,
                    category: category,
                    version: version,
                    date: date,
                    downloadURL: downloadURL,
                    size: size,
                    versions: versions,
                    permissions: permissions,
                    screenshotURLs: screenshotURLs
                ))
            }
        }

        let name = (sourceName?.isEmpty == false ? sourceName! : (identifier?.isEmpty == false ? identifier! : "Source"))
        return ParsedSource(name: name, identifier: identifier, apps: parsedApps)
    }

    private nonisolated static func parseSize(_ raw: Any?) -> Int64? {
        if let num = raw as? NSNumber {
            return num.int64Value
        }
        if let str = raw as? String {
            return Int64(str)
        }
        return nil
    }

    private nonisolated static func humanReadablePermission(_ key: String) -> String {
        var cleaned = key
        if cleaned.hasPrefix("NS") {
            cleaned.removeFirst(2)
        }
        if cleaned.hasSuffix("UsageDescription") {
            cleaned.removeLast("UsageDescription".count)
        }
        var result = ""
        var prevChar: Character?
        for char in cleaned {
            if char.isUppercase, let prev = prevChar, prev.isLowercase {
                result.append(" ")
            }
            result.append(char)
            prevChar = char
        }
        return result.isEmpty ? key : result
    }
}

private struct ParsedSource: Sendable {
    let name: String
    let identifier: String?
    let apps: [ParsedApp]
}

private struct ParsedApp: Sendable {
    let name: String
    let bundleIdentifier: String
    let developerName: String
    let subtitle: String?
    let localizedDescription: String?
    let iconURL: URL?
    let tintColor: String?
    let category: String?
    let version: String?
    let date: String?
    let downloadURL: URL?
    let size: Int64?
    let versions: [ParsedVersion]
    let permissions: [String]
    let screenshotURLs: [URL]
}

private struct ParsedVersion: Sendable {
    let version: String
    let date: String?
    let localizedDescription: String?
    let downloadURL: URL?
    let size: Int64?
}
