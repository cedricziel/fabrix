import FabrixCore
import FabrixDesign
import SwiftUI

struct ApprovalsView: View {
    enum Filter: Hashable { case waiting, decided }

    @Environment(AppModel.self) private var model
    @State private var filter = Filter.waiting

    var body: some View {
        let waiting = model.waitingApprovals
        let decided = model.decidedApprovals
        ScrollView {
            VStack(spacing: 12) {
                Picker("Show", selection: $filter) {
                    Text("Waiting · \(waiting.count)").tag(Filter.waiting)
                    Text("Decided · \(decided.count)").tag(Filter.decided)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 4)

                switch filter {
                case .waiting:
                    if waiting.isEmpty {
                        ContentUnavailableView("Nothing waiting", systemImage: "checkmark.circle",
                                               description: Text("Your agents will ping you here."))
                    }
                    ForEach(waiting) { approval in
                        ApprovalCard(approval: approval) {
                            HStack(spacing: 10) {
                                Button("Approve") { decide(approval, true) }
                                    .buttonStyle(FabrixButtonStyle(role: .primary, fullWidth: true))
                                Button("Reject") { decide(approval, false) }
                                    .buttonStyle(FabrixButtonStyle(role: .secondary, fullWidth: true))
                            }
                        }
                    }
                case .decided:
                    if decided.isEmpty {
                        ContentUnavailableView("No decisions yet", systemImage: "tray",
                                               description: Text("Approvals you decide show up here."))
                    }
                    ForEach(decided) { decided in
                        ApprovalCard(approval: decided.approval) {
                            HStack {
                                Label(decided.approved ? "Approved" : "Rejected",
                                      systemImage: decided.approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(decided.approved ? Palette.done : Palette.halt)
                                Spacer()
                                if decided.canUndo {
                                    Button("Undo") { withAnimation { model.undo(decided.id) } }
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
        .navigationTitle("Approvals")
        .sensoryFeedback(.success, trigger: decided.count)
    }

    private func decide(_ approval: Approval, _ approve: Bool) {
        withAnimation { model.decide(approval, approve: approve) }
    }
}

private struct ApprovalCard<Actions: View>: View {
    let approval: Approval
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                KindTag(kind: approval.kind)
                Text("\(approval.requestedBy) · \(approval.createdAt, format: .relative(presentation: .named))")
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview { PreviewHost { NavigationStack { ApprovalsView() } } }
