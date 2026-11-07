import FabrixCore
import FabrixDesign
import SwiftUI

struct ActivityView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            ActivityRows(events: model.snapshot?.activity ?? [])
                .fabrixCard()
                .padding(20)
                .frame(maxWidth: 900, alignment: .leading)
        }
        .background(Palette.paper)
        .navigationTitle("Activity")
    }
}

struct ActivityRows: View {
    let events: [ActivityEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if events.isEmpty {
                EmptyRow(text: "No activity yet.")
            }
            ForEach(events) { event in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(event.at, format: .dateTime.hour().minute())
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.muted)
                        .frame(minWidth: 44, alignment: .leading)
                    Text("**\(event.actor)** \(event.summary)")
                        .foregroundStyle(Palette.steel)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
