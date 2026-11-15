import SwiftUI

public struct ReceiptRow: View {
    private let receiptText: String
    private let context: String?
    private let dismiss: () -> Void

    public init(receiptText: String, context: String? = nil, dismiss: @escaping () -> Void) {
        self.receiptText = receiptText
        self.context = context
        self.dismiss = dismiss
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var isAccessibilitySize: Bool { dynamicTypeSize >= .accessibility1 }

    public var body: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.s) { content }
            } else {
                HStack(alignment: .center, spacing: Spacing.m) { content }
            }
        }
        .padding(Spacing.m)
        .background(Palette.paper)
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: receiptText)
                .font(.fabrix(.body))
                .foregroundStyle(Palette.graphite)
            if let context {
                Text(verbatim: context)
                    .font(.fabrix(.caption))
                    .foregroundStyle(Palette.muted)
            }
        }
        Spacer(minLength: 0)
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.fabrix(.label))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("inbox.receipt.dismiss", bundle: .module))
    }
}

#Preview("Receipt light") { ReceiptRow(receiptText: "Approved", context: "Hiring request · 2 minutes ago", dismiss: {}).padding().preferredColorScheme(.light) }
#Preview("Receipt dark") { ReceiptRow(receiptText: "Approved", context: "Hiring request · 2 minutes ago", dismiss: {}).padding().preferredColorScheme(.dark) }
#Preview("Receipt accessibility") { ReceiptRow(receiptText: "Approved", context: "Hiring request · 2 minutes ago", dismiss: {}).padding().dynamicTypeSize(.accessibility3) }
