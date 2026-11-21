import SwiftUI

struct MyAppsView: View {
    @EnvironmentObject private var model: StoreModel
    var selectedApp: Binding<StoreItem?>? = nil
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var internalSelectedApp: StoreItem? = nil

    private var appsWithUpdates: [InstalledItem] {
        model.installed.filter { $0.hasUpdate }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if model.installed.isEmpty {
                    emptyStateView
                } else {
                    if !model.favoriteApps.isEmpty {
                        favoritesSection
                    }

                    if !appsWithUpdates.isEmpty {
                        updatesSection
                    }

                    installedSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .refreshable {
            await model.reloadSources()
        }
        .background(Color.paper)
        .sheet(item: $internalSelectedApp) { app in
            AppDetailView(app: app)
                .environmentObject(model)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Apps")
                    .font(.brand(34, .extrabold))
                    .foregroundColor(.ink)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Favourites", count: model.favoriteApps.count)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(model.favoriteApps) { app in
                        Button {
                            if let binding = selectedApp {
                                binding.wrappedValue = app
                            } else {
                                internalSelectedApp = app
                            }
                        } label: {
                            VStack(spacing: 8) {
                                SpAppIconView(
                                    tint: app.tint,
                                    symbol: app.symbol,
                                    iconURL: app.iconURL,
                                    size: 72
                                )

                                Text(app.name)
                                    .font(.brand(13, .semibold))
                                    .foregroundColor(.ink)
                                    .lineLimit(1)
                                    .frame(width: 76)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                model.toggleFavorite(app.id)
                            } label: {
                                Label("Remove from Favourites", systemImage: "star.slash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Updates", count: appsWithUpdates.count)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(appsWithUpdates) { item in
                    UpdateAppRowView(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Installed Section

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Installed", count: model.installed.count)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(model.installed) { item in
                    InstalledAppRowView(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 32)

            Mark3DTile(size: 120)

            Text("Nothing installed yet")
                .font(.brand(24, .extrabold))
                .foregroundColor(.ink)

            Text("Get an app from Discover and it shows up here.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                Haptics.impact(.medium)
                onNavigateToTab?(0)
            } label: {
                Text("Browse apps")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Update App Row View

private struct UpdateAppRowView: View {
    @EnvironmentObject private var model: StoreModel
    let item: InstalledItem

    private var storeApp: StoreItem? {
        model.apps.first { $0.id == item.id }
    }

    // The store itself is hidden from `model.apps`, so build the update target from the installed row.
    private var updateTarget: StoreItem {
        storeApp ?? StoreItem(
            id: item.id,
            name: item.name,
            subtitle: "",
            developer: "",
            description: "",
            category: "",
            versionString: item.latestVersion ?? item.versionString,
            sizeBytes: 0,
            sourceName: "",
            tint: item.tint,
            symbol: item.symbol,
            iconURL: item.iconURL
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SpAppIconView(
                    tint: item.tint,
                    symbol: item.symbol,
                    iconURL: item.iconURL,
                    image: item.iconImage,
                    size: 50
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.brand(16, .semibold))
                        .foregroundColor(.ink)

                    Text("\(item.versionString) → \(item.latestVersion ?? "New")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accent)
                }

                Spacer()

                InstallButton(
                    state: model.installStates[item.id] ?? .updateAvailable,
                    minHeight: 32,
                    fontSize: 14
                ) {
                    model.install(updateTarget)
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 64)
        }
    }
}

// MARK: - Installed App Row View

private struct InstalledAppRowView: View {
    @EnvironmentObject private var model: StoreModel
    let item: InstalledItem
    @State private var confirmDelete = false

    // The store cannot delete itself.
    private var canDelete: Bool { !item.id.hasPrefix("de.spanani.store") }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SpAppIconView(
                    tint: item.tint,
                    symbol: item.symbol,
                    iconURL: item.iconURL,
                    image: item.iconImage,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.brand(17, .semibold))
                        .foregroundColor(.ink)

                    Text("Version \(item.versionString)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.inkFaint)
                }

                Spacer()

                Button {
                    model.open(item)
                } label: {
                    Text("Open")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.brand)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 32)
                        .background(Color.brand.opacity(0.16))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.brand.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Menu {
                    Button {
                        model.open(item)
                    } label: {
                        Label("Open", systemImage: "arrow.up.forward.app")
                    }

                    if canDelete {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Actions for \(item.name)")
            }
            .padding(.vertical, 12)
            .contextMenu {
                Button {
                    model.open(item)
                } label: {
                    Label("Open", systemImage: "arrow.up.forward.app")
                }

                if canDelete {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 70)
        }
        .confirmationDialog(
            "Delete \(item.name)?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                model.delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The app and its data are removed from this iPhone.")
        }
    }
}
