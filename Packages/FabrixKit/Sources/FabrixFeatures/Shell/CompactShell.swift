import SwiftUI

/// iPhone: a pager for approvals and wake/pause, four tabs.
struct CompactShell: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        TabView(selection: $navigator.tab) {
            ForEach(CompactTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.root.systemImage, value: tab) {
                    TabStack(tab: tab)
                }
                .badge(tab == .approvals ? model.waitingCount : 0)
            }
        }
    }
}

private struct TabStack: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    let tab: CompactTab

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: path) {
            SectionScreen(section: tab.root)
                .fabrixDestinations()
                .toolbar {
                    if tab == .factory { CompanyToolbar() }
                    if !tab.nestedSections.isEmpty {
                        ToolbarItem(placement: .navigation) {
                            Menu {
                                ForEach(tab.nestedSections) { section in
                                    Button { navigator.open(section) } label: {
                                        Label(section.title, systemImage: section.systemImage)
                                    }
                                }
                                if tab == .factory, model.canForgetFactory {
                                    Divider()
                                    Button("Forget Factory…", systemImage: "trash", role: .destructive) {
                                        navigator.confirmingForget = true
                                    }
                                }
                            } label: {
                                Label("More", systemImage: "ellipsis.circle")
                            }
                        }
                    }
                }
                .modifier(SearchField(enabled: tab == .tasks || tab == .agents, text: $model.searchText))
        }
        .refreshable { await model.refresh() }
    }

    private var path: Binding<NavigationPath> {
        Binding {
            navigator.tabPaths[tab] ?? NavigationPath()
        } set: {
            navigator.tabPaths[tab] = $0
        }
    }
}

private struct SearchField: ViewModifier {
    let enabled: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if enabled {
            content.searchable(text: $text, prompt: "Search")
        } else {
            content
        }
    }
}
