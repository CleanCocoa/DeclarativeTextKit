//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// > Note: You don't create ``CommandSequence``s manually, you use `@CommandSequenceBuilder` blocks instead.
public struct CommandSequence: Command {
    public let commands: [Command]

    init(_ commands: [Command]) {
        self.commands = commands
    }

    public func callAsFunction(buffer: Buffer) {
        for command in commands {
            command.callAsFunction(buffer: buffer)
        }
    }
}

@resultBuilder
public struct CommandSequenceBuilder {
    public static func buildBlock(_ components: Command...) -> CommandSequence {
        CommandSequence(components)
    }
}
