import CoreGraphics
import Foundation
// Lists on-screen windows at every layer: id | owner | title | x y w h | layer
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list {
    let o = w[kCGWindowOwnerName as String] as? String ?? ""
    let t = w[kCGWindowName as String] as? String ?? ""
    let l = w[kCGWindowLayer as String] as? Int ?? 0
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    print(w[kCGWindowNumber as String] as! Int, "|", o, "|", t, "|", b["X"] ?? 0, b["Y"] ?? 0, b["Width"] ?? 0, b["Height"] ?? 0, "|", l)
}
