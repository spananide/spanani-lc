//
//  SpananiRootView.swift
//  LiveContainer
//

import SwiftUI

struct SpananiRootView: View {
    @EnvironmentObject var sharedModel: SharedModel

    var body: some View {
        ZStack {
            LCTabView()
                .opacity(0)
                .allowsHitTesting(false)
                .accessibility(hidden: true)

            SpananiRoot(model: SpananiLCBridge.shared.model)
        }
        .task {
            if let msg = SpananiEngine.importInstallerCertificateIfPending() {
                SpananiAlert.shared.message = msg
            }
            SpananiEngine.updateExpiryReminder()
        }
        .onReceive(SpananiAlert.shared.$message.compactMap { $0 }) { msg in
            SpananiLCBridge.shared.model.lastError = msg
            SpananiAlert.shared.message = nil
        }
    }
}
