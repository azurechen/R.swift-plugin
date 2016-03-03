//
//  String_Extension.swift
//  Rauto
//
//  Created by Azure Chen on 2/9/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import Foundation

extension String {
    mutating func insert(string: String, atIndex index: Index) {
        self = self.substringToIndex(index) + string + self.substringFromIndex(index)
    }
    
    func rangeFromNSRange(nsRange: NSRange) -> Range<String.Index>? {
        if let range = nsRange.toRange() {
            let startIndex = self.startIndex.advancedBy(range.startIndex)
            let endIndex = startIndex.advancedBy(range.endIndex - range.startIndex)
            return Range<String.Index>(start: startIndex, end: endIndex)
        }
        return nil
    }
    
    static func readFile(path: String) -> String? {
        do {
            let content = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            return content as String
        } catch {
            return nil
        }
    }
    
    func writeToFile(path: String) {
        do {
            try self.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
        }
    }
    
    func match(pattern: String) -> Bool {
        let range = self.rangeOfString(pattern, options: .RegularExpressionSearch)
        return range?.startIndex == self.startIndex && range?.endIndex == self.endIndex
    }
    
    func matches(pattern: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
            return regex.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        } catch {
            return []
        }
    }
}