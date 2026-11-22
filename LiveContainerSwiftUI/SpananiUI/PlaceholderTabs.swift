import SwiftUI

// MARK: - SourcesView

struct SourcesView: View {
    @EnvironmentObject private var model: StoreModel
    @State private var isAddSheetPresented = false
    @State private var sourceToRemove: SpSourceItem? = nil
    @State private var isConfirmRemovePresented = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if model.sources.isEmpty {
                    emptySourcesView
                } else {
                    sourcesListSection
                    addSourceButton
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(Color.paper)
        .sheet(isPresented: $isAddSheetPresented) {
            AddSourceSheet()
                .environmentObject(model)
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Remove source?",
            isPresented: $isConfirmRemovePresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let source = sourceToRemove {
                    model.removeSource(source)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sources")
                .font(.brand(34, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
    }

    private var emptySourcesView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 32)

            Mark3DTile(size: 96)

            Text("No sources")
                .font(.brand(22, .extrabold))
                .foregroundColor(.ink)

            Text("Add a source to see apps here.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                Haptics.impact(.medium)
                isAddSheetPresented = true
            } label: {
                Text("Add source")
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
        .padding(.vertical, 36)
    }

    private var sourcesListSection: some View {
        VStack(spacing: 12) {
            ForEach(model.sources) { source in
                sourceCard(source: source)
            }
        }
        .padding(.horizontal, 20)
    }

    private func sourceCard(source: SpSourceItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                source.tint
                Text(String(source.name.prefix(1)).uppercased())
                    .font(.brand(20, .extrabold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(source.name)
                    .font(.brand(17, .semibold))
                    .foregroundColor(.ink)

                Text(source.url)
                    .font(.system(size: 12))
                    .foregroundColor(.inkFaint)
                    .lineLimit(1)
            }

            Spacer()

            Text(source.appCount == 1 ? "1 app" : "\(source.appCount) apps")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.paperSunk)
                .clipShape(Capsule())

            Menu {
                Button(role: .destructive) {
                    sourceToRemove = source
                    isConfirmRemovePresented = true
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.inkSoft)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Actions for \(source.name)")
        }
        .padding(16)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
    }

    private var addSourceButton: some View {
        Button {
            Haptics.impact(.medium)
            isAddSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add source")
                    .font(.brand(16, .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.brand)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

// MARK: - AddSourceSheet

struct AddSourceSheet: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss

    @State private var urlString: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter the address of a compatible source.")
                    .font(.system(size: 14))
                    .foregroundColor(.inkSoft)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("https://example.com/source.json", text: $urlString)
                        .font(.system(size: 15))
                        .foregroundColor(.ink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.paperSunk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(errorMessage != nil ? Color.danger : Color.paperSunk, lineWidth: 1)
                        )

                    if let errorMessage = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.danger)
                        .padding(.horizontal, 4)
                    }
                }

                Spacer()

                Button {
                    addSource()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 6)
                        }
                        Text("Add")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(20)
            .background(Color.paper)
            .navigationTitle("Add source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brand)
                }
            }
        }
    }

    private func addSource() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await model.addSource(urlString)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @State private var refreshTick = 0
    @State private var isConfirmRemoveCertPresented = false
    @State private var isLCSettingsPresented = false
    @State private var isTweaksPresented = false

    var body: some View {
        let _ = refreshTick
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                signingSection
                    .id(refreshTick)
                renewalSection
                engineSection
                advancedSection
                aboutSection
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(Color.paper)
        .onAppear {
            refreshTick += 1
        }
        .confirmationDialog(
            "Remove the signing certificate?",
            isPresented: $isConfirmRemoveCertPresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                SpananiEngine.removeCertificate()
                refreshTick += 1
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isLCSettingsPresented) {
            LCSettingsView()
                .environmentObject(DataManager.shared.model)
                .environmentObject(LCAppSortManager.shared)
        }
        .sheet(isPresented: $isTweaksPresented) {
            LCTweaksView()
                .environmentObject(DataManager.shared.model)
                .environmentObject(LCAppSortManager.shared)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Settings")
                .font(.brand(34, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Signing Section

    private var signingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signing certificate")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Certificate")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    statusPill(
                        text: SpananiEngine.hasCertificate ? "Imported" : "Not imported",
                        color: SpananiEngine.hasCertificate ? .success : .warning
                    )
                }
                .padding(16)

                if let date = SpananiEngine.certificateDate {
                    Rectangle()
                        .fill(Color.paperSunk)
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    HStack {
                        Text("Updated")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.ink)

                        Spacer()

                        Text(shortDateString(from: date))
                            .font(.brand(14, .semibold))
                            .foregroundColor(.inkSoft)
                    }
                    .padding(16)
                }

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Apps run with your own signing certificate. Sign in once in the store engine, then import the certificate here.")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)

                    Button {
                        if let msg = SpananiEngine.importCertificateFromStoreEngine() {
                            SpananiAlert.shared.message = msg
                        }
                        refreshTick += 1
                    } label: {
                        Text("Import from store engine")
                            .font(.brand(15, .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.brand)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!SpananiEngine.storeEngineAvailable)
                    .opacity(SpananiEngine.storeEngineAvailable ? 1.0 : 0.45)
                }
                .padding(16)

                if SpananiEngine.hasCertificate {
                    Rectangle()
                        .fill(Color.paperSunk)
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    Button {
                        isConfirmRemoveCertPresented = true
                    } label: {
                        HStack {
                            Text("Remove certificate")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.danger)
                            Spacer()
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.danger)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Renewal Section

    private var renewalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Renewal")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("App expires")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    if let expiry = SpananiEngine.appExpiryDate {
                        Text(shortDateTimeString(from: expiry))
                            .font(.brand(14, .semibold))
                            .foregroundColor(.inkSoft)

                        expiryStatusPill(for: expiry)
                    } else {
                        Text("Unknown")
                            .font(.brand(14, .semibold))
                            .foregroundColor(.inkSoft)
                    }
                }
                .padding(16)

                if SpananiEngine.appExpiryDate != nil {
                    Rectangle()
                        .fill(Color.paperSunk)
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Remind me before it expires", isOn: Binding(
                            get: { SpananiEngine.expiryReminderEnabled },
                            set: {
                                UserDefaults.standard.set($0, forKey: SpananiEngine.expiryReminderKey)
                                SpananiEngine.updateExpiryReminder()
                                refreshTick += 1
                            }
                        ))
                        .tint(.brand)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                        Text("Free Apple ID apps expire after 7 days. Renew by running the installer on your PC again.")
                            .font(.system(size: 13))
                            .foregroundColor(.inkSoft)
                    }
                    .padding(16)
                }
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Store Engine Section

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Store engine")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("The built-in store signs you in with your Apple ID and keeps the certificate fresh. Use the back button in its top-left corner to return here.")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSoft)

                Button {
                    SpananiEngine.openStoreEngine()
                } label: {
                    Text("Open store engine")
                        .font(.brand(15, .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.brand)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!SpananiEngine.storeEngineAvailable)
                .opacity(SpananiEngine.storeEngineAvailable ? 1.0 : 0.45)
            }
            .padding(16)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Advanced")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                Button {
                    isLCSettingsPresented = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("LiveContainer settings")
                                .font(.brand(16, .semibold))
                                .foregroundColor(.ink)

                            Text("Containers, JIT-less diagnose, multitasking")
                                .font(.system(size: 13))
                                .foregroundColor(.inkSoft)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.inkFaint)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                Button {
                    isTweaksPresented = true
                } label: {
                    HStack {
                        Text("Tweaks")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.ink)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.inkFaint)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Mark3DTile(size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("spanani Store")
                            .font(.brand(20, .extrabold))
                            .foregroundColor(.ink)

                        let versionString = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
                        Text("Version \(versionString)")
                            .font(.system(size: 14))
                            .foregroundColor(.inkSoft)
                    }

                    Spacer()
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Text("License")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text("Open source (AGPL-3.0)")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.inkSoft)
                }
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private func shortDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func expiryStatusPill(for expiry: Date) -> some View {
        let isPast = expiry <= Date()
        let days = max(1, SpananiEngine.daysUntilExpiry() ?? 0)
        let text = isPast ? "expired" : (days == 1 ? "in 1 day" : "in \(days) days")
        let color: Color = isPast ? .danger : (days >= 3 ? .success : .warning)
        return statusPill(text: text, color: color)
    }

    private func shortDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.brand(12, .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}
