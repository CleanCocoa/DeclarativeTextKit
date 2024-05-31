# Declarative Text Kit

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

A Swift DSL to make modifications to text buffers.

[build status]: https://github.com/CleanCocoa/DeclarativeTextKit/actions
[build status badge]: https://github.com/CleanCocoa/DeclarativeTextKit/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/CleanCocoa/DeclarativeTextKit
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FCleanCocoa%2FDeclarativeTextKit%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/CleanCocoa/DeclarativeTextKit/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue

## Goals

**Express your intent of multiple changes in one swoop.**

We replace procedural code with a declarative DSL for this.

For changes to a text view on the user's behalf with proper undo support, you often need to

1. modify the selected range, e.g. to word boundaries,
2. check whether the selected range is modifiable (abort if it isn't),
3. perform changes to the text -- starting from back to front to not invalidate indices of upcoming changes,
4. notify the text view that changes have been completed in the range.

If you want to modify a piece of a text in multiple places at once, the index reversal alone makes code harder to understand.


## What This Looks Like

Expand the user's selection to full lines, then wrap the text in GitHub-flavored Markdown fenced code blocks and put the insertion point after the opening triple backticks:

```swift
// Expand selection to the whole block (full lines).
Select(LineRange(selectedRange)) { lineRange in
    // In that range, attempt to wrap the selected text
    // in two lines to make it a code block.
    // (Abort if the text view doesn't permit changes.)
    Modifying(lineRange) { rangeToWrap in
        Insert(rangeToWrap.location) { Line("```") }
        Insert(rangeToWrap.endLocation) { Line("```") }
    }

    // Move insertion point to the
    // position after the opening backticks
    Select(lineRange.location + length(of: "```"))
}
```

[![Documentation][documentation badge blue]][documentation]

[documentation badge blue]: https://img.shields.io/badge/→_Read_the_Extensive_Documentation-0000ff?style=for-the-badge

## Approach

We operate on the abstraction of a `Buffer` to perform changes.

This enables usage of the declarative API on multiple buffers at once without having to put the text into a UI component to render.

A `NSTextView` is a buffer. You can use this declarative API to make changes to text views on screen.

You can also use purely in-memory buffers for text mutations of things you don't want to render. This allows you to read multiple files into buffers in your app and use the declarative API to change their contents, while only rendering a single selected file in a text view.


## License

Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

[See the LICENSE file.](./LICENSE)
