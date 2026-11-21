//
//  SpananiRootView.swift
//  LiveContainer
//

import SwiftUI

enum SpananiColors {
    static let background = Color(red: 0.05, green: 0.04, blue: 0.09)
    static let card = Color(red: 0.11, green: 0.09, blue: 0.18)
    static let accent = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let text = Color.white
    static let secondaryText = Color.white.opacity(0.6)
}

struct SpananiRootView: View {
    @EnvironmentObject var sharedModel: SharedModel
    @ObservedObject var alert = SpananiAlert.shared

    var body: some View {
        ZStack {
            LCTabView()
                .opacity(0)
                .allowsHitTesting(false)
                .accessibility(hidden: true)

            SpananiHomeView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("spanani Store", isPresented: Binding<Bool>(
            get: { alert.message != nil },
            set: { if !$0 { alert.message = nil } }
        )) {
            Button("OK", role: .cancel) {
                alert.message = nil
            }
        } message: {
            Text(alert.message ?? "")
        }
        .preferredColorScheme(.dark)
    }
}

struct SpananiHomeView: View {
    @EnvironmentObject var sharedModel: SharedModel
    @State private var showingInstallSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                SpananiColors.background
                    .ignoresSafeArea()

                if sharedModel.apps.isEmpty {
                    Text("No apps yet. Tap + to install an IPA.")
                        .foregroundColor(SpananiColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sharedModel.apps, id: \.self) { app in
                                SpananiAppRow(app: app)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingInstallSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(SpananiColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingInstallSheet) {
                SpananiInstallSheet()
            }
        }
        .navigationViewStyle(.stack)
        .background(SpananiColors.background.ignoresSafeArea())
    }
}

struct SpananiAppRow: View {
    @ObservedObject var app: LCAppModel

    var body: some View {
        HStack(spacing: 12) {
            if let icon = SpananiEngine.icon(for: app) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SpananiColors.card.opacity(0.8))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundColor(SpananiColors.secondaryText)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(app.appInfo.displayName() ?? app.displayName)
                    .font(.headline)
                    .foregroundColor(SpananiColors.text)
                    .lineLimit(1)

                Text(app.appInfo.version() ?? app.version)
                    .font(.subheadline)
                    .foregroundColor(SpananiColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                SpananiEngine.launch(app)
            } label: {
                HStack {
                    if app.isSigningInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if app.isAppRunning {
                        Text("Opening…")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("Open")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(SpananiColors.accent)
                .clipShape(Capsule())
            }
            .disabled(app.isAppRunning || app.isSigningInProgress)
        }
        .padding()
        .background(SpananiColors.card)
        .cornerRadius(14)
        .contextMenu {
            Button(role: .destructive) {
                SpananiEngine.remove(app, deleteData: true)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SpananiInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = ""

    var body: some View {
        NavigationView {
            ZStack {
                SpananiColors.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("https://…/app.ipa", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(SpananiColors.card)
                        .foregroundColor(SpananiColors.text)
                        .cornerRadius(10)

                    Button {
                        let toInstall = urlString
                        dismiss()
                        SpananiEngine.install(urlString: toInstall)
                    } label: {
                        Text("Install")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SpananiColors.accent)
                            .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Install IPA from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(SpananiColors.accent)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}
