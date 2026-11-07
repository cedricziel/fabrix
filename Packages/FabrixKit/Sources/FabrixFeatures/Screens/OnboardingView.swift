import AuthenticationServices
import FabrixDesign
import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fabrix", bundle: .module)
                        .font(.system(size: 34, weight: .bold))
                    Text("A control room for your Paperclip factories. Agents report, you decide.", bundle: .module)
                        .font(.title3)
                        .foregroundStyle(Palette.steel)
                }

                ConnectFactoryForm()

                VStack(alignment: .leading, spacing: 10) {
                    Text("No factory yet?", bundle: .module).font(.headline)
                    Text("Walk through a sample company with seven agents, live runs and approvals waiting on you.", bundle: .module)
                        .foregroundStyle(Palette.steel)
                    Button { Task { await model.exploreDemo() } } label: {
                            Text("Explore the demo", bundle: .module).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.fabrixSignal)
                }
                .padding(20)
                .fabrixCard()
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
        .background(Palette.paper)
    }
}

/// Address, sign-in method, credentials and custom headers for a factory.
/// Used by onboarding and by Add Factory.
struct ConnectFactoryForm: View {
    @Environment(AppModel.self) private var model
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var form = ConnectForm()
    @State private var connecting: Task<Void, Never>?
    var onConnected: () -> Void = {}

    private static let addressExample = "https://factory.example.com"
    private static let issuerExample = "https://auth.example.com"
    private static let clientIDExample = "fabrix"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect a factory", bundle: .module).font(.headline)
            if let reconnect = model.reconnect {
                Label(reconnect.reason, systemImage: "key.fill")
                    .font(.callout)
                    .foregroundStyle(Palette.steel)
            }
            Group {
                LabeledField(.features("Factory address")) {
                    TextField(Self.addressExample, text: $form.address)
                        .urlEntry()
                }
                Picker(.features("Sign in with"), selection: $form.method) {
                    ForEach(ConnectForm.Method.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                if form.method.usesOIDC {
                    LabeledField(.features("OIDC issuer")) {
                        TextField(Self.issuerExample, text: $form.issuer).urlEntry()
                    }
                    LabeledField(.features("Client ID")) {
                        TextField(Self.clientIDExample, text: $form.clientID).autocorrectionDisabled()
                    }
                }
                if form.method.usesAPIKey {
                    LabeledField(.features("Paperclip API key")) {
                        SecureField(.features("Paste the key from your Paperclip board"), text: $form.apiKey)
                            .textContentType(.password)
                    }
                }
                Text("Create one with `paperclipai token board create` on a signed-in machine.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .textSelection(.enabled)
            }
            .disabled(model.isConnecting)
            AdvancedSection(headers: $form.headers)
                .disabled(model.isConnecting)
            if let error = model.connectError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(Palette.halt)
            }
            if let signIn = model.browserSignIn {
                BrowserSignInView(state: signIn)
            } else {
                Button {
                    connect()
                } label: {
                    Group {
                        if model.isConnecting { ProgressView().controlSize(.small) } else { Text("Connect", bundle: .module) }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.fabrixPrimary)
                .disabled(!model.canConnect || form.address.isEmpty || model.isConnecting)
            }
            if model.isConnecting, model.browserSignIn == nil {
                Button(.features("Cancel")) { connecting?.cancel() }
                    .buttonStyle(.fabrixSecondary)
                    .frame(maxWidth: .infinity)
            }
            if !model.canConnect {
                Text("Connecting to your own factory arrives in an upcoming build. Explore the demo in the meantime.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
        .padding(20)
        .fabrixCard()
        .onSubmit(connect)
        .onAppear {
            if let reconnect = model.reconnect, form.address.isEmpty {
                form = ConnectForm(reconnecting: reconnect)
            }
        }
        .onChange(of: form) { model.clearConnectError() }
        .onChange(of: model.connectError) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
    }

    private func connect() {
        guard model.canConnect, !form.address.isEmpty, !model.isConnecting else { return }
        let authenticator = SessionAuthenticator(session: webAuthenticationSession)
        connecting = Task {
            if await model.connect(form, webAuthenticator: authenticator) { onConnected() }
        }
    }
}

/// "Add Factory…" from the title menu, with the current factory still open behind it.
struct AddFactorySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ConnectFactoryForm { dismiss() }
                    .padding(20)
                    .onDisappear { model.forgetReconnect() }
            }
            .background(Palette.paper)
            .navigationTitle(.features("Add Factory"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.features("Cancel")) { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 420)
        #else
        .presentationSizing(.form)
        #endif
        .onAppear { model.clearConnectError() }
    }
}

private extension ConnectForm.Method {
    var title: LocalizedStringResource {
        switch self {
        case .browser: "Sign in with browser"
        case .paperclip: "Paperclip API key"
        case .oidcWithBrowser: "Single sign-on + browser sign-in"
        case .oidcWithPaperclip: "Single sign-on + Paperclip key"
        case .oidc: "Single sign-on (OIDC)"
        }
    }
}

private extension View {
    /// Text typed as-is: no autocorrection or capitalization.
    func plainEntry() -> some View {
        autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
    }

    func urlEntry() -> some View {
        textContentType(.URL)
            .plainEntry()
            #if os(iOS)
            .keyboardType(.URL)
            #endif
    }
}

/// Custom request headers, collapsed unless the form already has some.
private struct AdvancedSection: View {
    @Binding var headers: [ConnectForm.HeaderRow]
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(.features("Advanced"), isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                FieldTitle(.features("Custom headers"))
                ForEach($headers) { $row in
                    HStack(spacing: Spacing.s) {
                        TextField(.features("Header name"), text: $row.name)
                            .plainEntry()
                            .textFieldStyle(.fabrix)
                        SecureField(.features("Value"), text: $row.value)
                            .textFieldStyle(.fabrix)
                        Button {
                            headers.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(Palette.halt)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(.features("Remove header"))
                    }
                }
                Button {
                    headers.append(ConnectForm.HeaderRow())
                } label: {
                    Label(.features("Add header"), systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.signal)
                Text("Sent with every request to this factory, e.g. a proxy access token.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .padding(.top, Spacing.s)
        }
        // Saved headers (or a reconnect that needs their values) should be visible, not hidden away.
        .onChange(of: headers.isEmpty, initial: true) { _, isEmpty in
            if !isEmpty { isExpanded = true }
        }
    }
}

#Preview { OnboardingView().environment(AppModel(defaults: UserDefaults(suiteName: "preview.onboarding")!)) }

#Preview("Add Factory") {
    AddFactorySheet()
        .environment(AppModel.demo())
        .environment(Navigator())
}
