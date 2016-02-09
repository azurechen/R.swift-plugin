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
            let syncMenuItem = NSMenuItem(title: "Sync Resources", action: "syncAction", keyEquivalent: "")
            syncMenuItem.target = self
            item!.submenu!.addItem(NSMenuItem.separatorItem())
            item!.submenu!.addItem(syncMenuItem)
        }
    }

    func syncAction() {
        // 1. check R file
        createResourceFileIfNeeded()
        // 2. rewrite R file
    }
    
    func createResourceFileIfNeeded() {
        let projectPath = PluginHelper.workspacePath()
        if (projectPath != nil) {
            let projectName = projectPath!.componentsSeparatedByString("/").last
            let projectFile = "\(projectPath!)/\(projectName!).xcodeproj/project.pbxproj"
            
            // if R file doesn't exist
            let rPath = "\(projectPath!)/\(projectName!)/R.swift"
            if (!NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
                NSFileManager.defaultManager().createFileAtPath(rPath, contents: nil, attributes: nil)
            }
            
            // register R file in project.pbxproj
            if var projectContent = String.readFile(projectFile) {
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
                    let regex = try NSRegularExpression(pattern: "/\\* Test \\*/ = \\{\\n\\t*isa = PBXGroup;[\\s\\S]*?\\t*(.*?) /\\* Supporting Files \\*/", options: .CaseInsensitive)
                    let matches = regex.matchesInString(projectContent, options: [], range: NSMakeRange(0, projectContent.characters.count))
                    let mainFolderId = (projectContent as NSString).substringWithRange(matches[0].rangeAtIndex(1)) as String
                    
                    if (mainFolderId.characters.count == 24) {
                        if let range = projectContent.rangeOfString("\(mainFolderId) /\\* Supporting Files \\*/ = \\{\\n\\t*isa = PBXGroup;\\n\\t*children = \\(", options: .RegularExpressionSearch) {
                            projectContent.insert("\n\t\t\t\t\(UUID2) /* R.swift */,", atIndex: range.endIndex)
                        }
                    } else {
                        print("Cannot find the Supporting Files group.")
                        return
                    }
                } catch {
                }
                // 4. PBXSourcesBuildPhase section
                if let range = projectContent.rangeOfString("/\\* Begin PBXSourcesBuildPhase section \\*/\\n\\t*[\\s\\S]*?files = \\(", options: .RegularExpressionSearch) {
                    projectContent.insert("\n\t\t\t\t\(UUID1) /* R.swift in Sources */,", atIndex: range.endIndex)
                }
                
                // save file
                projectContent.writeToFile(projectFile)
            }
        }
        
    }
}
