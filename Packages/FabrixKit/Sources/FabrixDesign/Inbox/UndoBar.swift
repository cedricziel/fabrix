import SwiftUI

public enum UndoPhase: Sendable, Equatable { case counting, sending, sent, held, failed }

struct UndoAnnouncementState {
    private var lastPhase: UndoPhase?

    mutating func message(phase: UndoPhase, verdict: String, remainingSeconds: Int, failureReason: String?) -> String? {
        guard phase != lastPhase else { return nil }
        lastPhase = phase
        return UndoBar.announcement(phase: phase, verdict: verdict, remainingSeconds: remainingSeconds, failureReason: failureReason)
    }
}

public struct UndoBar: View {
    public let phase: UndoPhase
    public let verdict: String
    public let remainingSeconds: Int
    public let failureReason: String?
    public let onUndo: () -> Void
    public let onSendNow: () -> Void
    @State private var announcements = UndoAnnouncementState()

    public init(phase: UndoPhase, verdict: String, remainingSeconds: Int, failureReason: String? = nil, onUndo: @escaping () -> Void, onSendNow: @escaping () -> Void) {
        self.phase = phase; self.verdict = verdict; self.remainingSeconds = remainingSeconds
        self.failureReason = failureReason; self.onUndo = onUndo; self.onSendNow = onSendNow
    }

    nonisolated static func announcement(phase: UndoPhase, verdict: String, remainingSeconds: Int, failureReason: String?) -> String {
        switch phase {
        case .counting: String(localized: "\(verdict), sending in \(remainingSeconds) seconds", bundle: .module)
        case .sending: String(localized: "\(verdict), sending", bundle: .module)
        case .sent: String(localized: "\(verdict), sent", bundle: .module)
        case .held: String(localized: "\(verdict). Not sent yet. It goes out when you sign in again.", bundle: .module)
        case .failed: String(localized: "\(verdict). Not sent: \(failureReason ?? String(localized: "Unknown error", bundle: .module))", bundle: .module)
        }
    }

    public var body: some View {
        let message = Self.announcement(phase: phase, verdict: verdict, remainingSeconds: remainingSeconds, failureReason: failureReason)
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(verbatim: message).font(.fabrix(.body)).fixedSize(horizontal: false, vertical: true)
            HStack {
                if phase == .counting { Button(String(localized: "Undo", bundle: .module), action: onUndo).buttonStyle(.fabrixSecondary) }
                Spacer(minLength: 0)
                if phase == .counting { Button(String(localized: "Send now", bundle: .module), action: onSendNow).buttonStyle(.fabrixPrimary) }
            }
        }
        .padding(Spacing.m).frame(maxWidth: .infinity, alignment: .leading).background(Palette.card)
        .accessibilityElement(children: .contain).accessibilityAddTraits(.updatesFrequently)
        .onChange(of: phase, initial: true) { _, newPhase in
            if let announcement = announcements.message(phase: newPhase, verdict: verdict, remainingSeconds: remainingSeconds, failureReason: failureReason) {
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
    }
}

#Preview("Undo bar · light") { UndoBar(phase: .counting, verdict: "Approved", remainingSeconds: 8, onUndo: {}, onSendNow: {}).padding().preferredColorScheme(.light) }
#Preview("Undo bar · dark") { UndoBar(phase: .held, verdict: "Approved", remainingSeconds: 0, onUndo: {}, onSendNow: {}).padding().preferredColorScheme(.dark) }
#Preview("Undo bar · accessibility") { VStack { ForEach([UndoPhase.counting, .sending, .sent, .held, .failed].indices, id: \.self) { index in let phases: [UndoPhase] = [.counting, .sending, .sent, .held, .failed]; UndoBar(phase: phases[index], verdict: "Approved", remainingSeconds: 8, failureReason: "Network unavailable", onUndo: {}, onSendNow: {}) } }.dynamicTypeSize(.accessibility3) }
