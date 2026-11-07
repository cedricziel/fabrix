import FabrixCore
import SwiftUI

extension View {
    /// The company as the navigation title, its factory as subtitle, and the factory menu
    /// as the title menu. `title` replaces the company name, e.g. "Tasks" on an iPhone tab.
    func factoryTitle(_ title: LocalizedStringResource? = nil) -> some View {
        modifier(FactoryTitle(title: title))
    }
}

private struct FactoryTitle: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    let title: LocalizedStringResource?

    func body(content: Content) -> some View {
        #if os(macOS)
        // macOS shows title menus only for document windows, so the title itself becomes the menu.
        content
            .navigationTitle(companyName)
            .toolbar(removing: .title)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        FactoryMenuContent(model: model, navigator: navigator)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(companyName).font(.headline)
                            if let factory = model.factory {
                                Text(factory.name).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .menuIndicator(.visible)
                    .fixedSize()
                    .help(.features("Switch factory or company"))
                }
            }
        #else
        content
            .navigationTitle(title.map { Text($0) } ?? Text(companyName))
            .navigationSubtitle(model.factory?.name ?? "")
            .toolbarTitleMenu {
                FactoryMenuContent(model: model, navigator: navigator)
            }
        #endif
    }

    private var companyName: String {
        model.snapshot?.company.name ?? "Fabrix"
    }
}

/// The factory and company commands, shared by the title menu and the macOS Factory menu.
struct FactoryMenuContent: View {
    let model: AppModel
    let navigator: Navigator
    var showsShortcuts = false

    var body: some View {
        let menu = model.factoryMenu
        if !menu.companies.isEmpty {
            Section(model.factory?.name ?? "") {
                ForEach(menu.companies) { item in
                    Toggle(item.company.name, isOn: binding(selected: item.isSelected) {
                        Task { await model.select(item.company) }
                    })
                    .keyboardShortcut(showsShortcuts ? item.shortcut.map { KeyEquivalent(Character("\($0)")) } : nil)
                }
            }
        }
        Section(.features("Factories")) {
            ForEach(menu.factories) { item in
                Toggle(item.factory.name, isOn: binding(selected: item.isOpen) {
                    Task { await model.open(item.factory) }
                })
            }
        }
        Section {
            Button(.features("Add Factory…"), systemImage: "plus") { navigator.showingAddFactory = true }
            if menu.canRemove {
                Button(.features("Remove Factory…"), systemImage: "trash", role: .destructive) { navigator.confirmingRemove = true }
            }
        }
    }

    /// A checkmark that runs `select` when turned on and ignores being turned off.
    private func binding(selected: Bool, select: @escaping () -> Void) -> Binding<Bool> {
        Binding { selected } set: { if $0 { select() } }
    }
}

private extension View {
    @ViewBuilder
    func keyboardShortcut(_ key: KeyEquivalent?) -> some View {
        if let key { keyboardShortcut(key, modifiers: .command) } else { self }
    }
}

extension FocusedValues {
    @Entry var appModel: AppModel?
    @Entry var navigator: Navigator?
}

/// The Factory menu in the macOS menu bar (and iPad keyboard shortcuts), acting on the
/// focused window.
public struct FactoryCommands: Commands {
    @FocusedValue(\.appModel) private var model
    @FocusedValue(\.navigator) private var navigator

    public init() {}

    public var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(.features("Refresh")) { Task { await model?.refresh() } }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(model == nil || model?.isOnboarding == true)
        }
        CommandMenu(Text("Factory", bundle: .module)) {
            if let model, let navigator, !model.isOnboarding {
                FactoryMenuContent(model: model, navigator: navigator, showsShortcuts: true)
            } else {
                Button(.features("Add Factory…")) {}.disabled(true)
            }
        }
    }
}
