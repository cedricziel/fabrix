import SwiftUI

/// The color family of a pill: a strong color, an ink for text and a tint for the ground.
public enum Tone: CaseIterable, Sendable {
    case run, neutral, signal, halt, done

    public var color: Color {
        switch self {
        case .run: Palette.run
        case .neutral: Palette.muted
        case .signal: Palette.signal
        case .halt: Palette.halt
        case .done: Palette.done
        }
    }

    public var ink: Color {
        switch self {
        case .run: Palette.runInk
        case .neutral: Palette.neutralInk
        case .signal: Palette.signalInk
        case .halt: Palette.haltInk
        case .done: Palette.doneInk
        }
    }

    public var tint: Color {
        switch self {
        case .run: Palette.runTint
        case .neutral: Palette.neutralTint
        case .signal: Palette.signalTint
        case .halt: Palette.haltTint
        case .done: Palette.doneTint
        }
    }
}

/// A tinted capsule with a label and an optional leading mark, such as a status dot.
public struct Pill<Leading: View>: View {
    private let label: Text
    private let tone: Tone
    private let leading: Leading

    public init(_ title: LocalizedStringResource, tone: Tone, @ViewBuilder leading: () -> Leading) {
        label = Text(title)
        self.tone = tone
        self.leading = leading()
    }

    @_disfavoredOverload
    public init(verbatim title: String, tone: Tone, @ViewBuilder leading: () -> Leading) {
        label = Text(verbatim: title)
        self.tone = tone
        self.leading = leading()
    }

    public var body: some View {
        HStack(spacing: 6) {
            leading
            label.lineLimit(1)
        }
        .font(.fabrix(.label))
        .foregroundStyle(tone.ink)
        .padding(.horizontal, 10)
        .frame(minHeight: 28)
        .background(tone.tint, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

public extension Pill where Leading == EmptyView {
    init(_ title: LocalizedStringResource, tone: Tone) {
        self.init(title, tone: tone) { EmptyView() }
    }

    @_disfavoredOverload
    init(verbatim title: String, tone: Tone) {
        self.init(verbatim: title, tone: tone) { EmptyView() }
    }
}

private struct PillsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Pill("Run", tone: .run)
            Pill("Neutral", tone: .neutral)
            Pill("Signal", tone: .signal)
            Pill("Halt", tone: .halt)
            Pill("Done", tone: .done)
            Pill("With a mark", tone: .run) { Image(systemName: "bolt.fill") }
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("Pills") { PillsPreview() }

#Preview("Pills · dark") { PillsPreview().preferredColorScheme(.dark) }
