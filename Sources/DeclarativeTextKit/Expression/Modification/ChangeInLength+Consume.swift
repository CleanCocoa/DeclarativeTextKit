//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension SelectedRange {
    func consume(changeInLength: inout ChangeInLength) {
        self.value.length += changeInLength.consumed()
    }
}

extension ChangeInLength {
    /// Applies all `.unappliedToSelection` elements in `changeInLength` and transforms them to `.appliedToSelection` in the process so they won't be applied again later.
    ///
    /// - Returns: Delta of all partial changes in length that were previously unapplied. 0 otherwise.
    fileprivate mutating func consumed() -> Delta {
        var result = 0
        for case let (index, .unappliedToSelection(delta)) in zip(elements.indices, elements) {
            result += delta
            elements[index] = .appliedToSelection(delta)
        }
        return result
    }
}
