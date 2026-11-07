## Context

`AppModel` holds one open factory and its companies. `FactoryStore` (through `FactoryConnector`) keeps every saved factory and its credentials. Today the sidebar renders factories and companies as rows above the sections.

## Goals / Non-Goals

**Goals:**

- One place to switch factory and company, reachable whether or not the sidebar is visible, on every platform.
- A menu-bar equivalent on macOS.

**Non-Goals:**

- Listing other factories' companies. That would need a network request per saved factory each time the menu opens. A factory opens on its last company and its companies show once it is current.
- Multi-factory windows (one window per factory).

## Decisions

- **Title menu over a toolbar picker.** `toolbarTitleMenu` is the HIG's "document menu" at the toolbar's leading edge. It works on iOS, iPadOS and macOS and survives a hidden sidebar. A picker in the toolbar would compete with Pause company and New task.
- **A pure `FactoryMenu` value.** It is built from the saved factories, the open factory, its companies and the selected company. It drives the title menu and the macOS Factory menu, so both always match and can be tested without UI.
- **Cmd-1…9 select companies, not factories.** Companies change more often than factories, and their order is stable within a factory. Factories stay one click away in the same menu.
- **Remove falls back to the next saved factory, then onboarding.** Removing the open factory shouldn't strand the user when others are saved. The demo has nothing saved, so it can't be removed; it stays reachable as the last menu entry.
- **Menu-bar commands read the focused window.** `FactoryCommands` uses `@FocusedValue` for the window's `AppModel` and `Navigator`, so each window's menu acts on that window.

## Risks / Trade-offs

- [Users who relied on the sidebar rows look there first] → The title shows the company name and factory, and the menu chevron sits beside it.
- [A removed factory's companies vanish from the menu at once] → Removal asks for confirmation and names the factory.
