import FabrixDesign
import SwiftUI

public struct RootView: View {
    @State private var model: AppModel
    @State private var navigator = Navigator()
    @Environment(\.scenePhase) private var scenePhase
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init(model: AppModel = AppModel()) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        Group {
            if model.isOnboarding {
                OnboardingView()
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
                    .safeAreaInset(edge: .top) { ErrorBanner() }
                case .empty:
                    ContentUnavailableView {
                        Label("No companies yet", systemImage: "building.2")
                    } description: {
                        Text("This factory has no companies.")
                    } actions: {
                        Button("Choose another factory") { model.disconnect() }
                    }
                case let .failed(message):
                    ContentUnavailableView {
                        Label("Can't reach the factory", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try again") { Task { await model.refresh() } }
                            .buttonStyle(.fabrixPrimary)
                        Button("Choose another factory") { model.disconnect() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
        .environment(model)
        .environment(navigator)
        .environment(\.isCompact, isCompact)
        .onChange(of: isCompact, initial: true) { navigator.isCompact = isCompact }
        .tint(Palette.signal)
        .sheet(isPresented: $navigator.showingNewTask) { NewTaskSheet() }
        .task(id: Polling(factoryID: model.factory?.id, isActive: scenePhase == .active)) {
            guard model.factory != nil, scenePhase == .active else { return }
            await model.keepFresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                Task { await model.commitStagedDecisions() }
            }
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
            sizeClass == .compact
        #else
            false
        #endif
    }
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
            .task { await model.refresh() }
    }
}

#Preview("Demo") { RootView(model: .demo()) }
