import FabrixDesign
import SwiftUI

/// Placeholder until FactoryService can create tasks.
struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(.features("Title"), text: $title)
                Text("Creating tasks from Fabrix arrives in an upcoming build. Until then, create them on your Paperclip board.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .formStyle(.grouped)
            .navigationTitle(.features("New task"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.features("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.features("Create")) {}.disabled(true)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 240)
    }
}
