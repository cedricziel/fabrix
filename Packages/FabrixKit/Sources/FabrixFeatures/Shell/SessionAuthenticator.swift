import AuthenticationServices
import FabrixCore
import SwiftUI

/// Shows an identity provider's login page with SwiftUI's web authentication session.
struct SessionAuthenticator: WebAuthenticator {
    let session: WebAuthenticationSession

    func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await session.authenticate(using: url, callbackURLScheme: callbackScheme, preferredBrowserSession: .ephemeral)
    }
}
