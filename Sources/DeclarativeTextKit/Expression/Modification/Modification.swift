//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public enum ModificationFailure: Error {
    case wrapped(Error)
    case outOfRange(requested: Buffer.Range, selected: Buffer.Range)
}

public protocol Modification: Expression
where Evaluation == ChangeInLength, Failure == ModificationFailure {

}
