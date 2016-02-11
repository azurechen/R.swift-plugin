//
//  ResourceGenerator.swift
//  AutoResource
//
//  Created by Azure Chen on 2/11/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

class ResourceGenerator {
    
    let PATTERN_STRINGS = "\"(.*?)\"[\\n\\s]*?=[\\n\\s]*?\"(.*?)\"[\\n\\s]*?;"
    
    var projectPath: String
    var content: String?
    
    init(path: String) {
        self.projectPath = path
    }
    
    func generate() -> String? {
        // 1. read template from the R_template.swift
        initFromTemplate()
        
        if (content != nil) {
            // 2. generate localizable strings
            generateStrings()
        }
        
        return content
    }
    
    private func initFromTemplate() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("R_template", withExtension: "txt")
        content = try? String(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
    }
    
    private func generateStrings() {
        let baseStringFilePath = PluginHelper.baseLocalizableFilePath(atPath: projectPath)
        // read the Localizable.strings file
        if let originalContent = String.readFile(baseStringFilePath) {
            do {
                let regex = try NSRegularExpression(pattern: PATTERN_STRINGS, options: .CaseInsensitive)
                let matches = regex.matchesInString(originalContent, options: [], range: NSMakeRange(0, originalContent.characters.count))
                
                // generate enum members
                var generatedContent = ""
                for match in matches {
                    let rID = (originalContent as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                    generatedContent += "        case \(rID) = \"\(rID)\"\n"
                }
                
                // replace the inner content of enum string
                let regex2 = try NSRegularExpression(pattern: "enum string: String \\{\\n([\\s\\S]*?\\n).*?\\}", options: .CaseInsensitive)
                let range = regex2.matchesInString(content!, options: [], range: NSMakeRange(0, content!.characters.count))[0].rangeAtIndex(1)
                content = (content! as NSString).stringByReplacingCharactersInRange(range, withString: generatedContent)
            } catch {
            }
        }
    }
    
}
