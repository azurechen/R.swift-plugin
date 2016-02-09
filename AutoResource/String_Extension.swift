//
//  String_Extension.swift
//  AutoResource
//
//  Created by Azure Chen on 2/9/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import Foundation

extension String {
    mutating func insert(string: String, atIndex index: Index) {
        self = self.substringToIndex(index) + string + self.substringFromIndex(index)
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
}