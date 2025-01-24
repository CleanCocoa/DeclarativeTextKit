//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Undoable where Base == NSTextViewBuffer {
    /// Wraps `base` to support automatic undo/redo of buffer mutations with the default undo manager of the `NSTextView`.
    ///
    /// `NSTextView`s delegate up the responder chain to get to their undo manager, which usually returns the undo manager from their enclosing `NSWindow` or `NSDocument`.
    ///
    /// This behavior can be tweaked by setting the `undoManager` on the enclosing document directly, or by implementing  [`NSWindowDelegate.windowWillReturnUndoManager(_:)`](https://developer.apple.com/documentation/appkit/nswindowdelegate/1419745-windowwillreturnundomanager) to return `UndoManager` instances you manage yourself.
    public convenience init(
        _ base: NSTextViewBuffer
    ) {
        self.init(base) {
            return base.textView.undoManager
        }
    }
}

extension NSTextViewBuffer {
    /// Buffer with the system's default undo/redo support (which is usually delegating to the `NSWindow` or `NSDocument`).
    public var undoable: Undoable<NSTextViewBuffer> { Undoable(self) }
}
