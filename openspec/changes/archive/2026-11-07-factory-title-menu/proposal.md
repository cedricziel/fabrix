## Why

The sidebar mixes three levels: factories, their companies, and the company's sections, with "Switch factory" as a row at the bottom. The HIG asks for at most two levels in a sidebar and nothing critical at its bottom on macOS. The sidebar can also be hidden, which hides the only way to switch. The HIG's place for whole-context commands is the toolbar's leading edge: the title plus a title menu, with a matching menu-bar command for every toolbar item.

## What Changes

- The sidebar shows only the current company's sections (Overview, Tasks, Agents, Org chart, Approvals, Activity). The factory and company rows and "Switch factory" go away.
- The navigation title shows the current company, with its factory as subtitle where it fits. Its title menu lists the saved factories, the current factory's companies with a checkmark on the current one, and the demo. Then "Add Factory…" opens the connect form, and "Remove Factory…" asks for confirmation, deletes the factory and its credentials, and opens the next saved factory or onboarding.
- macOS gets a Factory menu in the menu bar with the same commands, and Cmd-1 to Cmd-9 for the current factory's companies.
- iPhone and iPad get the same title menu. iPhone keeps its tab bar.
- "Forget Factory…" from the factory row's context menu and the More menu is replaced by "Remove Factory…".

Platforms: macOS, iPadOS and iOS. Targets: FabrixFeatures and `App/Shared`. `FactoryService` is unchanged; `FactoryConnector` gains a list of saved factories.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `navigation`: where factories and companies are switched, and what the sidebar holds.
- `onboarding`: leaving or removing a factory, and adding one while another is open.

## Impact

- `FabrixFeatures`: new `FactoryMenu` model and title-menu view, `FactoryCommands` for the menu bar, an Add Factory sheet reusing the connect form; `AppModel` switches and removes factories.
- `App/Shared/FabrixApp.swift`: adds `FactoryCommands`.
