//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Represents insertion of text into a ``Buffer``.
///
/// ## Inserting in Multiple Locations at Once
///
/// To insert in multiple locations, you put multiple ``Insert`` commands inside a single ``Modifying`` group that takes care of evaluating the buffer mutations appropriately.
///
/// > Note: Insertions cannot be mixed with ``Delete``; to perform both insertion and deletion in one block, you need to wrap both in ``Modifying`` blocks separately.
///
/// Changes to the modified range inside the block are _declarative_, which means you do not need to take character offsets into account. Instead, you tell the system where changes should go as if the user typed them.
///
/// ```swift
/// // 🔥 New hotness: Surround the selection
/// Modifying(selectedRange) { range in
///     Insert(range.location) { "<<" }
///     Insert(range.endLocation) { ">>" }
/// }
/// ```
///
/// This will wrap `"some text"` in angle brackets as `"<<some text>>"`. In a procedural approach, you would have to compute the actual location of the closing pair manually:
///
/// ```swift
/// // Old and busted: procedural approach
/// let range = textView.selectedRange()
/// textStorage.insert("<<", at: range.location)
/// // +2 offset to take the change from the previous statement into account
/// textStorage.insert(">>", at: range.endLocation + 2)
/// ```
///
/// Or better yet, apply changes from back to front to prevent locations from becoming invalid:
///
/// ```swift
/// // Old and busted: procedural approach in reverse
/// let range = textView.selectedRange()
/// textStorage.insert(">>", at: range.endLocation)
/// textStorage.insert("<<", at: range.location)
/// ```
///
/// This messes with the order in which we humans read, though. The ``Insert`` DSL instead allows you to express multiple changes however you like and do the right thing automatically.
///
/// > Invariant: Multiple insertions in one ``Modifying`` block are combined and applied in reverse order to preserve correct buffer offsets.
///
/// ## Using the Domain-Specific Language for Insert
///
/// The Result Builder ``InsertableBuilder`` that's used in ``Insert/init(_:_:)`` takes care of the grammar.
///
/// This Result Builder-based approach allows you to seamlessly express complex strings to be inserted at any location. The general form is this:
///
/// ```swift
/// Insert(locationInBuffer) {
///     someInsertableContent
///     // ... more insertable Content ...
/// }
/// ```
///
/// ### Inserting Blocks/Paragraphs Anywhere
///
/// The powerful ``Line`` guarantees smartly that the inserted text will be surrounded by `"\n"` newline characters in the buffer, re-using existing line breaks if possible.
///
/// The following will insert a block of text at the insertion point location, starting with a line break if the insertion point is somewhere inside an existing paragraph:
///
/// ```swift
/// Insert(buffer.insertionPointLocation) {
///     Line("# Overview")
///     Line()
///     Line("Here is my overview ...")
/// }
/// ```
///
/// ### Concatenating Strings
///
/// By defaults, multiple strings are concatenated. This allows you to insert parts of a string from literals and variables alike.
///
/// ```swift
/// let prefix = "See also: "
/// let myWebsite = "christiantietze.de"
/// Insert(buffer.insertionPointLocation) {
///     prefix
///     "underplot.com, "
///     "chimehq.com, "
///     myWebsite
/// }
/// ```
///
/// ### Mixing Insertion-at-Point with Block Creation
///
/// Inserting text wherever the insertion point is, followed by separate blocks or paragraphs of text, can be combined in one statement:
///
/// ```swift
/// Insert(buffer.insertionPointLocation) {
///     "[^footnote]"
///     Line()
///     Line("[^footnote]: ")
///     "See christiantietze.de for more Text Kit stuff."
/// }
/// ```
///
/// The ``InsertableBuilder`` grammar  ensures that ``Line``'s guarantees are upheld when concatenating with regular strings left and/or right.
public struct Insert {
    let insertions: () -> SortedArray<TextInsertion>

    init(
        _ insertions: @escaping @autoclosure () -> SortedArray<TextInsertion>
    ) {
        self.insertions = insertions
    }

    public init(
        _ location: @escaping @autoclosure () -> UTF16Offset,
        @InsertableBuilder _ body: @escaping () -> Insertable
    ) {
        self.init(SortedArray(sorted: [
            TextInsertion(at: location(), insertable: body())
        ], areInIncreasingOrder: TextInsertion.arePositionedInIncreasingOrder))
    }
}


struct TextInsertion {
    static func arePositionedInIncreasingOrder (lhs: TextInsertion, rhs: TextInsertion) -> Bool {
        return lhs.location < rhs.location
    }

    let location: UTF16Offset
    let insertable: Insertable

    init(at location: UTF16Offset, insertable: Insertable) {
        self.location = location
        self.insertable = insertable
    }
}
