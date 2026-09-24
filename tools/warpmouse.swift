import CoreGraphics
// Move the mouse pointer to a point in screen coordinates: warpmouse <x> <y>
let x = Double(CommandLine.arguments[1])!, y = Double(CommandLine.arguments[2])!
CGWarpMouseCursorPosition(CGPoint(x: x, y: y))
CGAssociateMouseAndMouseCursorPosition(1)
