import FabrixDesign
import SwiftUI
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

extension View {
    /// Swaps the content for the lock screen while locked and covers every window while inactive.
    /// Modifiers outside this one (polling, committing decisions) keep running while locked.
    func appLock(_ lock: AppLock) -> some View {
        modifier(AppLockGate(lock: lock))
    }
}

/// The lock is app-wide, so it follows app activation rather than each scene's phase:
/// closing one iPad window must not cover another.
private struct AppLockGate: ViewModifier {
    let lock: AppLock

    func body(content: Content) -> some View {
        ZStack {
            if lock.isLocked {
                LockScreen()
            } else {
                content.accessibilityHidden(lock.isCovered)
            }
        }
        .environment(lock)
        #if os(macOS)
            // The window toolbar sits outside the content view and shows the company name.
            .toolbar(lock.isCovered ? .hidden : .automatic, for: .windowToolbar)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                lock.sceneWillResignActive()
                lock.sceneDidEnterBackground(at: .now)
                WindowShield.update(covered: lock.isCovered)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                lock.sceneDidBecomeActive(at: .now)
                WindowShield.update(covered: lock.isCovered)
                Task { await lock.promptIfNeeded() }
            }
        #else
            .background { ShieldWindowHost(lock: lock, covered: lock.isCovered) }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                lock.sceneWillResignActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                lock.sceneDidEnterBackground(at: .now)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                lock.sceneDidBecomeActive(at: .now)
                Task { await lock.promptIfNeeded() }
            }
        #endif
    }
}

#if os(macOS)
    /// Covers every app window, including sheets and Settings, which sit outside the SwiftUI tree.
    @MainActor
    enum WindowShield {
        private static let identifier = NSUserInterfaceItemIdentifier("fabrix.shield")

        static func update(covered: Bool) {
            for window in NSApp.windows {
                // The frame view, not the hosting view: SwiftUI owns the content view's subviews.
                guard let frameView = window.contentView?.superview else { continue }
                let shield = frameView.subviews.first { $0.identifier == identifier }
                if covered, shield == nil {
                    let cover = NSHostingView(rootView: BrandCover())
                    cover.identifier = identifier
                    cover.frame = frameView.bounds
                    cover.autoresizingMask = [.width, .height]
                    frameView.addSubview(cover, positioned: .above, relativeTo: nil)
                } else if !covered {
                    shield?.removeFromSuperview()
                }
            }
        }
    }
#else
    /// Puts the cover in a window above this scene's sheets and alerts, so app-switcher
    /// snapshots never show factory data.
    private struct ShieldWindowHost: UIViewRepresentable {
        let lock: AppLock
        let covered: Bool

        func makeUIView(context: Context) -> SceneProbe {
            SceneProbe(lock: lock)
        }

        func updateUIView(_ probe: SceneProbe, context: Context) {
            probe.setCovered(covered)
        }
    }

    final class SceneProbe: UIView {
        private let lock: AppLock
        private var shield: UIWindow?

        init(lock: AppLock) {
            self.lock = lock
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard shield == nil, let scene = window?.windowScene else { return }
            let shield = UIWindow(windowScene: scene)
            shield.windowLevel = .alert + 1
            shield.rootViewController = UIHostingController(rootView: BrandCover())
            shield.isHidden = true
            self.shield = shield
            // SwiftUI updates on the next pass; show the cover before the system takes its snapshot.
            NotificationCenter.default.addObserver(
                self, selector: #selector(sceneWillDeactivate), name: UIScene.willDeactivateNotification, object: scene
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(sceneDidActivate), name: UIScene.didActivateNotification, object: scene
            )
        }

        @objc private func sceneWillDeactivate() {
            if lock.shieldsScene(isActive: false) { setCovered(true) }
        }

        @objc private func sceneDidActivate() {
            setCovered(lock.shieldsScene(isActive: true))
        }

        func setCovered(_ covered: Bool) {
            shield?.isHidden = !covered
        }
    }
#endif

private struct LockScreen: View {
    @Environment(AppLock.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        BrandCover {
            Text("Fabrix is locked", bundle: .module)
                .font(.fabrix(.body))
                .foregroundStyle(Palette.steel)
                .accessibilityAddTraits(.isHeader)
            Button {
                Task { await lock.unlock() }
            } label: {
                Label(.features("Unlock"), systemImage: lock.biometry.systemImage)
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
            Text("Fabrix will ask for \(lock.factorName) when you open it, so nobody else can approve or pause your agents. You can change this in Settings.", bundle: .module)
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
                    Text("Turn On", bundle: .module).frame(maxWidth: .infinity)
                }
                .buttonStyle(.fabrixPrimary)
                .disabled(lock.isAuthenticating)
                Button {
                    dismiss()
                } label: {
                    Text("Not Now", bundle: .module).frame(maxWidth: .infinity)
                }
                .buttonStyle(.fabrixSecondary)
            }
            .controlSize(.large)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 420)
        .presentationDetents([.medium])
        .onAppear { lock.markOffered() }
    }

    private var title: String {
        if let name = lock.biometry.name {
            String(localized: "Lock Fabrix with \(name)?", bundle: .module)
        } else {
            String(localized: "Lock Fabrix with your \(AppLock.secretName)?", bundle: .module)
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
