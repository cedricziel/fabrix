import FabrixDesign
import SwiftUI

/// App settings. The Mac shows it in the Settings scene; iPhone and iPad in a sheet.
public struct SettingsView: View {
    @Bindable private var lock: AppLock

    public init(lock: AppLock = .shared) {
        self.lock = lock
    }

    public var body: some View {
        if lock.isLocked {
            // The Mac Settings window sits outside the locked main window.
            BrandCover { Text("Unlock Fabrix to change settings.").foregroundStyle(Palette.steel) }
                .frame(minWidth: 460, minHeight: 240)
        } else {
            form
        }
    }

    private var form: some View {
        Form {
            Section {
                Toggle("Lock Fabrix", isOn: isEnabled)
                    .disabled(!lock.canAuthenticate && !lock.settings.isEnabled)
                if lock.settings.isEnabled {
                    Picker("Unlock with", selection: $lock.method) {
                        ForEach(lock.unlockOptions) { Text(lock.label(for: $0)).tag($0) }
                    }
                    Picker("Lock", selection: $lock.timeout) {
                        ForEach(LockTimeout.allCases) { Text($0.title).tag($0) }
                    }
                }
                Toggle("Confirm approvals with \(lock.factorName)", isOn: confirmsApprovals)
                    .disabled(!lock.canAuthenticate)
            } header: {
                Text("Security")
            } footer: {
                Text(footer)
            }
        }
        .formStyle(.grouped)
        .disabled(lock.isAuthenticating)
        .navigationTitle("Settings")
        #if os(macOS)
            .frame(width: 460)
            .fixedSize(horizontal: false, vertical: true)
        #endif
    }

    private var footer: String {
        guard lock.canAuthenticate else {
            return String(localized: "Set a \(AppLock.secretName) on this device to use the lock.")
        }
        return String(localized: "Fabrix also hides its content in the app switcher while the lock is on. Background refreshes and decisions you already made keep going while it's locked.")
    }

    /// Turning the lock on or off asks for authentication; the toggle follows the result.
    private var isEnabled: Binding<Bool> {
        Binding { lock.settings.isEnabled } set: { enabled in
            Task { await lock.setEnabled(enabled) }
        }
    }

    private var confirmsApprovals: Binding<Bool> {
        Binding { lock.confirmsApprovals } set: { confirms in
            Task { await lock.setConfirmsApprovals(confirms) }
        }
    }
}

/// iPhone and iPad.
struct SettingsSheet: View {
    @Environment(AppLock.self) private var lock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsView(lock: lock)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Opens Settings on iPhone and iPad.
struct SettingsButton: View {
    @Environment(Navigator.self) private var navigator

    var body: some View {
        Button {
            navigator.showingSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}

extension LockTimeout {
    var title: LocalizedStringKey {
        switch self {
        case .immediately: "Immediately"
        case .oneMinute: "After 1 minute"
        case .fiveMinutes: "After 5 minutes"
        case .fifteenMinutes: "After 15 minutes"
        }
    }
}

#Preview { NavigationStack { SettingsView() } }
