//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Command {
    func callAsFunction(buffer: Buffer)
}
