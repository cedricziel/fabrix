import FabrixDesign
import SwiftUI

/// Placeholder until FactoryService can create tasks.
struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(LocalizedStringResource("Title", bundle: .module), text: $title)
                Text("Creating tasks from Fabrix arrives in an upcoming build. Until then, create them on your Paperclip board.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .formStyle(.grouped)
            .navigationTitle(LocalizedStringResource("New task", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringResource("Cancel", bundle: .module)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringResource("Create", bundle: .module)) {}.disabled(true)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 240)
    }
}
