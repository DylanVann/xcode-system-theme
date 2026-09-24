import CoreGraphics
import Foundation
let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "ALL"
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list {
    let o = w[kCGWindowOwnerName as String] as? String ?? ""
    if owner != "ALL" && o != owner { continue }
    let title = w[kCGWindowName as String] as? String ?? ""
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    if layer != 0 { continue }
    print(w[kCGWindowNumber as String] as! Int, "|", o, "|", title, "|", b["Width"] ?? 0, "x", b["Height"] ?? 0)
}
