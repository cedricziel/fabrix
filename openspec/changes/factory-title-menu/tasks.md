## 1. Switching model (PR 1)

- [x] 1.1 Propose and validate this change
- [ ] 1.2 `FactoryMenu` built from saved factories, open factory, companies and selection (`Logic/FactoryMenu.swift`); tests `FactoryMenuTests`
- [ ] 1.3 `FactoryConnector.factories`, `AppModel` switching and removal with fallback (`Logic/Connecting.swift`, `Logic/StoreConnector.swift`, `AppModel.swift`); tests in `FactorySwitchingTests`

## 2. Title menu (PR 2)

- [ ] 2.1 Sidebar holds only sections; title shows company and factory with the title menu on every layout (`Shell/SplitShell.swift`, `Shell/CompactShell.swift`, `Shell/FactoryTitleMenu.swift`); no test, visual, checked on Mac
- [ ] 2.2 Add Factory sheet reusing the connect form, Remove Factory confirmation (`Screens/OnboardingView.swift`, `RootView.swift`); covered by 1.3 tests
- [ ] 2.3 macOS Factory menu with Command-1…9 (`Shell/FactoryCommands.swift`, `App/Shared/FabrixApp.swift`); no test, checked on Mac
- [ ] 2.4 Archive the change
