//
//  Regex.swift
//  LightSwordX
//
//  Created by Neko on 1/3/16.
//  Copyright © 2016 Neko. All rights reserved.
//

import Foundation

class Regex {
    let internalExpression: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalExpression = try! NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
    }
    
    func test(input: String) -> Bool {
        let matches = self.internalExpression.matchesInString(input, options: .ReportCompletion, range:NSMakeRange(0, input.length))
        return matches.count > 0
    }
}