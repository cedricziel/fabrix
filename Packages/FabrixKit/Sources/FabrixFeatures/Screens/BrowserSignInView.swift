import FabrixDesign
import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

/// Waiting for the user to approve Fabrix on Paperclip's page in their own browser, or why that ended.
struct BrowserSignInView: View {
    let state: BrowserSignInState
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let failure = state.failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(Palette.halt)
                HStack {
                    Button("Try again") { Task { await model.retryBrowserSignIn() } }.buttonStyle(.fabrixPrimary)
                    Button("Back") { model.cancelBrowserSignIn() }
                }
            } else {
                HStack(spacing: Spacing.s) {
                    ProgressView().controlSize(.small)
                    Text("Approve Fabrix in your browser").font(.headline)
                }
                Text("Paperclip's approval page is open in your browser. Approve the request from \(StoreConnector.clientName) there, and Fabrix connects on its own.")
                    .foregroundStyle(Palette.steel)
                if let expiresAt = state.expiresAt {
                    Text("The request expires at \(expiresAt, format: .dateTime.hour().minute()).")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
                if let url = state.approvalURL {
                    HStack {
                        Button("Open again") { openURL(url) }
                        Button(copied ? "Copied" : "Copy link") {
                            Self.copy(url)
                            copied = true
                        }
                        Spacer()
                        Button("Cancel", role: .cancel) { model.cancelBrowserSignIn() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func copy(_ url: URL) {
        #if os(iOS)
            UIPasteboard.general.url = url
        #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #endif
    }
}

/// Offers browser sign-in when the factory rejected its key or the key expires soon.
struct SignInBanner: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let message {
            NoticeBanner(systemImage: "key.fill", tint: Palette.signal, message: message) {
                Button("Sign in again") { Task { await model.signInAgain(openURL: { openURL($0) }) } }
                    .buttonStyle(.fabrixPrimary)
                    .disabled(model.browserSignIn != nil)
            }
        }
    }

    private var message: String? {
        if model.needsSignIn {
            return String(localized: "This factory no longer accepts Fabrix's key.")
        }
        if let expiry = model.keyExpiry {
            return String(localized: "Fabrix's key for this factory expires \(expiry.formatted(.relative(presentation: .named))).")
        }
        return nil
    }
}
