import SwiftUI

public struct OwnerLabel: View {
    private let owner: String
    public init(_ owner: String) { self.owner = owner }
    public var body: some View { Text(verbatim: owner).font(.fabrix(.subheadline)).foregroundStyle(Palette.muted) }
}

#Preview("Owner light") { OwnerLabel("For you").padding().background(Palette.paper).preferredColorScheme(.light) }
#Preview("Owner dark") { OwnerLabel("For you").padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Owner accessibility") { OwnerLabel("For you").padding().dynamicTypeSize(.accessibility3) }
