extension AppLock {
    /// Whether one scene's cover window shows. A deactivating scene covers itself at once,
    /// before SwiftUI updates; a reactivating scene follows the app-wide state, so an iPad
    /// window that comes back while another kept the app active doesn't stay covered.
    func shieldsScene(isActive: Bool) -> Bool {
        isActive ? isCovered : settings.isEnabled && !isAuthenticating
    }
}
