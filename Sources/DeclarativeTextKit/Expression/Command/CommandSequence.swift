//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct CommandSequenceFailure: Error {
    public let wrapped: Error
}

/// > Note: You don't create ``CommandSequence``s manually, you use `@CommandSequenceBuilder` blocks instead.
public struct CommandSequence {
    public let commands: [Command]

    init(_ commands: [Command]) {
        self.commands = commands
    }
}

extension CommandSequence: Expression {
    public func evaluate(in buffer: Buffer) -> Result<Void, CommandSequenceFailure> {
        do {
            for command in commands {
                try command.evaluate(in: buffer)
            }
            return .success(())
        } catch {
            return .failure(CommandSequenceFailure(wrapped: error))
        }
    }
}

public protocol CommandConvertible: Expression { }
extension Modifying: CommandConvertible where Content: Expression { }
extension Select: CommandConvertible { }
extension Noop: CommandConvertible { }

@resultBuilder
public struct CommandSequenceBuilder {
    public static func buildPartialBlock(first: Command) -> CommandSequence {
        return CommandSequence([first])
    }

    public static func buildPartialBlock(first: some CommandConvertible) -> CommandSequence {
        return CommandSequence([Command(wrapped: first)])
    }

    public static func buildPartialBlock(
        accumulated: CommandSequence,
        next: some CommandConvertible
    ) -> CommandSequence {
        return CommandSequence(
            accumulated.commands + [Command(wrapped: next)]
        )
    }

    public static func buildPartialBlock(
        accumulated: CommandSequence,
        next: Command
    ) -> CommandSequence {
        return CommandSequence(
            accumulated.commands + [next]
        )
    }
}
