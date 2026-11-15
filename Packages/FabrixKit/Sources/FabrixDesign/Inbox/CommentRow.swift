import SwiftUI

public enum CommentState: Equatable, Sendable {
    case sent, sending, failed
}

/// One comment on an approval: author, age and text. A comment you just wrote can be sending or not sent.
public struct CommentRow: View {
    private let author: String
    private let isAgent: Bool
    private let age: String
    private let text: String
    private let state: CommentState
    private let onRetry: (() -> Void)?

    public init(
        author: String, isAgent: Bool, age: String, text: String, state: CommentState = .sent,
        onRetry: (() -> Void)? = nil
    ) {
        self.author = author
        self.isAgent = isAgent
        self.age = age
        self.text = text
        self.state = state
        self.onRetry = onRetry
    }

    nonisolated static func accessibilityLabel(
        author: String, isAgent: Bool, age: String, text: String, state: CommentState
    ) -> String {
        let header = [author] + (isAgent ? [String(localized: "agent", bundle: .module)] : []) + [age]
        let status: String? = switch state {
        case .sent: nil
        case .sending: String(localized: "Sending", bundle: .module)
        case .failed: String(localized: "Not sent", bundle: .module)
        }
        return [header.joined(separator: ", "), text, status].compactMap { $0 }.spokenSentences()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            AvatarBadge(author)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.s) {
                        Text(verbatim: author).font(.fabrix(.headline)).foregroundStyle(Palette.graphite)
                        if isAgent { KindTag(title: String(localized: "Agent", bundle: .module), tone: .neutral) }
                        Text(verbatim: age).font(.fabrix(.caption)).foregroundStyle(Palette.muted)
                    }
                    Text(verbatim: text).font(.fabrix(.body)).foregroundStyle(Palette.graphite)
                    statusLine
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: Self.accessibilityLabel(
                    author: author, isAgent: isAgent, age: age, text: text, state: state
                )))
                if state == .failed, let onRetry {
                    Button(action: onRetry) { Text("Retry", bundle: .module) }
                        .buttonStyle(.fabrixSecondary)
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(state == .sending ? 0.7 : 1)
    }

    @ViewBuilder private var statusLine: some View {
        switch state {
        case .sent: EmptyView()
        case .sending:
            Label { Text("Sending…", bundle: .module) } icon: { ProgressView().controlSize(.mini) }
                .font(.fabrix(.caption)).foregroundStyle(Palette.muted)
        case .failed:
            Label { Text("Not sent", bundle: .module) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
                .font(.fabrix(.caption)).foregroundStyle(Palette.haltInk)
        }
    }
}

private struct CommentRowPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            CommentRow(author: "Priya", isAgent: false, age: "3 minutes ago", text: "Looks good to me.")
            CommentRow(author: "CEO", isAgent: true, age: "10 minutes ago", text: "Budget fits the plan.")
            CommentRow(author: "You", isAgent: false, age: "now", text: "Please add the review date.", state: .sending)
            CommentRow(author: "You", isAgent: false, age: "now", text: "Please add the review date.", state: .failed) {}
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("CommentRow") { CommentRowPreview() }

#Preview("CommentRow · dark") { CommentRowPreview().preferredColorScheme(.dark) }

#Preview("CommentRow · accessibility") { CommentRowPreview().dynamicTypeSize(.accessibility3) }
