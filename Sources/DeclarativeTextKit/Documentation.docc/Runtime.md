# Runtime vs Build Time

When mixing the declarative approach of `DeclarativeTextKit` with otherwise procedural app code from `AppKit`/`UIKit`, you'll have to be careful to express values _inside the DSL_ so that they are evaluated properly at 'runtime', i.e. when the block is being run, instead of when the block is assembled via Swift's' Result Builder desugarization.

## What is 'Build Time'?

As a programmer, you'll be familiar with the differenct of 'compile time' or 'build time' vs 'runtime'. With Swift, one of the nice things is that we can lift some checks and invariances into the type system, think `Result<Success, Failure>` or `Optional<Wrapped>`, so that the compiler can verify that we don't misuse a value at 'compile time'.

With a declarative DSL, 'build time' is when the Result Builder block is being run.

This no-op block is absolutely useless, but illustrates the point:

```swift
try buffer.evaluate {
    Identity()
}
```

1. ``/TextBuffer/Buffer/evaluate(_:)-7jmtt`` is called
2. the ``ModificationBuilder``-annotated block is executed:
    1. ``Identity/init()`` is called to create the value,
    2. ``ModificationBuilder/buildPartialBlock(first:)-6xgr4`` is called with the ``Identity`` value as a parameter -- that's the overload that takes a `some ModificationSequence.Element`.
    3. The builder function returns a ``ModificationSequence`` with the ``Identity`` input value as its only element.
3. Finally, the builder result is evaluated in the buffer via ``ModificationSequence/evaluate(in:)``.

Step (2) is the 'build time'.


## What is 'Runtime'?

In the example above, step (3), the call to any ``Modification/evaluate(in:)`` starts the evaluation, including buffer mutations. That's the 'runtime'.

During evaluation or 'runtime', ``AffectedRange`` values will self-update to represent changes to the selection in a buffer.


## A Breaking Example

Imagine that the ``ModificationBuilder`` supports `if` statements via `buildOptional(_:)`.

The `if` statements would be syntactic sugar to express a function call in the Swift Result Builder convention. That is, the boolean expression is evaluated at 'build time' to take the proper path through the result builder.

A quick example that works as intended:

```swift
try buffer.evaluate(in: buffer.range) { fullRange in
    if fullRange.length == 0 { // Buffer is empty
        Modifying(fullRange) { modifiableRange in
            Insert(modifiableRange.location) { "Start here: " }
        }
    }
}
```

Here, `if fullRange.length == 0` is being evaluated by Swift during 'build time' of ``ModificationBuilder`` to

- either ignore the `Modifying` construct if the buffer is not empty,
- or to insert the `Modifying` construct into the result builder's ``ModificationSequence``.

Using the same structure, almost the similar code, in a second step in a sequence like this, you can break intuition:

```swift
try buffer.evaluate(in: buffer.range) { fullRange in
    if fullRange.length == 0 { // Buffer is empty
        Modifying(fullRange) { modifiableRange in
            Insert(modifiableRange.location) { "Start here: " }
        }
    }

    if fullRange.length > 0 { // by now it surely isn't empty anymore?
        Modifying(fullRange) { modifiableRange in
            Insert(modifiableRange.endLocation) { "end here." }
        }
    }
}
```

From other examples, you may be conditioned to expect that `fullRange` automatically updates itself, as ``AffectedRange`` values do.

Drawing from that experience, the `fullRange.length > 0` condition will surely hold, because the first conditional block inserted something into the buffer and adjusted the range, so afterwards the ``AffectedRange/length`` should be `12`, not `0`.

You'd expect an empty buffer to end up with this content:

```
Start here: end here.
```

Thinking about this some more, this is expressing a trivial, a useless condition that always holds: because if the length wasn't `0` initially, consequently it's `> 0`. So it's always `> 0`. You could remove the condition and the result is the same.

And we believe you'd be right to expect that.

That's why we don't support `if` in the Result Builder syntax: Because your expectations will not be met!

Both conditions are checked at 'build time'. So if `fullRange.length == 0`, the Result Builder will insert the first block into the ``ModificationSequence``. But it won't insert the second block into the sequence, because as the second condition is evaluated,  `fullRange.length` is still `0`. It will only change to `12` during 'runtime', when ``Modification/evaluate(in:)`` is executed -- which is *after* the ``ModificationSequence`` has been assembled by the Result Builder.

So your actual result

- given `buffer.content = ""` initially, will produce `"Start here: "`.
- given `buffer.content = "mistakes "` initially, will produce `"mistakes end here."`.


## Solution: Evaluate Declarations Lazily

Where possible, we can delay evaluation of Swift expressions until ``Modification/evaluate(in:)`` is run by wrapping values in closures, which are invisible thanks to `@autoclosure`.

That's how a `Select(fullRange)` will always use the ``AffectedRange/value`` value that is available at 'runtime', not 'build time'.

### Lazy Conditions

To achieve a similar 'runtime' evaluation with conditions, we introduced ``If`` and ``IfLet``. Both delay the evaluation of their respective conditions until the root block's ``Expression/evaluate(in:)-2h76j`` is run:

```swift
// Given an empty buffer,
let buffer = MutableStringBuffer(content: "")
// and an optional string,
var optionalValue: String? = ...

try buffer.evaluate { fullRange in
    // ... insert the optional string into the buffer, ...
    IfLet (optionalValue) { value in
        Modifying(fullRange) { fullRange in
            Insert(fullRange.location) { value }
        }
    }

    // ... then, iff it was inserted, end with a bang!
    If (fullRange.length > 0) {
        Modifying(fullRange) { fullRange in
            Insert(range.endLocation) { "!" }
        }
    }
}
```

This expresses similar conditions to the `if` example above, but actually does what it looks like it should do.

And this time, you'd be right that the condition is always `true` and the `If`-expression useless! 🎉
