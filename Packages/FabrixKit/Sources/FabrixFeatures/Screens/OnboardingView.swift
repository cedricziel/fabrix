import AuthenticationServices
import FabrixDesign
import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var form = ConnectForm()
    @State private var showsAdvanced = false
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fabrix")
                        .font(.system(size: 34, weight: .bold))
                    Text("A control room for your Paperclip factories. Agents report, you decide.")
                        .font(.title3)
                        .foregroundStyle(Palette.steel)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Connect a factory").font(.headline)
                    LabeledField(title: "Factory address") {
                        TextField("https://factory.example.com", text: $form.address)
                            .urlEntry()
                    }
                    Picker("Sign in with", selection: $form.method) {
                        ForEach(ConnectForm.Method.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                    if form.method.usesOIDC {
                        LabeledField(title: "OIDC issuer") {
                            TextField("https://auth.example.com", text: $form.issuer).urlEntry()
                        }
                        LabeledField(title: "Client ID") {
                            TextField("fabrix", text: $form.clientID).autocorrectionDisabled()
                        }
                    }
                    if form.method.usesAPIKey {
                        LabeledField(title: "Paperclip API key") {
                            SecureField("Paste the key from your Paperclip board", text: $form.apiKey)
                                .textContentType(.password)
                        }
                    }
                    AdvancedSection(headers: $form.headers, isExpanded: $showsAdvanced)
                    if let error = model.connectError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(Palette.halt)
                    }
                    Button {
                        connect()
                    } label: {
                        Group {
                            if model.isConnecting { ProgressView().controlSize(.small) } else { Text("Connect") }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.fabrixPrimary)
                    .disabled(!model.canConnect || form.address.isEmpty || model.isConnecting)
                    if !model.canConnect {
                        Text("Connecting to your own factory arrives in an upcoming build. Explore the demo in the meantime.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }
                .padding(20)
                .cardSurface()

                VStack(alignment: .leading, spacing: 10) {
                    Text("No factory yet?").font(.headline)
                    Text("Walk through a sample company with seven agents, live runs and approvals waiting on you.")
                        .foregroundStyle(Palette.steel)
                    Button { Task { await model.exploreDemo() } } label: {
                            Text("Explore the demo").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.fabrixSignal)
                }
                .padding(20)
                .cardSurface()
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
        .background(Palette.paper)
        .onSubmit(connect)
    }

    private func connect() {
        guard model.canConnect else { return }
        let authenticator = SessionAuthenticator(session: webAuthenticationSession)
        Task { await model.connect(form, webAuthenticator: authenticator) }
    }
}

private extension ConnectForm.Method {
    var title: LocalizedStringKey {
        switch self {
        case .paperclip: "Paperclip API key"
        case .oidc: "Single sign-on (OIDC)"
        case .oidcWithPaperclip: "Single sign-on + Paperclip key"
        }
    }
}

private extension View {
    func fieldChrome() -> some View {
        textFieldStyle(.plain)
            .padding(10)
            .background(Palette.card, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.hairline))
    }

    func urlEntry() -> some View {
        textContentType(.URL)
            .autocorrectionDisabled()
            #if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            #endif
    }
}

private struct LabeledField<Field: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.medium)).foregroundStyle(Palette.steel)
            field.fieldChrome()
        }
    }
}

/// Custom request headers, collapsed until the user opens it or headers exist.
private struct AdvancedSection: View {
    @Binding var headers: [ConnectForm.HeaderRow]
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup("Advanced", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom headers").font(.caption.weight(.medium)).foregroundStyle(Palette.steel)
                ForEach($headers) { $row in
                    HStack(spacing: 8) {
                        TextField("Header name", text: $row.name)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .fieldChrome()
                        SecureField("Value", text: $row.value)
                            .fieldChrome()
                        Button {
                            headers.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(Palette.halt)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove header")
                    }
                }
                Button {
                    headers.append(ConnectForm.HeaderRow())
                } label: {
                    Label("Add header", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.signal)
                Text("Sent with every request to this factory, e.g. a proxy access token.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .padding(.top, 8)
        }
        .onAppear { isExpanded = isExpanded || !headers.isEmpty }
    }
}

#Preview { OnboardingView().environment(AppModel(defaults: UserDefaults(suiteName: "preview.onboarding")!)) }
