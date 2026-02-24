import TextBuffer

#if os(macOS)
extension NSTextViewBuffer: @MainActor ModifiableBuffer { }
#endif
extension MutableStringBuffer: ModifiableBuffer { }
