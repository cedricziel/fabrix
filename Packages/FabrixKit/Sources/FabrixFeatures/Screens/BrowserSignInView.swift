import AuthenticationServices
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
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let failure = state.failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(Palette.halt)
                HStack {
                    Button(.features("Try again")) { Task { await model.retryBrowserSignIn() } }.buttonStyle(.fabrixPrimary)
                    Button(.features("Back")) { model.cancelBrowserSignIn() }
                }
            } else {
                HStack(spacing: Spacing.s) {
                    ProgressView().controlSize(.small)
                    Text("Approve Fabrix in your browser", bundle: .module).font(.headline)
                }
                Text("Approve the request from \(StoreConnector.clientName) on Paperclip's page, and Fabrix connects on its own. Signed in somewhere else? Copy the link and open it there.", bundle: .module)
                    .foregroundStyle(Palette.steel)
                if let expiresAt = state.expiresAt {
                    Text("The request expires at \(expiresAt, format: .dateTime.hour().minute()).", bundle: .module)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
                if let url = state.approvalURL {
                    HStack {
                        Button(copied ? "Copied" : "Copy link") {
                            Self.copy(url)
                            copied = true
                        }
                        Spacer()
                        Button(.features("Cancel"), role: .cancel) { model.cancelBrowserSignIn() }
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

    var body: some View {
        if let message {
            NoticeBanner(systemImage: "key.fill", tint: Palette.signal, message: message) {
                Button(.features("Sign in again")) { Task { await model.signInAgain() } }
                    .buttonStyle(.fabrixPrimary)
                    .disabled(model.browserSignIn != nil)
            }
        }
    }

    private var message: String? {
        if let reason = model.signedOutReason {
            return reason.message(for: nil)
        }
        if let expiry = model.keyExpiry {
            return String(localized: "Fabrix's key for this factory expires \(expiry.formatted(.relative(presentation: .named))).", bundle: .module)
        }
        return nil
    }
}

extension SignedOutReason {
    /// Says what ended: the Paperclip key, or the single sign-on session in front of it.
    func message(for factoryName: String?) -> String {
        let factory = factoryName ?? String(localized: "This factory", bundle: .module)
        return switch self {
        case .boardKeyRejected: String(localized: "\(factory) no longer accepts Fabrix's key.", bundle: .module)
        case .identityProviderSessionEnded: String(localized: "Your single sign-on session for \(factory) ended.", bundle: .module)
        }
    }
}
