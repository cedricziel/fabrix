import FabrixCore

struct DecidedApproval: Identifiable, Hashable {
    var approval: Approval
    var approved: Bool
    var canUndo: Bool
    /// Decided here and on its way to the factory, after the undo window.
    var isSending = false
    var id: Approval.ID { approval.id }
}

/// Decisions wait here for an undo window before they reach the factory, which has no undo.
struct ApprovalDesk {
    private struct Entry {
        var approve: Bool
        var committing = false
    }

    private var entries: [Approval.ID: Entry] = [:]

    var stagedIDs: [Approval.ID] {
        entries.filter { !$0.value.committing }.map(\.key)
    }

    func waiting(_ approvals: [Approval]) -> [Approval] {
        approvals.filter { $0.state == .pending && entries[$0.id] == nil }
    }

    func decided(_ approvals: [Approval]) -> [DecidedApproval] {
        approvals.compactMap { approval in
            if let entry = entries[approval.id] {
                return DecidedApproval(
                    approval: approval, approved: entry.approve, canUndo: !entry.committing,
                    isSending: entry.committing && approval.state == .pending
                )
            }
            guard approval.state != .pending else { return nil }
            return DecidedApproval(approval: approval, approved: approval.state == .approved, canUndo: false)
        }
    }

    mutating func stage(_ id: Approval.ID, approve: Bool) {
        entries[id] = Entry(approve: approve)
    }

    mutating func undo(_ id: Approval.ID) -> Bool {
        guard entries[id]?.committing == false else { return false }
        entries[id] = nil
        return true
    }

    /// Returns the staged verdict and locks it, or nil if nothing is waiting to be committed.
    mutating func beginCommit(_ id: Approval.ID) -> Bool? {
        guard let entry = entries[id], !entry.committing else { return nil }
        entries[id]?.committing = true
        return entry.approve
    }

    mutating func finish(_ id: Approval.ID) {
        entries[id] = nil
    }

    var ids: Set<Approval.ID> {
        Set(entries.keys)
    }

    func tracks(_ id: Approval.ID) -> Bool {
        entries[id] != nil
    }

    /// Forgets decisions on approvals that left with their company.
    mutating func keepOnly(_ ids: Set<Approval.ID>) {
        entries = entries.filter { ids.contains($0.key) }
    }

    /// Drops sent decisions once the factory shows them decided (or the approval is gone).
    /// Until then they stay under Decided, even if the refresh after sending failed.
    mutating func settle(with approvals: [Approval]) {
        let pending = Set(approvals.filter { $0.state == .pending }.map(\.id))
        entries = entries.filter { !$0.value.committing || pending.contains($0.key) }
    }
}
