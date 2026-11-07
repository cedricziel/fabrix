import SwiftUI

/// Shared shape for Fabrix buttons. `controlSize` picks the height:
/// small 30 (Mac toolbars and inline actions), regular 44, large 50.
/// On touch devices every size keeps a 44pt hit area.
private struct FabrixButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let fill: Color
    let foreground: Color
    var border: Color?

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

    private var height: CGFloat {
        switch controlSize {
        case .mini, .small: 30
        case .large, .extraLarge: 50
        default: minimumTapTarget
        }
    }

    private var radius: CGFloat {
        switch controlSize {
        case .mini, .small: Radius.row
        case .large, .extraLarge: Radius.controlLarge
        default: Radius.control
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .font(.fabrix(.headline))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, height < minimumTapTarget ? Spacing.m : 18)
            .frame(minHeight: height)
            .background(fill, in: shape)
            .overlay {
                if let border {
                    shape.strokeBorder(border)
                }
            }
            .contentShape(shape)
        #if !os(macOS)
            .frame(minHeight: minimumTapTarget)
            .contentShape(Rectangle())
        #endif
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Black confirm button: Approve.
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        FabrixButtonBody(configuration: configuration, fill: Palette.graphite, foreground: Palette.onGraphite)
    }
}

/// Orange button for the one action that a human is waited on for: Wake now, New task.
public struct SignalButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        FabrixButtonBody(configuration: configuration, fill: Palette.signal, foreground: Palette.onSignal)
    }
}

/// Outlined button for everything else: Pause, Reject, Open.
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        FabrixButtonBody(
            configuration: configuration, fill: Palette.card, foreground: Palette.graphite, border: Palette.hairline
        )
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var fabrixPrimary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}

public extension ButtonStyle where Self == SignalButtonStyle {
    static var fabrixSignal: SignalButtonStyle {
        SignalButtonStyle()
    }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var fabrixSecondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

#Preview("Buttons") {
    VStack(alignment: .leading, spacing: Spacing.l) {
        HStack {
            Button("Wake now") {}.buttonStyle(.fabrixSignal)
            Button("Approve") {}.buttonStyle(.fabrixPrimary)
            Button("Pause") {}.buttonStyle(.fabrixSecondary)
        }
        HStack {
            Button("Approve") {}.buttonStyle(.fabrixPrimary)
            Button("Open") {}.buttonStyle(.fabrixSecondary)
        }
        .controlSize(.small)
        HStack {
            Button("Pause") {}.buttonStyle(.fabrixSecondary)
            Button("Wake now") {}.buttonStyle(.fabrixSignal)
        }
        .controlSize(.large)
        Button("Disabled") {}.buttonStyle(.fabrixPrimary).disabled(true)
    }
    .padding()
    .background(Palette.paper)
}
