import FabrixCore
import SwiftUI

extension AppModel {
    /// Stages the decision once the lock confirms it; a failed confirmation leaves the approval waiting.
    func decide(_ approval: Approval, approve: Bool, confirmingWith lock: AppLock) async {
        guard await lock.confirmDecision() else { return }
        withAnimation { decide(approval, approve: approve) }
    }
}
