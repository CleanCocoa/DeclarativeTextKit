//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

public protocol Modification: Expression
where Evaluation == ChangeInLength, Failure == BufferAccessFailure {

}
