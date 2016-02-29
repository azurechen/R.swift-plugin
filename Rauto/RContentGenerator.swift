//
//  ResourceGenerator.swift
//  Rauto
//
//  Created by Azure Chen on 2/11/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

class RContentGenerator {
    
    let PATTERN_STRINGS = "\"(.*?)\"[\\n\\s]*?=[\\n\\s]*?\"(.*?)\"[\\n\\s]*?;"
    
    var project: (path: String, name: String)
    var content: String?
    
    init(project: (path: String, name: String)) {
        self.project = project
    }
    
    func generate() -> String? {
        // 1. read template from the R_template.swift
        initFromTemplate()
        
        if (content != nil) {
            // 2. generate colors
            generateColors()
            // 3. generate images
            generateImages()
            // 4. generate localizable strings
            generateStrings()
        }
        
        return content
    }
    
    private func initFromTemplate() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("R_template", withExtension: "txt")
        content = try? String(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
        content? += "\n\n//  \(NSDate())" // for debug
    }
    
    private func generateColors() {
        let colorFilePaths = PluginHelper.colorFilePaths(inProject: project)
        
        // generate enum members
        var generatedContent = ""
        for colorFilePath in colorFilePaths {
            // read the Color.strings file
            if let originalContent = String.readFile(colorFilePath) {
                if let matches = originalContent.matches(PATTERN_STRINGS) {
                    for match in matches {
                        let key = (originalContent as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                        let value = (originalContent as NSString).substringWithRange(match.rangeAtIndex(2)) as String
                        generatedContent += "        case \(key) = \"\(value)\"\n"
                    }
                    // replace members of enum color
                    replaceEnumMembers("color: String", members: generatedContent)
                }
            }
        }
    }
    
    private func generateImages() {
        let imageDirPaths = PluginHelper.imageDirPaths(inProject: project)
        
        // generate enum members
        var generatedContent = ""
        for imageDirPath in imageDirPaths {
            // read images in the Images.xcassets dir
            if let ls = PluginHelper.runShellCommand("ls \(imageDirPath) | grep imageset") {
                let imagePaths = ls.componentsSeparatedByString("\n")
                
                for imagePath in imagePaths {
                    let key = imagePath.stringByReplacingOccurrencesOfString(".imageset", withString: "")
                    generatedContent += "        case \(key)\n"
                }
                // replace members of enum string
                replaceEnumMembers("image", members: generatedContent)
            }
        }
    }
    
    private func generateStrings() {
        let baseStringFilePath = PluginHelper.baseLocalizableFilePath(inProject: project)
        // read the Localizable.strings file
        if let originalContent = String.readFile(baseStringFilePath) {
            if let matches = originalContent.matches(PATTERN_STRINGS) {
                
                // generate enum members
                var generatedContent = ""
                for match in matches {
                    let key = (originalContent as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                    generatedContent += "        case \(key)\n"
                }
                // replace members of enum string
                replaceEnumMembers("string", members: generatedContent)
            }
        }
    }
    
    private func replaceEnumMembers(identifier: String, members: String) {
        let range = content!.matches("enum \(identifier) \\{\\n([\\s\\S]*?)\\s{4}\\}")![0].rangeAtIndex(1)
        content = (content! as NSString).stringByReplacingCharactersInRange(range, withString: members)
    }
    
}
