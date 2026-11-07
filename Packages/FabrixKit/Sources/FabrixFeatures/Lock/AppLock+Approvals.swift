import FabrixCore

extension AppModel {
    /// Stages the decision once the lock confirms it; a failed confirmation leaves the approval waiting.
    func decide(_ approval: Approval, approve: Bool, confirmingWith lock: AppLock) async {
        guard await lock.confirmDecision() else { return }
        decide(approval, approve: approve)
    }
}
