import SwiftUI

public struct CommentRow: View {
    public enum State: Sendable { case normal, sending, failed }

    private let author, bodyText, age: String
    private let state: State
    private let failureText: String?
    private let retry: (() -> Void)?

    public init(author: String, body: String, age: String, state: State = .normal, failureText: String? = nil, retry: (() -> Void)? = nil) {
        self.author = author; self.bodyText = body; self.age = age
        self.state = state; self.failureText = failureText; self.retry = retry
    }

    nonisolated static func presentation(state: State, failureText: String?) -> [String] {
        switch state {
        case .normal: []
        case .sending: [String(localized: "inbox.comment.sending", defaultValue: "Sending…", bundle: .module)]
        case .failed: [String(localized: "inbox.comment.failed", defaultValue: "Failed", bundle: .module)] + (failureText.map { [$0] } ?? [])
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var isAccessibilitySize: Bool { dynamicTypeSize >= .accessibility1 }

    public var body: some View {
        Group {
            if isAccessibilitySize { VStack(alignment: .leading, spacing: Spacing.s) { content } }
            else { HStack(alignment: .top, spacing: Spacing.m) { content } }
        }
        .padding(Spacing.m)
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack { Text(verbatim: author).font(.fabrix(.subheadline)).foregroundStyle(Palette.graphite); Spacer(minLength: 0); Text(verbatim: age).font(.fabrix(.caption)).foregroundStyle(Palette.muted) }
            Text(verbatim: bodyText).font(.fabrix(.body)).foregroundStyle(Palette.graphite)
            ForEach(Array(Self.presentation(state: state, failureText: failureText).enumerated()), id: \.offset) { _, message in
                Text(verbatim: message).font(.fabrix(.caption)).foregroundStyle(state == .failed ? Palette.haltInk : Palette.muted)
            }
            if state == .failed, let retry {
                Button(action: retry) { Text(String(localized: "inbox.comment.retry", defaultValue: "Retry", bundle: .module)).font(.fabrix(.label)) }
                    .accessibilityLabel(Text(String(localized: "inbox.comment.retry", defaultValue: "Retry", bundle: .module)))
            }
        }
    }
}

#Preview("Comment normal light") { CommentRow(author: "Alex", body: "Looks good to me.", age: "2m ago").padding().background(Palette.paper).preferredColorScheme(.light) }
#Preview("Comment sending dark") { CommentRow(author: "Alex", body: "Looks good to me.", age: "2m ago", state: .sending).padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Comment failed") { CommentRow(author: "Alex", body: "Looks good to me.", age: "2m ago", state: .failed, failureText: "Connection lost", retry: {}).padding() }
#Preview("Comment accessibility") { CommentRow(author: "Alex", body: "Looks good to me.", age: "2m ago", state: .failed, failureText: "Connection lost", retry: {}).padding().dynamicTypeSize(.accessibility3) }
