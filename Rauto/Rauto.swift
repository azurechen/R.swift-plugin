//
//  Rauto.swift
//
//  Created by AzureChen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

var sharedPlugin: Rauto?

class Rauto: NSObject, NSMenuDelegate {
    
    var states: [String: Bool] = [:] // [workspace: enable]
    let pluginMenu = NSMenu()

    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()
    
    static let REGISTERED_RESOURCE_FILE_PATTERNS = [
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
        center.addObserver(self, selector: Selector("createMenu"), name: NSApplicationDidFinishLaunchingNotification, object: nil)
        
        self.swizzleClass(NSTabView.self,
            replace: Selector("selectTabViewItem:"),
            with: Selector("hook_selectTabViewItem:"))
        self.swizzleClass(NSTabViewItem.self,
            replace: Selector("setLabel:"),
            with: Selector("hook_setLabel:"))
    }

    deinit {
        removeObserver()
    }

    func removeObserver() {
        center.removeObserver(self)
    }
    
    func createMenu() {
        removeObserver()

        let item = NSApp.mainMenu!.itemWithTitle("Product")
        if (item != nil) {
            item!.submenu!.addItem(NSMenuItem.separatorItem())
            
            // first level item
            let pluginItem = NSMenuItem(title: "Rauto", action: nil, keyEquivalent: "")
            item!.submenu!.addItem(pluginItem)
            
            pluginMenu.delegate = self
            item!.submenu!.setSubmenu(pluginMenu, forItem: pluginItem)
        }
    }
    
    func menuWillOpen(menu: NSMenu) {
        if (menu == pluginMenu) {
            var enabled = false
            
            // create a state of current workspace at first time
            if let project = PluginHelper.project() {
                let key = "\(project.path)/\(project.name)"
                
                if (states[key] == nil) {
                    let rPath = PluginHelper.resourceFilePath(inProject: project)
                    states[key] = NSFileManager.defaultManager().fileExistsAtPath(rPath)
                }
                enabled = states[key]!
            }
            resetMenuItems(enabled: enabled)
        }
    }
    
    func resetMenuItems(enabled enabled: Bool) {
        pluginMenu.removeAllItems()
        
        // 1. Enable
        let enableItem = NSMenuItem(title: "Enable Auto Sync", action: "enableAction:", keyEquivalent: "")
        enableItem.state = enabled ? NSOnState : NSOffState
        enableItem.target = self
        pluginMenu.addItem(enableItem)
        
        // 2. separator
        pluginMenu.addItem(NSMenuItem.separatorItem())
        
        // 3. sync
        let syncItem = NSMenuItem(title: "Sync", action: "syncAction", keyEquivalent: "")
        syncItem.target = self
        pluginMenu.addItem(syncItem)
        
        // 4. clean
        let cleanItem = NSMenuItem(title: "Clean", action: "cleanAction", keyEquivalent: "")
        cleanItem.target = self
        pluginMenu.addItem(cleanItem)
    }

    func enableAction(sender: NSMenuItem) {
        if let project = PluginHelper.project() {
            let key = "\(project.path)/\(project.name)"
            
            if (states[key] != nil) {
                if (sender.state == NSOnState) {
                    states[key] = false
                } else {
                    states[key] = true
                }
            }
        }
    }
    
    func syncAction() {
        Rauto.sync()
    }
    
    func cleanAction() {
        Rauto.clean()
    }
    
    static func sync() {
        if let project = PluginHelper.project() {
            // 1. create and write the R.swift file
            createResourceFile(inProject: project)
            // 2. register the R.swift file in project.pbxproj
            registerResourceFileIfNeeded(inProject: project)
        } else {
            print("Cannot find the root path of the current project.")
        }
    }
    
    static func clean() {
        if let project = PluginHelper.project() {
            // 1. remove the R.swift file
            removeResourceFile(inProject: project)
            // 2. clean registered the R.swift file in project.pbxproj
            cleanResourceFile(inProject: project)
        } else {
            print("Cannot find the root path of the current project.")
        }
    }
    
    private static func createResourceFile(inProject project: (path: String, name: String)) {
        let rPath = PluginHelper.resourceFilePath(inProject: project)
        
        // if the R.swift file exist, remove it
        if (NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
            removeResourceFile(inProject: project)
        }
        
        // create the R.swift file
        if (!NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
            NSFileManager.defaultManager().createFileAtPath(rPath, contents: nil, attributes: nil)
        }
        
        // generate contents of the R.swift
        let generator = ResourceGenerator(project: project)
        generator.generate()?.writeToFile(rPath)
    }
    
    private static func registerResourceFileIfNeeded(inProject project: (path: String, name: String)) {
        let projectFilePath = PluginHelper.projectFilePath(inProject: project)
        
        // check status first
        let status = checkResourceFile(inProject: project)
        if (status == 4) { // the R.swift file is registered
            return
        } else if (status != 0) { // some parts of info have been registered, but not completed
            cleanResourceFile(inProject: project)
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
                let regex = try NSRegularExpression(pattern: "/\\*.*?\\*/ = \\{\\n*?\\t*?isa = PBXGroup;[\\s\\S]*?\\t*(.{24}?) /\\* Supporting Files \\*/", options: .CaseInsensitive)
                let matches = regex.matchesInString(projectContent, options: [], range: NSMakeRange(0, projectContent.characters.count))
                if (!matches.isEmpty) {
                    let mainFolderId = (projectContent as NSString).substringWithRange(matches[0].rangeAtIndex(1)) as String
                
                    if (mainFolderId.characters.count == 24) {
                        if let range = projectContent.rangeOfString("\(mainFolderId) /\\* Supporting Files \\*/ = \\{\\n*?\\t*?isa = PBXGroup;\\n*?\\t*?children = \\(", options: .RegularExpressionSearch) {
                            projectContent.insert("\n\t\t\t\t\(UUID2) /* R.swift */,", atIndex: range.endIndex)
                        }
                    } else {
                        print("Cannot find the Supporting Files group.")
                        return
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
    
    private static func removeResourceFile(inProject project: (path: String, name: String)) {
        // remove R file
        let rPath = PluginHelper.resourceFilePath(inProject: project)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(rPath)
        } catch {
        }
    }
    
    private static func cleanResourceFile(inProject project: (path: String, name: String)) {
        let projectFilePath = PluginHelper.projectFilePath(inProject: project)
        
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
    
    private static func checkResourceFile(inProject project: (path: String, name: String)) -> Int {
        let projectFilePath = PluginHelper.projectFilePath(inProject: project)
        
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

