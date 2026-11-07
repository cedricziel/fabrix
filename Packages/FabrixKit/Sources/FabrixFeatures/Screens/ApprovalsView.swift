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
                Picker(.features("Show"), selection: $filter) {
                    Text("Waiting · \(waiting.count)", bundle: .module).tag(Filter.waiting)
                    Text("Decided · \(decided.count)", bundle: .module).tag(Filter.decided)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 4)

                switch filter {
                case .waiting:
                    if waiting.isEmpty {
                        ContentUnavailableView(.features("Nothing waiting"), systemImage: "checkmark.circle",
                                               description: Text("Your agents will ping you here.", bundle: .module))
                    }
                    ForEach(waiting) { approval in
                        ApprovalCard(approval: approval) {
                            if let error = model.decisionErrors[approval.id] {
                                Label(.features("Your decision wasn't sent: \(error)"), systemImage: "exclamationmark.triangle.fill")
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
                        ContentUnavailableView(.features("No decisions yet"), systemImage: "tray",
                                               description: Text("Approvals you decide show up here.", bundle: .module))
                    }
                    ForEach(decided) { decided in
                        ApprovalCard(approval: decided.approval) {
                            HStack {
                                Label(decided.approved ? .features("Approved") : .features("Rejected"),
                                      systemImage: decided.approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(decided.approved ? Palette.done : Palette.halt)
                                Spacer()
                                if decided.canUndo {
                                    Button(.features("Undo")) { withAnimation { model.undo(decided.id) } }
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
                Text(verbatim: "\(approval.requestedBy) · \(approval.createdAt.formatted(.relative(presentation: .named)))")
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
