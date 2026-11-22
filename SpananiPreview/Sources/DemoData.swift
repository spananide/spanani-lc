import Foundation
import SwiftUI
import UIKit

enum DemoData {
    @MainActor
    static func makeModel() -> StoreModel {
        let apps: [StoreItem] = [
            StoreItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                subtitle: "Wiki & link checker for free knowledge",
                developer: "Free Software Collective",
                description: "The most comprehensive directory of useful tools, educational resources, and media on the web. Features integrated security checks for external links and offline bookmarks. Fast full-text search and curated recommendations.",
                category: "Utilities",
                versionString: "1.6.0",
                sizeBytes: 19_400_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Version 1.6.0 introduces an improved link filter, dark mode optimizations, and faster loading times for offline articles.",
                permissions: ["Network Access", "Local Storage"],
                isFeatured: true,
                heroTagline: "Developer Favorite"
            ),
            StoreItem(
                id: "kh.feather.app",
                name: "Feather",
                subtitle: "Open-source on-device IPA signer",
                developer: "Feather Open Source",
                description: "An open-source on-device iOS application signer and manager. Feather allows you to sign and install IPAs with custom certificates, manage app groups, and configure entitlements directly on your device.",
                category: "Utilities",
                versionString: "1.2.1",
                sizeBytes: 24_500_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.35, green: 0.65, blue: 0.95),
                symbol: "signature",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Improved certificate parser, modernized interface, and support for iPad multitasking.",
                permissions: ["Local Storage", "Keychain Access"],
                isFeatured: true,
                heroTagline: "Open-source IPA signer"
            ),
            StoreItem(
                id: "de.spanani.kippe",
                name: "Tilt",
                subtitle: "Minimalist physics and balance game",
                developer: "Studio Incline",
                description: "Keep the floating platform balanced with delicate device tilting. Physics-based puzzles with subtle haptic feedback and a soothing soundtrack. Every level tests your dexterity.",
                category: "Games",
                versionString: "1.0.4",
                sizeBytes: 42_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "10 new levels, support for enhanced haptics, and finer gyroscope sensitivity.",
                permissions: ["Motion Sensors"],
                isFeatured: true,
                heroTagline: "New in Store"
            ),
            StoreItem(
                id: "de.spanani.pausenklau",
                name: "Break Puzzles",
                subtitle: "Quick mini-puzzles for short breaks",
                developer: "Lukas Bergmann",
                description: "Bite-sized brain teasers designed to take exactly three minutes, perfect for your coffee break. No ads, no in-app purchases, just pure puzzle fun. Daily challenges shareable with friends.",
                category: "Games",
                versionString: "2.3.1",
                sizeBytes: 15_200_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.25, green: 0.75, blue: 0.85),
                symbol: "gamecontroller.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "New category for number puzzles and synchronized high scores.",
                permissions: ["Local Storage"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.wetterfrosch",
                name: "Weather Frog",
                subtitle: "Open-source weather forecast without trackers",
                developer: "Open Meteorology",
                description: "High-precision forecasts directly from European meteorological services without ad trackers. Minute-by-minute radar images and detailed wind and pressure graphs. Efficient background polling saves battery.",
                category: "Weather",
                versionString: "4.1.2",
                sizeBytes: 17_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.20, green: 0.60, blue: 0.95),
                symbol: "cloud.sun.rain.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Minute-by-minute widget updates when severe rain is imminent.",
                permissions: ["Location Services (While In Use)"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.notizzettel",
                name: "Notes",
                subtitle: "Clean Markdown notes with Git sync",
                developer: "Plaintext Software",
                description: "Your thoughts in plain text, stored locally and optionally synchronized with Git. Fast keyboard shortcuts, wiki links, and tag organization. Full control over your personal notes.",
                category: "Productivity",
                versionString: "1.8.4",
                sizeBytes: 14_300_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.85, green: 0.75, blue: 0.30),
                symbol: "note.text",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Added support for mathematical formulas and Mermaid diagrams.",
                permissions: ["File Access", "Local Storage"],
                isFeatured: false,
                heroTagline: ""
            )
        ]

        let installed: [InstalledItem] = [
            InstalledItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                versionString: "1.5.1",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(1 * 86400 + 3 * 3600),
                isActive: true,
                hasUpdate: true,
                latestVersion: "1.6.0"
            ),
            InstalledItem(
                id: "de.spanani.kippe",
                name: "Tilt",
                versionString: "1.0.4",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(5 * 86400 + 14 * 3600),
                isActive: true,
                hasUpdate: false,
                latestVersion: nil
            ),
            InstalledItem(
                id: "kh.feather.app",
                name: "Feather",
                versionString: "1.2.1",
                tint: Color(red: 0.35, green: 0.65, blue: 0.95),
                symbol: "signature",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(6 * 86400),
                isActive: true,
                hasUpdate: false,
                latestVersion: nil
            )
        ]

        let sources: [SpSourceItem] = [
            SpSourceItem(
                id: "source-spanani",
                name: "spanani.de",
                url: "https://apps.spanani.de/source.json",
                appCount: 6,
                tint: .accentColor
            ),
            SpSourceItem(
                id: "source-community",
                name: "Community Source",
                url: "https://community.spanani.de/apps.json",
                appCount: 4,
                tint: .accentColor
            )
        ]

        let account = AccountInfo(
            appleID: "user@icloud.com",
            isPaired: true,
            vpnOn: true,
            widgetsReady: true
        )

        let now = Date()
        let changes: [ChangeItem] = [
            ChangeItem(
                id: "de.spanani.fmhy@1.6.0",
                appID: "de.spanani.fmhy",
                appName: "FMHY",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                version: "1.6.0",
                date: now.addingTimeInterval(-2 * 3600),
                notes: "Version 1.6.0 introduces an improved link filter, dark mode optimizations, and faster loading times for offline articles."
            ),
            ChangeItem(
                id: "kh.feather.app@1.2.1",
                appID: "kh.feather.app",
                appName: "Feather",
                tint: Color(red: 0.35, green: 0.65, blue: 0.95),
                symbol: "signature",
                version: "1.2.1",
                date: now.addingTimeInterval(-4 * 3600),
                notes: "Improved certificate parser, modernized interface, and support for iPad multitasking."
            ),
            ChangeItem(
                id: "de.spanani.kippe@1.0.4",
                appID: "de.spanani.kippe",
                appName: "Tilt",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                version: "1.0.4",
                date: now.addingTimeInterval(-6 * 3600),
                notes: "10 new levels, support for enhanced haptics, and finer gyroscope sensitivity."
            ),
            ChangeItem(
                id: "de.spanani.wetterfrosch@4.1.2",
                appID: "de.spanani.wetterfrosch",
                appName: "Weather Frog",
                tint: Color(red: 0.20, green: 0.60, blue: 0.95),
                symbol: "cloud.sun.rain.fill",
                version: "4.1.2",
                date: now.addingTimeInterval(-26 * 3600),
                notes: "Minute-by-minute widget updates when severe rain is imminent."
            ),
            ChangeItem(
                id: "de.spanani.pausenklau@2.3.1",
                appID: "de.spanani.pausenklau",
                appName: "Break Puzzles",
                tint: Color(red: 0.25, green: 0.75, blue: 0.85),
                symbol: "gamecontroller.fill",
                version: "2.3.1",
                date: now.addingTimeInterval(-30 * 3600),
                notes: "New category for number puzzles and synchronized high scores."
            )
        ]

        let model = StoreModel(
            apps: apps,
            installed: installed,
            sources: sources,
            changes: changes,
            account: account,
            activeLimit: 3,
            favorites: ["de.spanani.fmhy"],
            autoRefreshEnabled: true,
            remindersEnabled: true,
            actions: nil
        )

        return model
    }
}
