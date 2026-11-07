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
            if let snapshot = model.snapshot {
                PlaceholderOverview(snapshot: snapshot)
            } else {
                ProgressView()
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
