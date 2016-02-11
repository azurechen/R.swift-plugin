//
//  AutoResource.swift
//
//  Created by AzureChen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

var sharedPlugin: AutoResource?

class AutoResource: NSObject {

    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()
    
    let REGISTERED_RESOURCE_FILE_PATTERNS = [
        // 1. PBXBuildFile section
        "\\n*?\\t*?.{24}? /\\* R.swift in Sources \\*/ = \\{isa = PBXBuildFile; fileRef = .*? /\\* R.swift \\*/; \\};",
        // 2. PBXFileReference section
        "\\n*?\\t*?.{24}? /\\* R.swift \\*/ = \\{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = .*?R.swift; sourceTree = \"<group>\"; \\};",
        // 3. PBXGroup section
        "\\n*?\\t*?.{24}? /\\* R.swift \\*/,",
        // 4. PBXSourcesBuildPhase section
        "\\n*?\\t*?.{24}? /\\* R.swift in Sources \\*/,",
    ]

    init(bundle: NSBundle) {
        self.bundle = bundle

        super.init()
        center.addObserver(self, selector: Selector("createMenuItems"), name: NSApplicationDidFinishLaunchingNotification, object: nil)
    }

    deinit {
        removeObserver()
    }

    func removeObserver() {
        center.removeObserver(self)
    }
    
    func createMenuItems() {
        removeObserver()

        let item = NSApp.mainMenu!.itemWithTitle("Edit")
        if item != nil {
            item!.submenu!.addItem(NSMenuItem.separatorItem())
            
            // sync button
            let syncMenuItem = NSMenuItem(title: "Sync Resources", action: "syncAction", keyEquivalent: "")
            syncMenuItem.target = self
            item!.submenu!.addItem(syncMenuItem)
            
            // clean button
            let cleanMenuItem = NSMenuItem(title: "Clean Generated Resources", action: "cleanAction", keyEquivalent: "")
            cleanMenuItem.target = self
            item!.submenu!.addItem(cleanMenuItem)
        }
    }

    func syncAction() {
        if let projectPath = PluginHelper.workspacePath() {
            // 1. create and write the R.swift file
            createResourceFile(atPath: projectPath)
            // 2. register the R.swift file in project.pbxproj
            registerResourceFileIfNeeded(atPath: projectPath)
        } else {
            print("Cannot find the root path of the current project.")
        }
    }
    
    func cleanAction() {
        if let projectPath = PluginHelper.workspacePath() {
            // 1. remove the R.swift file
            removeResourceFile(atPath: projectPath)
            // 2. clean registered the R.swift file in project.pbxproj
            cleanResourceFile(atPath: projectPath)
        } else {
            print("Cannot find the root path of the current project.")
        }
    }
    
    func createResourceFile(atPath projectPath: String) {
        let rPath = PluginHelper.resourceFilePath(atPath: projectPath)
        
        // if the R.swift file exist, remove it
        if (NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
            removeResourceFile(atPath: projectPath)
        }
        
        // create the R.swift file
        if (!NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
            NSFileManager.defaultManager().createFileAtPath(rPath, contents: nil, attributes: nil)
        }
        
        // generate contents of the R.swift
        let generator = ResourceGenerator(path: projectPath)
        if var content = generator.generate() {
            content += "\n\n//  \(NSDate())" // for debug
            content.writeToFile(rPath)
        }
    }
    
    func registerResourceFileIfNeeded(atPath projectPath: String) {
        let projectFilePath = PluginHelper.projectFilePath(atPath: projectPath)
        
        // check status first
        let status = checkResourceFile(atPath: projectPath)
        if (status == 4) { // the R.swift file is registered
            return
        } else if (status != 0) { // some parts of info have been registered, but not completed
            cleanResourceFile(atPath: projectPath)
        }
        
        // read the content of project.pbxproj and register R file in project.pbxproj
        if var projectContent = String.readFile(projectFilePath) {
            // create UUIDs
            let UUID1 = PluginHelper.UUID(withLength: 24)
            let UUID2 = PluginHelper.UUID(withLength: 24)
            
            // 1. PBXBuildFile section
            if let range = projectContent.rangeOfString("/\\* Begin PBXBuildFile section \\*/", options: .RegularExpressionSearch) {
                projectContent.insert("\n\t\t\(UUID1) /* R.swift in Sources */ = {isa = PBXBuildFile; fileRef = \(UUID2) /* R.swift */; };", atIndex: range.endIndex)
            }
            // 2. PBXFileReference section
            if let range = projectContent.rangeOfString("/\\* Begin PBXFileReference section \\*/", options: .RegularExpressionSearch) {
                projectContent.insert("\n\t\t\(UUID2) /* R.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = R.swift; sourceTree = \"<group>\"; };", atIndex: range.endIndex)
            }
            // 3. PBXGroup section (Supporting Files)
            do {
                let regex = try NSRegularExpression(pattern: "/\\* Test \\*/ = \\{\\n*?\\t*?isa = PBXGroup;[\\s\\S]*?\\t*(.{24}?) /\\* Supporting Files \\*/", options: .CaseInsensitive)
                let matches = regex.matchesInString(projectContent, options: [], range: NSMakeRange(0, projectContent.characters.count))
                let mainFolderId = (projectContent as NSString).substringWithRange(matches[0].rangeAtIndex(1)) as String
                
                if (mainFolderId.characters.count == 24) {
                    if let range = projectContent.rangeOfString("\(mainFolderId) /\\* Supporting Files \\*/ = \\{\\n*?\\t*?isa = PBXGroup;\\n*?\\t*?children = \\(", options: .RegularExpressionSearch) {
                        projectContent.insert("\n\t\t\t\t\(UUID2) /* R.swift */,", atIndex: range.endIndex)
                    }
                } else {
                    print("Cannot find the Supporting Files group.")
                    return
                }
            } catch {
            }
            // 4. PBXSourcesBuildPhase section
            if let range = projectContent.rangeOfString("/\\* Begin PBXSourcesBuildPhase section \\*/\\n*?\\t*?[\\s\\S]*?files = \\(", options: .RegularExpressionSearch) {
                projectContent.insert("\n\t\t\t\t\(UUID1) /* R.swift in Sources */,", atIndex: range.endIndex)
            }
            
            // save file
            projectContent.writeToFile(projectFilePath)
        } else {
            print("Cannot read the project.pbxproj file.")
        }
    }
    
    func removeResourceFile(atPath projectPath: String) {
        // remove R file
        let rPath = PluginHelper.resourceFilePath(atPath: projectPath)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(rPath)
        } catch {
        }
    }
    
    func cleanResourceFile(atPath projectPath: String) {
        let projectFilePath = PluginHelper.projectFilePath(atPath: projectPath)
        
        // remove from project.pbxproj
        if var projectContent = String.readFile(projectFilePath) {
            do {
                for pattern in REGISTERED_RESOURCE_FILE_PATTERNS {
                    let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
                    projectContent = regex.stringByReplacingMatchesInString(projectContent, options: [], range: NSMakeRange(0, projectContent.characters.count), withTemplate: "")
                }
                
                // save file
                projectContent.writeToFile(projectFilePath)
            } catch {
            }
        } else {
            print("Cannot read the project.pbxproj file.")
        }
    }
    
    func checkResourceFile(atPath projectPath: String) -> Int {
        let projectFilePath = PluginHelper.projectFilePath(atPath: projectPath)
        
        // check if R.swift exists in project.pbxproj
        if let projectContent = String.readFile(projectFilePath) {
            var count = 0
            for pattern in REGISTERED_RESOURCE_FILE_PATTERNS {
                if let _ = projectContent.rangeOfString(pattern, options: .RegularExpressionSearch) {
                    count++
                }
            }
            return count
        } else {
            print("Cannot read the project.pbxproj file.")
            return -1
        }
    }
}

