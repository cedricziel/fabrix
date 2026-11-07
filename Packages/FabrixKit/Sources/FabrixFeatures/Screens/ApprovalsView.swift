import FabrixCore
import FabrixDesign
import SwiftUI

struct ApprovalsView: View {
    enum Filter: Hashable { case waiting, decided }

    @Environment(AppModel.self) private var model
    @Environment(AppLock.self) private var lock
    @State private var filter = Filter.waiting

    var body: some View {
        let waiting = model.waitingApprovals
        let decided = model.decidedApprovals
        ScrollView {
            VStack(spacing: 12) {
                Picker(LocalizedStringResource("Show", bundle: .module), selection: $filter) {
                    Text("Waiting · \(waiting.count)", bundle: .module).tag(Filter.waiting)
                    Text("Decided · \(decided.count)", bundle: .module).tag(Filter.decided)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 4)

                switch filter {
                case .waiting:
                    if waiting.isEmpty {
                        ContentUnavailableView(LocalizedStringResource("Nothing waiting", bundle: .module), systemImage: "checkmark.circle",
                                               description: Text("Your agents will ping you here.", bundle: .module))
                    }
                    ForEach(waiting) { approval in
                        ApprovalCard(approval: approval) {
                            if let error = model.decisionErrors[approval.id] {
                                Label(LocalizedStringResource("Your decision wasn't sent: \(error)", bundle: .module), systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(Palette.halt)
                            }
                            HStack(spacing: 10) {
                                Button { decide(approval, true) } label: {
                                        Text("Approve", bundle: .module).frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.fabrixPrimary)
                                Button { decide(approval, false) } label: {
                                        Text("Reject", bundle: .module).frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.fabrixSecondary)
                            }
                        }
                    }
                case .decided:
                    if decided.isEmpty {
                        ContentUnavailableView(LocalizedStringResource("No decisions yet", bundle: .module), systemImage: "tray",
                                               description: Text("Approvals you decide show up here.", bundle: .module))
                    }
                    ForEach(decided) { decided in
                        ApprovalCard(approval: decided.approval) {
                            HStack {
                                Label(decided.approved ? LocalizedStringResource("Approved", bundle: .module) : LocalizedStringResource("Rejected", bundle: .module),
                                      systemImage: decided.approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(decided.approved ? Palette.done : Palette.halt)
                                Spacer()
                                if decided.canUndo {
                                    Button(LocalizedStringResource("Undo", bundle: .module)) { withAnimation { model.undo(decided.id) } }
                                        .buttonStyle(.fabrixSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.paper)
        .sensoryFeedback(.success, trigger: decided.count)
    }

    private func decide(_ approval: Approval, _ approve: Bool) {
        Task { await model.decide(approval, approve: approve, confirmingWith: lock) }
    }
}

private struct ApprovalCard<Actions: View>: View {
    let approval: Approval
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                KindTag(title: approval.kind.label)
                Text("\(approval.requestedBy) · \(approval.createdAt, format: .relative(presentation: .named))", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }
            Text(approval.title).font(.headline)
            Text(approval.detail)
                .font(.subheadline)
                .foregroundStyle(Palette.steel)
                .fixedSize(horizontal: false, vertical: true)
            actions.padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .fabrixCard()
        .fabrixTransition(.slideIn(from: .top))
    }
}

#Preview { PreviewHost { NavigationStack { ApprovalsView() } } }
