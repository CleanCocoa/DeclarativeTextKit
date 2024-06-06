//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

/// Shoveling-operator for dictionary concatenation or merging.
fileprivate func << <Key, Value>(
    lhs: inout [Key: Value],
    rhs: [Key: Value]
) {
    lhs = lhs.merging(rhs) { _, rhs in
        rhs
    }
}

final class BufferWordRangeTests: XCTestCase {
    func twoWords(separatedBy separator: Character) -> [String : String] {
        return [
            "start word\(separator)word{^} end" : "start word\(separator){word} end",
            "start word\(separator){^}word end" : "start word\(separator){word} end",
            "start word\(separator){word} end"  : "start word\(separator){word} end",
            "start word{^}\(separator)word end" : "start {word}\(separator)word end",
            "start {word}\(separator)word end"  : "start {word}\(separator)word end",
            "start wo{rd\(separator)wo}rd end"  : "start {word\(separator)word} end",
            "start {word\(separator)word} end"  : "start {word\(separator)word} end",
        ]
    }

    func word(punctuatedBy char: Character) -> [String : String] {
        return word(punctuatedBy: char, char)
    }

    func word(punctuatedBy lhs: Character, _ rhs: Character) -> [String : String] {
        var samples: [String : String] = [:]

        func addPair(_ lhs: Character, _ rhs: Character) {
            samples << [
                "a punc\(lhs)tu{^}at\(rhs)ion z" : "a punc\(lhs){tuat}\(rhs)ion z",
                "a punc\(lhs)t{ua}t\(rhs)ion z"  : "a punc\(lhs){tuat}\(rhs)ion z",
                "a punc\(lhs){tuat}\(rhs)ion z"  : "a punc\(lhs){tuat}\(rhs)ion z",
            ]
        }

        addPair(lhs, rhs)
        addPair(" ", rhs)
        addPair(lhs, " ")

        return samples
    }

    func sanitized(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// MARK: -

extension BufferWordRangeTests {
    func testWordRange_ValidCases() throws {
        var samples: [String : String] = [:]
        samples << [ // Empty buffer maintains selection
            "{^}"                  : "{^}",
            "  {^}  "              : "  {^}  ",
            " \n\t {^} \n\t "      : " \n\t {^} \n\t ",
            " \n\t { \t\n } \n\t " : " \n\t { \t\n } \n\t ",
        ]
        samples << [ // Direct selection of adjacent, sole non-boundary character
            "a{^}"    : "{a}",
            "{a}"     : "{a}",
            "foo{^}"  : "{foo}",
            "{foo}"   : "{foo}",
            "{^}foo"  : "{foo}",
            "你{^}"    : "{你}",
            "你好{^}"  : "{你好}",
        ]
        samples << [ // Skipping whitespace to find next word forward
            "{^}  \n\t\r  foo  " : "  \n\t\r  {foo}  ",
            "  \n\t\r  foo  {^}" : "  \n\t\r  {foo}  ",
            "foo {^} \n\t bar"   : "foo  \n\t {bar}",
            "你  {^}  好"         : "你    {好}",
        ]
        samples << [ // Trim whitespace from selection
            "  {   foo   }  "           : "     {foo}     ",
            " foo  {  bar  }  baz  "    : " foo    {bar}    baz  ",
            " foo  {  bar !  }  baz  "  : " foo    {bar !}    baz  ",
            " foo  {  ba rr  }  baz  "  : " foo    {ba rr}    baz  ",
            " fo{o    ba rr  }  baz  "  : " {foo    ba rr}    baz  ",
        ]
        samples << [ // Selecting symbols, too, if that's all there is adjacent to insertion point
            "?{^}"   : "{?}",
            "{^}?"   : "{?}",
            "{?}"    : "{?}",
            "a!{^}"  : "{a!}",
            "a{!}"   : "{a!}",
            "{^},b"  : "{,b}",
            "{,}b"   : "{,b}",
        ]
        samples << [
            "{^}(foo bar)" : "{(foo} bar)",
            "{^}(foo) bar" : "{(foo)} bar",
            "(foo){^} bar" : "{(foo)} bar",
            "(foo bar){^}" : "(foo {bar)}",
            "foo (bar){^}" : "foo {(bar)}",
        ]
        samples << [
            "⭐️{^}"       : "{⭐️}",
            "⭐️ ⭐️{^}"    : "⭐️ {⭐️}",
            "⭐️ {⭐️}"     : "⭐️ {⭐️}",
            // This is actually a skin-color changed female head, but Xcode renders this as a male head with female modifier
            "👴🏻 👱🏾‍♀️{^}" : "👴🏻 {👱🏾‍♀️}",
            "👴🏻 {👱🏾‍♀️}" : "👴🏻 {👱🏾‍♀️}",
        ]
        samples << twoWords(separatedBy: " ")
        samples << twoWords(separatedBy: "　") // IDEOGRAPHIC SPACE
        samples << twoWords(separatedBy: "\t")
        samples << twoWords(separatedBy: "\n")
        samples << twoWords(separatedBy: "\r")
        samples << twoWords(separatedBy: "\r\n")
        samples << word(punctuatedBy: #"("#, #")"#)
        samples << word(punctuatedBy: #"["#, #"]"#)
        samples << word(punctuatedBy: #"〔"#, #"〕"#)
        samples << word(punctuatedBy: #"《"#, #"》"#)
        samples << word(punctuatedBy: #"."#)
        samples << word(punctuatedBy: #","#)
        samples << word(punctuatedBy: #"、"#) // IDEOGRAPHIC COMMA
        samples << word(punctuatedBy: #"。"#) // IDEOGRAPHIC PERIOD
        samples << word(punctuatedBy: #"､"#) // HALFWIDTH IDEOGRAPHIC COMMA
        samples << word(punctuatedBy: #"｡"#) // HALFWIDTH IDEOGRAPHIC PERIOD
        samples << word(punctuatedBy: #"¿"#, #"?"#)
        samples << word(punctuatedBy: #"¡"#, #"!"#)
        samples << word(punctuatedBy: #"""#)
        samples << word(punctuatedBy: #"'"#)
        samples << word(punctuatedBy: #"“"#, #"”"#)
        samples << word(punctuatedBy: #"‘"#, #"’"#)
        // Symbols
        samples << word(punctuatedBy: #"`"#)
        samples << word(punctuatedBy: #"!"#)
        samples << word(punctuatedBy: #"@"#)
        samples << word(punctuatedBy: #"#"#)
        samples << word(punctuatedBy: #"$"#)
        samples << word(punctuatedBy: #"%"#)
        samples << word(punctuatedBy: #"^"#)
        samples << word(punctuatedBy: #"&"#)
        samples << word(punctuatedBy: #"*"#)
        samples << word(punctuatedBy: #"-"#)
        samples << word(punctuatedBy: #"_"#)
        samples << word(punctuatedBy: #"="#)
        samples << word(punctuatedBy: #"+"#)
        samples << word(punctuatedBy: #"!"#)

        continueAfterFailure = true

        for (input, expectedOutput) in samples {
            let buf = try buffer(input)
            XCTAssertNoThrow(
                buf.select(try buf.wordRange(for: buf.selectedRange)),
                "Given \"\(sanitized(input))\""
            )
            XCTAssertEqual(
                buf.description, expectedOutput,
                "Given \"\(sanitized(input))\""
            )
        }
    }

    func testWordRange_InvalidInputRange() throws {
        let buffer = MutableStringBuffer("Lorem ipsum")
        let expectedAvailableRange = Buffer.Range(location: 0, length: 11)

        let invalidRanges: [Buffer.Range] = [
            .init(location: -1, length: 999),
            .init(location: -1, length: 1),
            .init(location: -1, length: 0),
            .init(location: 11, length: -2),
            .init(location: 11, length: -1),
            .init(location: 1, length: 999),
            .init(location: 11, length: 1),
            .init(location: 12, length: 0),
            .init(location: 100, length: 999),
        ]
        for invalidRange in invalidRanges {
            assertThrows(
                try buffer.wordRange(for: invalidRange),
                error: BufferAccessFailure.outOfRange(
                    requested: invalidRange,
                    available: expectedAvailableRange
                ),
                "Selecting word range in \(invalidRange)"
            )
        }
    }
}

