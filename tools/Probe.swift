import Foundation
import Observation
import SwiftUI

// plain comment
/// Doc comment with `inline code`, **strong**, *emphasis*, and a link: https://example.com/path
/// - Parameter value: a parameter
// MARK: - Section mark
// TODO: todo mark
// FIXME: fixme mark
// https://example.com/bare/url/in/comment

#if DEBUG
let preprocessorLine = 1
#endif
#warning("compile time warning")

let globalConstant = 12345
var globalVariable = 3.14159
let stringLiteral = "string literal \(globalConstant) with interpolation"
let multiLine = """
    multi line
    """
let characterLiteral: Character = "c"
let boolLiteral = true
let nilLiteral: Int? = nil

struct DeclaredType {
    var storedProperty = 0
    let storedConstant = "x"
    static let staticConstant = 1
    func declaredMethod(parameterLabel argumentName: Int) -> Int { argumentName + storedProperty }
    subscript(index: Int) -> Int { index }
    init() {}
}

enum DeclaredEnum { case first, second(Int) }
protocol DeclaredProtocol { func requirement() }
typealias DeclaredAlias = DeclaredType
extension DeclaredType: DeclaredProtocol { func requirement() {} }

func declaredFunction(_ parameter: DeclaredType) -> DeclaredType {
    let localConstant = parameter.storedProperty
    var localVariable = localConstant
    localVariable += globalConstant
    let instance = DeclaredType()
    _ = instance.declaredMethod(parameterLabel: localVariable)
    _ = instance[0]
    _ = DeclaredEnum.first
    _ = DeclaredEnum.second(2)
    _ = DeclaredAlias()
    _ = globalVariable
    _ = declaredFunction
    let systemTypes: (String, Int, Double, Date, URL, Array<Int>, NSObject) = ("", 0, 0, Date(), URL(fileURLWithPath: "/"), [], NSObject())
    _ = systemTypes
    print(max(1, 2), min(3, 4), abs(-5), String(describing: 6), Date.now, Int.max, Double.pi)
    _ = Notification.Name.NSCalendarDayChanged
    _ = FileManager.default.currentDirectoryPath
    _ = "".count + "".uppercased().count
    return instance
}

@MainActor @objc @inlinable @frozen @usableFromInline @discardableResult
@available(macOS 14, *)
func attributed(@ViewBuilder content: () -> some View) -> some View { content() }

@Observable final class ObservedModel { var value = 0 }
@propertyWrapper struct Wrapped { var wrappedValue = 0 }
struct UsesWrapper { @Wrapped var wrapped; @State private var state = 0 }

#Preview { Text("preview") }
#expect(true)
