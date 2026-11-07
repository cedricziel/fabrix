import SwiftUI

/// How a view enters and leaves. Slides become fades when Reduce Motion is on.
public enum FabrixTransition: Sendable {
    case slideIn(from: Edge)

    enum Resolved: Equatable {
        case fade
        case slideAndFade(Edge)
    }

    func resolved(reduceMotion: Bool) -> Resolved {
        switch self {
        case let .slideIn(edge): reduceMotion ? .fade : .slideAndFade(edge)
        }
    }
}

extension FabrixTransition.Resolved {
    var transition: AnyTransition {
        switch self {
        case .fade: .opacity
        case let .slideAndFade(edge): .move(edge: edge).combined(with: .opacity)
        }
    }
}

private struct FabrixTransitionModifier: ViewModifier {
    let kind: FabrixTransition
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transition(kind.resolved(reduceMotion: reduceMotion).transition)
    }
}

public extension View {
    /// Applies a Fabrix transition that respects Reduce Motion.
    func fabrixTransition(_ kind: FabrixTransition) -> some View {
        modifier(FabrixTransitionModifier(kind: kind))
    }
}

private struct MotionPreview: View {
    @State private var shown = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Button(shown ? "Hide" : "Show") { withAnimation { shown.toggle() } }
                .buttonStyle(.fabrixSecondary)
            if shown {
                Text("Slides in from the top, or fades with Reduce Motion")
                    .padding(Spacing.m)
                    .fabrixCard()
                    .fabrixTransition(.slideIn(from: .top))
            }
            Spacer()
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("Motion") { MotionPreview() }

#Preview("Motion · dark") { MotionPreview().preferredColorScheme(.dark) }
