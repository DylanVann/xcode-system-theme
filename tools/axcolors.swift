import AppKit
import ApplicationServices

func attr(_ e: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?; AXUIElementCopyAttributeValue(e, name as CFString, &v); return v
}
func children(_ e: AXUIElement) -> [AXUIElement] { (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] }
func findTextAreas(_ e: AXUIElement, depth: Int = 0, out: inout [AXUIElement]) {
    if depth > 40 { return }
    if let r = attr(e, kAXRoleAttribute) as? String, r == "AXTextArea" { out.append(e) }
    for c in children(e) { findTextAreas(c, depth: depth + 1, out: &out) }
}
func hex(_ c: NSColor) -> String {
    guard let s = c.usingColorSpace(.sRGB) else { return "?" }
    let space = c.colorSpace.localizedName ?? "\(c.colorSpace)"
    var raw = ""
    if c.numberOfComponents >= 3 { var comps = [CGFloat](repeating: 0, count: c.numberOfComponents); c.getComponents(&comps); raw = " raw=[" + comps.prefix(3).map { String(format: "%.4f", $0) }.joined(separator: ",") + "] space=" + space }
    return String(format: "#%02x%02x%02x a=%.2f", Int((s.redComponent*255).rounded()), Int((s.greenComponent*255).rounded()), Int((s.blueComponent*255).rounded()), s.alphaComponent) + raw
}
let windowName = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Probe2.swift"
guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode").first else { print("no xcode"); exit(1) }
let axApp = AXUIElementCreateApplication(app.processIdentifier)
guard let windows = attr(axApp, kAXWindowsAttribute) as? [AXUIElement] else { print("no windows (accessibility permission?)"); exit(1) }
var target: AXUIElement?
for w in windows { if let t = attr(w, kAXTitleAttribute) as? String, t.contains(windowName) { target = w } }
guard let win = target else { print("window not found; titles:", windows.compactMap { attr($0, kAXTitleAttribute) as? String }); exit(1) }
var areas: [AXUIElement] = []; findTextAreas(win, out: &areas)
print("text areas:", areas.count)
for (i, ta) in areas.enumerated() {
    let n = (attr(ta, kAXNumberOfCharactersAttribute) as? Int) ?? 0
    if n < 50 { continue }
    print("== area \(i) chars \(n) desc:", attr(ta, kAXDescriptionAttribute) as? String ?? "", attr(ta, kAXRoleDescriptionAttribute) as? String ?? "")
    var range = CFRange(location: 0, length: n)
    guard let rv = AXValueCreate(.cfRange, &range) else { continue }
    var out: AnyObject?
    let err = AXUIElementCopyParameterizedAttributeValue(ta, kAXAttributedStringForRangeParameterizedAttribute as CFString, rv, &out)
    guard err == .success, let s = out as? NSAttributedString else { print("  attributed string error", err.rawValue); continue }
    var seen: [String: Set<String>] = [:]
    s.enumerateAttributes(in: NSRange(location: 0, length: s.length)) { attrs, r, _ in
        let text = (s.string as NSString).substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }
        var fg = "none"; var bg = ""
        for (k, v) in attrs {
            let key = k.rawValue
            if key.lowercased().contains("foreground") {
                if let c = v as? NSColor { fg = hex(c) } else if CFGetTypeID(v as CFTypeRef) == CGColor.typeID, let c = NSColor(cgColor: v as! CGColor) { fg = hex(c) } else { fg = "\(v)" }
            }
            if key.lowercased().contains("background") {
                if let c = v as? NSColor { bg = hex(c) } else if CFGetTypeID(v as CFTypeRef) == CGColor.typeID, let c = NSColor(cgColor: v as! CGColor) { bg = hex(c) }
            }
        }
        let key = fg + (bg.isEmpty ? "" : " bg=" + bg)
        seen[key, default: []].insert(String(text.prefix(24)))
    }
    if seen.isEmpty { print("  attribute keys sample:", s.length > 0 ? s.attributes(at: 0, effectiveRange: nil).keys.map { $0.rawValue } : []) }
    for (k, v) in seen.sorted(by: { $0.key < $1.key }) { print("  \(k)  <- \(v.sorted().prefix(60).joined(separator: " | "))") }
}
