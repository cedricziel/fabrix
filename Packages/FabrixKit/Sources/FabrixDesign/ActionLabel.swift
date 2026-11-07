import SwiftUI

/// A button title that turns into a spinner while its action runs, keeping the button's width.
public struct ActionLabel: View {
    private let title: LocalizedStringResource
    private let isBusy: Bool

    public init(_ title: LocalizedStringResource, isBusy: Bool) {
        self.title = title
        self.isBusy = isBusy
    }

    public var body: some View {
        Text(title)
            .opacity(isBusy ? 0 : 1)
            .overlay { if isBusy { ProgressView().controlSize(.small) } }
            .frame(maxWidth: .infinity)
    }
}
