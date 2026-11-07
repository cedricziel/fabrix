import FabrixCore
import FabrixDesign
import SwiftUI

public struct RootView: View {
    @State private var model: AppModel
    @State private var navigator = Navigator()
    @State private var shutdownTask: UUID?
    @State private var offeringLock = false
    @State private var lockOfferIsDue = false
    private let lock: AppLock
    @Environment(\.scenePhase) private var scenePhase
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init(model: AppModel = AppModel(), lock: AppLock = .shared) {
        _model = State(initialValue: model)
        self.lock = lock
    }

    /// Connects and reopens factories through `factoryStore`. Pass the app's single store so
    /// other parts of the app (telemetry scrubbing) see factories as soon as they are added.
    public init(factoryStore: FactoryStore) {
        _model = State(initialValue: AppModel(connector: StoreConnector(store: factoryStore)))
        lock = .shared
    }

    public var body: some View {
        Group {
            if model.isOnboarding {
                OnboardingView()
            } else if model.needsSignIn, model.loadState != .loaded {
                ContentUnavailableView {
                    Label(.features("Sign in again"), systemImage: "key")
                } description: {
                    Text("\(model.factory?.name ?? "This factory") no longer accepts Fabrix's key.")
                } actions: {
                    SignInBanner()
                    Button(.features("Choose another factory")) { model.disconnect() }
                }
            } else {
                switch model.loadState {
                case .loading:
                    ProgressView()
                case .loaded:
                    Group {
                        if isCompact {
                            CompactShell()
                        } else {
                            SplitShell()
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        VStack(spacing: 0) {
                            SignInBanner()
                            ErrorBanner()
                        }
                    }
                    .modifier(ErrorAnnouncer())
                case .empty:
                    // The title menu stays reachable so another factory can be opened or this one removed.
                    NavigationStack {
                        ContentUnavailableView {
                            Label(.features("No companies yet"), systemImage: "building.2")
                        } description: {
                            Text("This factory has no companies.", bundle: .module)
                        } actions: {
                            Button(.features("Choose another factory")) { model.disconnect() }
                        }
                        .factoryTitle()
                    }
                case let .failed(message):
                    NavigationStack {
                        ContentUnavailableView {
                            Label(.features("Can't reach the factory"), systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(message)
                        } actions: {
                            Button(.features("Try again")) { Task { await model.refresh() } }
                                .buttonStyle(.fabrixPrimary)
                            Button(.features("Choose another factory")) { model.disconnect() }
                        }
                        .factoryTitle()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
        .onChange(of: isCompact, initial: true) { navigator.isCompact = isCompact }
        .tint(Palette.signal)
        // Inside the lock, so sheets close when it locks.
        .sheet(isPresented: $navigator.showingNewTask, onDismiss: presentDueLockOffer) { NewTaskSheet() }
        .sheet(isPresented: $navigator.showingAddFactory, onDismiss: presentDueLockOffer) { AddFactorySheet() }
        .sheet(isPresented: $navigator.showingSettings, onDismiss: presentDueLockOffer) { SettingsSheet() }
        .sheet(isPresented: $offeringLock) { LockOfferSheet() }
        .focusedSceneValue(\.appModel, model)
        .focusedSceneValue(\.navigator, navigator)
        .sheet(isPresented: signingInAgain, onDismiss: presentDueLockOffer) {
            if let signIn = model.browserSignIn {
                BrowserSignInView(state: signIn)
                    .padding(Spacing.xl)
                    .frame(minWidth: 360)
                    .environment(model)
            }
        }
        .confirmationDialog(
            Text("Remove \(model.factory?.name ?? String(localized: "this factory", bundle: .module))?", bundle: .module),
            isPresented: $navigator.confirmingRemove, titleVisibility: .visible
        ) {
            Button(.features("Remove Factory"), role: .destructive) { Task { await model.removeOpenFactory() } }
        } message: {
            Text("Fabrix deletes the saved address and credentials from this device. Your factory and its agents are not affected.", bundle: .module)
        }
        .appLock(lock)
        .onChange(of: model.connectCount) {
            lockOfferIsDue = lock.shouldOfferLock
            if !navigator.isPresentingSheet, !signingInAgain.wrappedValue { presentDueLockOffer() }
        }
        .task(id: Polling(factoryID: model.factory?.id, isActive: ScenePolicy.keepsPolling(scenePhase))) {
            guard model.factory != nil, ScenePolicy.keepsPolling(scenePhase) else { return }
            await model.keepFresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if ScenePolicy.commitsDecisions(phase) {
                ShutdownTasks.runInBackground { [model] in await model.commitStagedDecisions() }
            }
        }
        .onAppear {
            shutdownTask = ShutdownTasks.register { [model] in await model.commitStagedDecisions() }
        }
        .onDisappear {
            shutdownTask.map(ShutdownTasks.unregister)
        }
        .onChange(of: SwitchContext(factoryID: model.factory?.id, companyID: model.snapshot?.company.id)) {
            navigator.resetPaths()
        }
        .onChange(of: model.supportsProjects) { _, supported in
            if !supported { navigator.leaveProjects() }
        }
        .onChange(of: model.storeRevision) {
            Task { await model.followStoreChanges() }
        }
        // Last, so sheets, dialogs and popovers presented above inherit the same environment.
        .environment(model)
        .environment(navigator)
        .environment(\.isCompact, isCompact)
    }

    /// Re-sign-in for a saved factory; onboarding shows its own sign-in inline.
    private var signingInAgain: Binding<Bool> {
        Binding {
            !model.isOnboarding && model.browserSignIn != nil
        } set: { shown in
            if !shown { model.cancelBrowserSignIn() }
        }
    }

    private func presentDueLockOffer() {
        guard lockOfferIsDue else { return }
        lockOfferIsDue = false
        offeringLock = lock.shouldOfferLock
    }

    private var isCompact: Bool {
        #if os(iOS)
            sizeClass == .compact
        #else
            false
        #endif
    }
}

/// Inactive is brief (Control Center, an incoming call, the app switcher), so polling and
/// undo windows keep running until the app actually reaches the background.
enum ScenePolicy {
    static func keepsPolling(_ phase: ScenePhase) -> Bool {
        phase != .background
    }

    static func commitsDecisions(_ phase: ScenePhase) -> Bool {
        phase == .background
    }
}

private struct SwitchContext: Equatable {
    var factoryID: String?
    var companyID: String?
}

private struct Polling: Equatable {
    var factoryID: String?
    var isActive: Bool
}

extension EnvironmentValues {
    /// True for the iPhone tab layout.
    @Entry var isCompact = false
}

/// Loads the demo factory for SwiftUI previews of a single screen.
struct PreviewHost<Content: View>: View {
    @State private var model = AppModel.demo()
    @State private var navigator = Navigator()
    @ViewBuilder var content: Content

    var body: some View {
        content
            .environment(model)
            .environment(navigator)
            .environment(AppLock(defaults: UserDefaults(suiteName: "fabrix.preview") ?? .standard))
            .task { await model.refresh() }
    }
}

#Preview("Demo") { RootView(model: .demo()) }
