import FabrixCore
import FabrixDesign
import SwiftUI

public struct RootView: View {
    @State private var model: AppModel

    public init(model: AppModel = AppModel()) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        Group {
            switch model.loadState {
            case .loading:
                ProgressView()
            case .loaded:
                if let snapshot = model.snapshot { PlaceholderOverview(snapshot: snapshot) }
            case .empty:
                ContentUnavailableView("No companies yet", systemImage: "building.2", description: Text("This factory has no companies."))
            case .failed(let message):
                ContentUnavailableView {
                    Label("Can't reach the factory", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { Task { await model.refresh() } }
                }
            }
        }
        .task { await model.refresh() }
        .environment(model)
    }
}

private struct PlaceholderOverview: View {
    let snapshot: CompanySnapshot

    var body: some View {
        NavigationStack {
            List {
                Section("Needs your decision") {
                    ForEach(snapshot.pendingApprovals) { Text($0.title) }
                }
                Section("Live runs") {
                    ForEach(snapshot.liveRuns) { Text($0.title) }
                }
            }
            .navigationTitle(snapshot.company.name)
        }
        .tint(Palette.signal)
    }
}

#Preview { RootView() }
