import FabrixDesign
import SwiftUI
#if os(macOS)
    import AppKit
#endif

extension View {
    /// Swaps the content for the lock screen while locked and covers it while inactive.
    /// Modifiers outside this one (polling, committing decisions) keep running while locked.
    func appLock(_ lock: AppLock) -> some View {
        modifier(AppLockGate(lock: lock))
    }
}

private struct AppLockGate: ViewModifier {
    let lock: AppLock
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        ZStack {
            if lock.isLocked {
                LockScreen()
            } else {
                content
                if lock.isCovered {
                    BrandCover().transition(.opacity)
                }
            }
        }
        .environment(lock)
        #if os(macOS)
            // A Mac window's scene phase doesn't follow app activation.
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                lock.sceneWillResignActive()
                lock.sceneDidEnterBackground(at: .now)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                lock.sceneDidBecomeActive(at: .now)
                Task { await lock.promptIfNeeded() }
            }
        #else
            .onChange(of: scenePhase, initial: true) { _, phase in
                switch phase {
                case .inactive: lock.sceneWillResignActive()
                case .background: lock.sceneDidEnterBackground(at: .now)
                case .active:
                    lock.sceneDidBecomeActive(at: .now)
                    Task { await lock.promptIfNeeded() }
                @unknown default: break
                }
            }
        #endif
    }
}

private struct LockScreen: View {
    @Environment(AppLock.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        BrandCover {
            Text("Fabrix is locked")
                .font(.fabrix(.body))
                .foregroundStyle(Palette.steel)
            Button {
                Task { await lock.unlock() }
            } label: {
                Label("Unlock", systemImage: lock.biometry.systemImage)
            }
            .buttonStyle(.fabrixPrimary)
            .controlSize(.large)
            .disabled(lock.isAuthenticating)
            .padding(.top, Spacing.s)
        }
        // Covers a cold launch, where no activation event follows the first appearance.
        .task(id: scenePhase) {
            if scenePhase == .active {
                await lock.promptIfNeeded()
            }
        }
    }
}

/// Shown once, after the first real factory connects.
struct LockOfferSheet: View {
    @Environment(AppLock.self) private var lock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: lock.biometry.systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Palette.signal)
            Text(title)
                .font(.fabrix(.title))
                .multilineTextAlignment(.center)
            Text("Fabrix will ask for \(lock.factorName) when you open it, so nobody else can approve or pause your agents. You can change this in Settings.")
                .font(.fabrix(.body))
                .foregroundStyle(Palette.steel)
                .multilineTextAlignment(.center)
            VStack(spacing: Spacing.s) {
                Button {
                    Task {
                        await lock.setEnabled(true)
                        dismiss()
                    }
                } label: {
                    Text("Turn On").frame(maxWidth: .infinity)
                }
                .buttonStyle(.fabrixPrimary)
                .disabled(lock.isAuthenticating)
                Button {
                    dismiss()
                } label: {
                    Text("Not Now").frame(maxWidth: .infinity)
                }
                .buttonStyle(.fabrixSecondary)
            }
            .controlSize(.large)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 420)
        .presentationDetents([.medium])
    }

    private var title: String {
        if let name = lock.biometry.name {
            String(localized: "Lock Fabrix with \(name)?")
        } else {
            String(localized: "Lock Fabrix with your \(AppLock.secretName)?")
        }
    }
}

extension Biometry {
    var systemImage: String {
        switch self {
        case .none: "lock.fill"
        case .touchID: "touchid"
        case .faceID: "faceid"
        case .opticID: "opticid"
        }
    }
}
