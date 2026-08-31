import Foundation
import TextBuffer

public protocol NSStringBuffer: Buffer, TextAnalysisCapable where Range == NSRange, Content == String {}

extension MutableStringBuffer: NSStringBuffer {}

#if os(macOS)
extension NSTextViewBuffer: @MainActor NSStringBuffer {}
#endif

extension ScopedBufferSlice: NSStringBuffer where Base: NSStringBuffer {}

extension Undoable: @MainActor NSStringBuffer where Base: NSStringBuffer {}

public typealias UTF16Offset = Int
public typealias UTF16Range = NSRange

public func length(of string: NSString) -> Int {
    return string.length
}

public func length(of string: String) -> Int {
    return (string as NSString).length
}
