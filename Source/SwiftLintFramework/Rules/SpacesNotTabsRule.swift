//
//  SpacesNotTabsRule.swift
//  SwiftLint
//
//  Created by Marc Schwieterman on 11/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension File {
    private func violatingTabRanges() -> [NSRange] {
        return matchPattern(
            "(^[\\t]+)",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct SpacesNotTabsRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)
    private let indentation = 4

    public init() {}

    public static let description = RuleDescription(
        identifier: "spaces_not_tabs",
        name: "Spaces vs Tabs",
        description: "Indentation should use spaces not tabs.",
        nonTriggeringExamples: [
            "func foo() {}",
            "  func foo() {}",
            "    func foo() {}"
        ],
        triggeringExamples: [
            "↓\tfunc foo() {}",
            "↓\t\tfunc foo() {}"
        ],
        corrections: [
            "\tfunc foo() {}": "    func foo() {}",
            "\tfunc foo() {}\n\tfunc bar() {}": "    func foo() {}    func bar() {}",
            "\t\tfunc foo() {}": "        func foo() {}"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingTabRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabledViolatingRanges(
            file.violatingTabRanges(),
            forRule: self
        )
        return writeToFile(file, violatingRanges: violatingRanges)
    }

    private func writeToFile(file: File, violatingRanges: [NSRange]) -> [Correction] {
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reverse() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                let spaces = spacesForLength(violatingRange.length)
                correctedContents = correctedContents
                    .stringByReplacingCharactersInRange(indexRange, withString: spaces)
                adjustedLocations.insert(violatingRange.location, atIndex: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0))
        }
    }

    private func spacesForLength(length: Int) -> String {
        return (0..<(length * indentation)).map { _ in " " }.joinWithSeparator("")
    }
}
