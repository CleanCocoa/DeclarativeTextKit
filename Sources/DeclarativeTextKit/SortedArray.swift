//  Copyright © 2024 Christian Tietze
//  Adapted from <https://github.com/ole/SortedArray>
//  Copyright © 2017 Ole Begemann
//  All rights reserved. Distributed under the MIT License.

/// An array that keeps its elements sorted at all times.
struct SortedArray<Element> {
    /// The backing store.
    fileprivate var _elements: [Element]

    typealias Comparator<A> = (A, A) -> Bool

    /// The predicate that determines the array's sort order.
    fileprivate let areInIncreasingOrder: Comparator<Element>

    /// Initializes an empty array.
    ///
    /// - Parameter areInIncreasingOrder: The comparison predicate the array should use to sort its elements.
    init(areInIncreasingOrder: @escaping Comparator<Element>) {
        self._elements = []
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    /// Initializes the array with a sequence of unsorted elements and a comparison predicate.
    init<S: Sequence>(
        unsorted: S,
        areInIncreasingOrder: @escaping Comparator<Element>
    ) where S.Element == Element {
        let sorted = unsorted.sorted(by: areInIncreasingOrder)
        self._elements = sorted
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    /// Initializes the array with a sequence that is already sorted according to the given comparison predicate.
    ///
    /// This is faster than `init(unsorted:areInIncreasingOrder:)` because the elements don't have to sorted again.
    ///
    /// - Precondition: `sorted` is sorted according to the given comparison predicate. If you violate this condition, the behavior is undefined.
    init<S: Sequence>(
        sorted: S,
        areInIncreasingOrder: @escaping Comparator<Element>
    ) where S.Element == Element {
        self._elements = Array(sorted)
        self.areInIncreasingOrder = areInIncreasingOrder
    }
}

// MARK: - Swift.Comparable-conforming Elements

extension SortedArray where Element: Comparable {
    /// Initializes an empty sorted array. Uses `<` as the comparison predicate.
    init() {
        self.init(areInIncreasingOrder: <)
    }

    /// Initializes the array with a sequence of unsorted elements. Uses `<` as the comparison predicate.
    init<S: Sequence>(unsorted: S) where S.Element == Element {
        self.init(unsorted: unsorted, areInIncreasingOrder: <)
    }

    /// Initializes the array with a sequence that is already sorted according to the `<` comparison predicate. Uses `<` as the comparison predicate.
    ///
    /// This is faster than `init(unsorted:)` because the elements don't have to sorted again.
    ///
    /// - Precondition: `sorted` is sorted according to the `<` predicate. If you violate this condition, the behavior is undefined.
    init<S: Sequence>(sorted: S) where S.Element == Element {
        self.init(sorted: sorted, areInIncreasingOrder: <)
    }
}

extension SortedArray: RandomAccessCollection {
    typealias Index = Int

    var startIndex: Index { return _elements.startIndex }
    var endIndex: Index { return _elements.endIndex }

    func index(after i: Index) -> Index {
        return _elements.index(after: i)
    }

    func index(before i: Index) -> Index {
        return _elements.index(before: i)
    }

    subscript(position: Index) -> Element {
        return _elements[position]
    }
}

extension SortedArray: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        return "\(String(describing: _elements)) (sorted)"
    }

    var debugDescription: String {
        return "<SortedArray> \(String(reflecting: _elements))"
    }
}

extension SortedArray: Equatable where Element: Equatable {
    static func == (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
        // Ignore the comparator function for Equatable
        return lhs._elements == rhs._elements
    }
}

extension SortedArray: Hashable where Element: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(_elements)
    }
}
