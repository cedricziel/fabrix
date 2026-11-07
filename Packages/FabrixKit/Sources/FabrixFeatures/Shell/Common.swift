import FabrixCore
import FabrixDesign
import SwiftUI

/// A card with a heading and rows below a divider: "Live runs", "Activity".
struct SectionCard<Content: View>: View {
    let title: LocalizedStringResource
    var action: (title: LocalizedStringResource, perform: () -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if let action {
                        SectionHeader(String(localized: title), actionTitle: String(localized: action.title), action: action.perform)
                    } else {
                        SectionHeader(String(localized: title))
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                Divider().overlay(Palette.divider)
                content
            }
        }
    }
}

struct EmptyRow: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.l)
    }
}

/// Ticks once a second while visible.
struct ElapsedText: View {
    let since: Date

    var body: some View {
        TimelineView(.periodic(from: since, by: 1)) { context in
            Text(Elapsed.string(from: since, to: context.date))
                .monospacedDigit()
        }
    }
}

extension View {
    /// Puts content on the design system's standard card surface.
    func cardSurface() -> some View {
        Card(padding: 0) { self }
    }

    /// The signal outline on the selected card of a board or chart.
    func selectionOutline(_ isSelected: Bool) -> some View {
        overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.signal, lineWidth: 2)
            }
        }
    }
}

extension Binding {
    /// Shows a presentation while an optional selection is set; dismissing clears it.
    func isPresent<Wrapped: Sendable>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool> { wrappedValue != nil } set: { if !$0 { wrappedValue = nil } }
    }
}

extension BudgetBar {
    init(_ budget: Budget, height: CGFloat = 8) {
        self.init(spent: Double(budget.spentCents), limit: Double(budget.capCents ?? 0), height: height)
    }
}

extension AgentStatus {
    var style: StatusStyle {
        switch self {
        case .running: .running
        case .idle: .idle
        case .paused: .paused
        case .needsYou: .needsYou
        case .blocked, .error: .blocked
        }
    }
}
