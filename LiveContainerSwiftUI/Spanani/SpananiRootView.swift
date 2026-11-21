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
        .onReceive(SpananiAlert.shared.$message.compactMap { $0 }) { msg in
            SpananiLCBridge.shared.model.lastError = msg
            SpananiAlert.shared.message = nil
        }
    }
}
