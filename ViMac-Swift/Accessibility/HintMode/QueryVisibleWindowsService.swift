import Cocoa
import AXSwift

struct WindowInfo {
    let pid: pid_t
    let frame: NSRect
    let layer: Int
    let rawInfo: [String: AnyObject]
}

struct Window {
    let cg: WindowInfo
    let ax: Element
}

class QueryVisibleWindowsService {
    func perform() throws -> [Window] {
        let cgWindows = fetchCgWindows()
                            // remove menu bar items
                            .filter { $0.frame.height > 50 }
                            // remove floating windows
                            .filter { $0.layer == 0 }
        let cgWindowClusters = clusterCgWindows(windows: cgWindows)
        // those at the top of their clusters are fully visible
        let visibleCgWindows = cgWindowClusters.map({ $0.first }).compactMap({ $0 })
        
        // associate cgwindows with the best guess of their equivalent ax element because focus action can be performed on ax elements
        var visibleWindows: [Window] = []
        var axWindowsByPid = fetchAxWindowsByPid()
        for cgWindow in visibleCgWindows {
            guard let axWindows = axWindowsByPid[cgWindow.pid] else { continue }
            guard let matchingAxWindowIndex = axWindows.firstIndex(where: { $0.frame == cgWindow.frame }) else { continue }
            
            print("cgWindow: \(cgWindow)")
            print("axWindow: \(axWindows[matchingAxWindowIndex])")
            
            visibleWindows.append(
                .init(cg: cgWindow, ax: axWindows[matchingAxWindowIndex])
            )

            axWindowsByPid[cgWindow.pid]!.remove(at: matchingAxWindowIndex)
        }

        return topOfClusterWindows
    }
    
    // fetches all windows
    // windows are ordered from top to bottom
    private func fetchCgWindows() -> [WindowInfo] {
        let windowInfosRef = CGWindowListCopyWindowInfo(
            CGWindowListOption(rawValue:
                CGWindowListOption.optionOnScreenOnly.rawValue | CGWindowListOption.excludeDesktopElements.rawValue
            ),
            kCGNullWindowID
        )
        
        var windowInfos: [WindowInfo] = []
        for i in 0..<CFArrayGetCount(windowInfosRef) {
            let lineUnsafePointer: UnsafeRawPointer = CFArrayGetValueAtIndex(windowInfosRef, i)
            let lineRef = unsafeBitCast(lineUnsafePointer, to: CFDictionary.self)
            let dict = lineRef as [NSObject: AnyObject]

            guard let item = dict as? [String: AnyObject] else {
                continue
            }
            
            if let x = item["kCGWindowBounds"]?["X"] as? Int,
                let y = item["kCGWindowBounds"]?["Y"] as? Int,
                let width = item["kCGWindowBounds"]?["Width"] as? Int,
                let height = item["kCGWindowBounds"]?["Height"] as? Int,
                let pid = item["kCGWindowOwnerPID"] as? pid_t,
                let layer = item["kCGWindowLayer"] as? Int {
                let frame = NSRect(x: x, y: y, width: width, height: height)
                windowInfos.append(
                    .init(pid: pid, frame: frame, layer: layer, rawInfo: item)
                )
            }
        }
        return windowInfos
    }
    
    // groups windows into clusters of intersecting windows
    // windows of the same cluster are in same order as in the original window array input
    private func clusterCgWindows(windows: [WindowInfo]) -> [[WindowInfo]] {
        var windowInfosClusters: [[WindowInfo]] = []
        for windowInfo in windows {
            let clusterIndex = windowInfosClusters.firstIndex(where: { cluster in
                return cluster.contains(where: { clusterWindow in
                    clusterWindow.frame.intersects(windowInfo.frame)
                })
            })
            
            if let clusterIndex = clusterIndex {
                windowInfosClusters[clusterIndex].append(windowInfo)
            } else {
                let cluster = [windowInfo]
                windowInfosClusters.append(cluster)
            }
        }
        return windowInfosClusters
    }
    
    // fun fact, focusedWindow need not return "AXWindow"...
    private func fetchFocusedWindow() -> Element? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let axAppOptional = Application.init(app)
        guard let axApp = axAppOptional else { return nil }
        
        let axWindowOptional: UIElement? = try? axApp.attribute(.focusedWindow)
        guard let axWindow = axWindowOptional else { return nil }
        
        return Element.initialize(rawElement: axWindow.element)
    }
    
    // ax windows are of the same pid are in descending order
    private func fetchAxWindowsByPid() -> [pid_t : [Element]] {
        let apps = NSWorkspace.shared.runningApplications
        var axWindowsByPid: [pid_t : [Element]] = [:]
        
        for app in apps {
            if let axApp = Application(forProcessID: app.processIdentifier) {
                if let axWindows = try? axApp.windows() {
                    let elements = axWindows
                        .map({ $0.element })
                        .map({ Element.initialize(rawElement: $0) })
                        .compactMap({ $0 })
                    axWindowsByPid[app.processIdentifier] = elements
                }
            }
        }
        
        return axWindowsByPid
    }
}
