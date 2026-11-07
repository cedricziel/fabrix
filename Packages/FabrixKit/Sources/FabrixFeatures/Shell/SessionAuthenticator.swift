import AuthenticationServices
import FabrixCore
import SwiftUI

/// Shows an identity provider's login page, or Paperclip's approval page, with SwiftUI's web
/// authentication session. The shared browser session carries over logins the user already
/// has, so they don't sign in to their identity provider or Paperclip again.
struct SessionAuthenticator: WebAuthenticator {
    let session: WebAuthenticationSession

    func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await session.authenticate(using: url, callbackURLScheme: callbackScheme, preferredBrowserSession: .shared)
    }
}
