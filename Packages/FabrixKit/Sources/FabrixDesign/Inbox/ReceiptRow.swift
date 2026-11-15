import SwiftUI

/// How a receipt turned out for you: shown as an icon next to a sentence that names the outcome.
public enum ReceiptOutcome: CaseIterable, Sendable {
    case positive, negative, neutral

    var symbol: String {
        switch self {
        case .positive: "checkmark.circle.fill"
        case .negative: "xmark.circle.fill"
        case .neutral: "minus.circle.fill"
        }
    }

    var tone: Tone {
        switch self {
        case .positive: .done
        case .negative: .halt
        case .neutral: .neutral
        }
    }
}

/// "Priya approved X for you": an outcome icon, the sentence and a dismiss button. Not a card, never counted.
public struct ReceiptRow: View {
    private let sentence: String
    private let outcome: ReceiptOutcome
    private let onDismiss: () -> Void

    public init(sentence: String, outcome: ReceiptOutcome, onDismiss: @escaping () -> Void) {
        self.sentence = sentence
        self.outcome = outcome
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: outcome.symbol)
                .foregroundStyle(outcome.tone.color)
                .accessibilityHidden(true)
            Text(verbatim: sentence)
                .font(.fabrix(.subheadline))
                .foregroundStyle(Palette.steel)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.fabrix(.label))
                    .foregroundStyle(Palette.steel)
                    .frame(minWidth: minimumTapTarget, minHeight: minimumTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Dismiss", bundle: .module))
        }
        .padding(.leading, Spacing.l)
        .padding(.vertical, Spacing.xs)
        .background(Palette.rail)
    }
}

private struct ReceiptRowPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            ReceiptRow(sentence: "Priya approved Hire a Designer agent for you", outcome: .positive) {}
            ReceiptRow(sentence: "Priya rejected the Q4 plan for you", outcome: .negative) {}
            ReceiptRow(sentence: "Priya answered Which push provider? for you", outcome: .neutral) {}
        }
    }
}

#Preview("ReceiptRow") { ReceiptRowPreview() }

#Preview("ReceiptRow · dark") { ReceiptRowPreview().preferredColorScheme(.dark) }

#Preview("ReceiptRow · accessibility") { ReceiptRowPreview().dynamicTypeSize(.accessibility3) }
