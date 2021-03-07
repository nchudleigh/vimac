import Cocoa
import RxSwift

// For performance reasons Chromium only makes the webview accessible when there it detects voiceover through the `AXEnhancedUserInterface` attribute on the Chrome application itself:
// http://dev.chromium.org/developers/design-documents/accessibility
// Similarly, electron uses `AXManualAccessibility`:
// https://electronjs.org/docs/tutorial/accessibility#assistive-technology
class AXEnhancedUserInterfaceActivator {
    static func activate(_ app: NSRunningApplication) {
        activate(AXUIElementCreateApplication(app.processIdentifier))
    }
    
    static func activate(_ app: AXUIElement) {
        _ = setAttribute(app: app, value: true)
    }
    
    static func deactivate(_ app: NSRunningApplication) {
        deactivate(AXUIElementCreateApplication(app.processIdentifier))
    }
    
    static func deactivate(_ app: AXUIElement) {
        _ = setAttribute(app: app, value: false)
    }
    
    static func deactivateAll() {
        let apps = NSWorkspace.shared.runningApplications
        let pids = apps.map { $0.processIdentifier }
        let elements = pids.map { AXUIElementCreateApplication($0) }
        
        for element in elements {
            _ = setAttribute(app: element, value: false)
        }
    }
    
    private static func setAttribute(app: AXUIElement, value: Bool) -> AXError {
        let attribute = "AXEnhancedUserInterface"
        return AXUIElementSetAttributeValue(app, attribute as CFString, value as AnyObject)
    }
}
