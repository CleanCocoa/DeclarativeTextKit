//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified in a range.
///
/// Depending on the concrete ``Buffer`` you use, the execution of commands can support undoing/redoing of operations (see ``Undoable-struct``), or AppKit/UIKit compatible delegate calls that can prevent changes within the range (see ``NSTextViewBuffer``), or both when you combine the buffers.
///
/// You use ``Modifying`` to combine and group either
/// - multiple ``Modification``s  like ``Insert`` and ``Delete`` at multiple locations into one block,
/// - or non-modifying effects like a ``Select`` command and nested ``Modifying`` blocks within a larger scope.
///
/// The Domain-Specific Language's grammar is enforced by the Result Builder, so you can't accidentally mix incompatible modifications.
///
/// ## Examples
///
/// ### Modifying a buffer in multiple locations at once
/// To surround the selected range in a Markdown text buffer with two asterisks, `**`, to make the selected text bold:
///
/// ```swift
/// Modifying(selectedRange) { modifiableRange in
///     Insert(modifiableRange.location) { "**" }
///     Insert(modifiableRange.endLocation) { "**" }
/// }
/// ```
///
/// ### Grouping multiple effects, e.g. as an undo group
/// To group multiple effects into one undo group if you :
///
/// ```swift
/// // Assuming `buffer` is of type `Undoable`
/// Modifying(buffer.range) { fullRange in
///     // This modification block updates `fullRange`
///     // to reflect the changes inside:
///     Modifying(fullRange) { editedRange in
///         Delete(
///             location: editedRange.location,
///             length: editedRange.length / 2
///         )
///     }
///
///     // Put insertion point at the end of the text
///     // as it looks after the previous modification:
///     Select(fullRange.endLocation)
/// }
/// ```
public struct Modifying<Content> {
    public typealias ModificationBody = (SelectedRange) -> Content

    let range: SelectedRange
    let modification: ModificationBody
}

extension Modifying: Modification, Expression
where Content: Modification {
    @_disfavoredOverload  // For client code, favor the throwing alternative available from the protocol extension.
    public func evaluate(in buffer: Buffer) -> Result<Content.Evaluation, BufferAccessFailure> {
        return _evaluate(in: buffer)
    }

    private func _evaluate<B: Buffer>(in buffer: B) -> Result<Content.Evaluation, BufferAccessFailure> {
        do {
            let scopedBuffer = try ScopedBufferSlice(base: buffer, scopedRange: range.value)

            return try scopedBuffer.modifyingScope {
                switch modification(range).evaluate(in: scopedBuffer) {
                case .success(var changeInLength):
                    range.consume(changeInLength: &changeInLength)
                    return .success(changeInLength)
                case .failure(let error):
                    return .failure(.wrap(error))
                }
            }
        } catch {
            return .failure(.wrap(error))
        }
    }

    public init(
        _ range: SelectedRange,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.range = range
        self.modification = body
    }
}
