# ``DeclarativeTextKit``

A Swift DSL to express complex modifications to text buffers in a simple, declarative way.

## Overview

Performing changes on text views from the system frameworks, like `NSTextView` and `UITextView`, require error-prone, procedural code.

For example, to mutate a text view in multiple locations can be an annoying task: you need to apply changes from back to front, otherwise a deletion/insertion at the front will invalidate all upcoming string indices. This means you need to separate how you  express your intended changes from how they are applied to the text view, making your code longer and more noisy in the process.

`DeclarativeTextView` takes care of all this under the hood so you can focus on expressing what you want the change to look like.

### Example of a complex, undoable change

The following code snippet will

1. expand the user's selection to full lines,
2. wrap the selected lines of text in GitHub-flavored Markdown fenced code blocks,
3. then put the insertion point after the opening triple backticks:

```swift
buffer.evaluate {
    // Expand selection to the whole block (full lines).
    Select(LineRange(selectedRange)) { lineRange in
        // In that range, attempt to wrap the selected text
        // in two lines to make it a code block.
        // (Abort if the text view doesn't permit changes.)
        Modifying(lineRange) { rangeToWrap in
            // Insert triple backticks on isolated lines, in
            // a "Do What I Mean" (DWIM) style: it does the
            // right thing, preserving and reusing existing
            // line breaks if possible, adding new "\n" line
            // breaks as needed to keep its guarantee.
            Insert(rangeToWrap.location) { Line("```") }
            Insert(rangeToWrap.endLocation) { Line("```") }
        }

        // Move insertion point to the
        // position after the opening backticks
        Select(lineRange.location + length(of: "```"))
    }
}
```

If the affected text buffer supports undo/redo (like the default text views do), the block will be undoable as a single action.

## Topics

### Buffers

A `Buffer` is an abstraction of textual content and a selection. Its ``Buffer/evaluate(_:)-7jmtt`` is the simplest entry point to the DSL.

- ``Buffer``
- ``InMemoryBuffer``
- ``MutableStringBuffer``
- ``Undoable``

### Platform-Specific Buffer Adapters

Text Kit's text views behave as buffers, but offer a much wider surface API to perform layout and typesetting. Opposed to these, a `Buffer` is a lightweight API to perform changes like a user would in an interactive text view, which we expose as adapters.

- ``NSTextViewBuffer``

### Buffer Mutations in the Domain-Specific Language

`Modifying`: Groups multiple mutations as one change.

- ``Modifying-struct``
- ``Insert-struct``
- ``Delete-struct``

### Non-Mutating Side Effects in the Domain-Specific Language

- ``Select-struct``

### Semantic Selections: Range Finders

"Range finders" are used to expand a buffer's selected range to common semantic units. The are used as parameter for ``Select`` commands. 

- ``WordRange``
- ``LineRange``

### Semantic Insertions

``Insertable``s are used to express expectations about the buffer's resulting state after an insertion.

- ``Line``
- ``Word``
