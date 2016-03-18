//
//  MainPlugin.swift
//
//  Created by AzureChen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

var sharedPlugin: MainPlugin?

class MainPlugin: NSObject, NSMenuDelegate {
    
    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()
    
    let pluginMenu = NSMenu()
    
    static var currentDocumentName: String?
    static var states: [String: Bool] = [:] // [workspace: enable]
    
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
        
        self.swizzleClass(NSWindow.self,
            replace: Selector("becomeKeyWindow"),
            with: Selector("hook_becomeKeyWindow"))
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

        let item = NSApp.mainMenu!.itemWithTitle("Edit")
        if (item != nil) {
            item!.submenu!.addItem(NSMenuItem.separatorItem())
            
            // first level item
            let pluginItem = NSMenuItem(title: "R.swift", action: nil, keyEquivalent: "")
            item!.submenu!.addItem(pluginItem)
            
            pluginMenu.delegate = self
            item!.submenu!.setSubmenu(pluginMenu, forItem: pluginItem)
        }
    }
    
    func menuWillOpen(menu: NSMenu) {
        if (menu == pluginMenu) {
            var enabled = false
            
            // get state
            if let project = PluginHelper.project() {
                let key = "\(project.path)/\(project.name)"
                if let state = MainPlugin.states[key] {
                    enabled = state
                }
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
            
            if (MainPlugin.states[key] != nil) {
                if (sender.state == NSOnState) {
                    MainPlugin.states[key] = false
                } else {
                    MainPlugin.states[key] = true
                    MainPlugin.sync()
                }
            }
        }
    }
    
    func syncAction() {
        MainPlugin.sync()
    }
    
    func cleanAction() {
        MainPlugin.clean()
        
        // Set auto sync disable to avoid sync again after cleaning R
        if let project = PluginHelper.project() {
            let key = "\(project.path)/\(project.name)"
            
            if (MainPlugin.states[key] != nil) {
                MainPlugin.states[key] = false
            }
        }
    }
    
    static func autoSyncIfNeeded(document documentName: String?) {
        let prevDocumentName = currentDocumentName
        currentDocumentName = documentName
        //print("\(prevDocumentName) \(currentDocumentName)")
        
        if (currentDocumentName == nil) ||  isRFile(prevDocumentName) ||
            (!isRFile(currentDocumentName) &&
            prevDocumentName != currentDocumentName &&
            isTargetFile(prevDocumentName) &&
            !isTargetFile(currentDocumentName)) {
            
            if let project = PluginHelper.project() {
                let key = "\(project.path)/\(project.name)"
                // Auto sync is enabled
                if (states[key] == true) {
                    sync()
                }
            }
        }
    }
    
    private static func isRFile(name: String?) -> Bool {
        if (name != nil) {
            return name!.match(PluginHelper.TARGET_NAME_PATTERN_R)
        }
        return false
    }
    
    private static func isTargetFile(name: String?) -> Bool {
        if (name != nil) {
            return name!.match(PluginHelper.TARGET_NAME_PATTERN_COLOR) || name!.match(PluginHelper.TARGET_NAME_PATTERN_IMAGE) || name!.match(PluginHelper.TARGET_NAME_PATTERN_LOCALIZABLE)
        }
        return false
    }
    
    static func sync() {
        print("R.swift-plugin Sync")
        if let project = PluginHelper.project() {
            // 1. register the R.swift file in project.pbxproj
            registerResourceFileIfNeeded(inProject: project)
            // 2. create and write the R.swift file
            createResourceFile(inProject: project)
        } else {
            print("Cannot find the root path of the current project.")
        }
    }
    
    static func clean() {
        print("R.swift-plugin Clean")
        if let project = PluginHelper.project() {
            // 1. remove the R.swift file
            removeResourceFile(inProject: project)
            // 2. clean registered the R.swift file in project.pbxproj
            unregisterResourceFile(inProject: project)
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
        let generator = RContentGenerator(project: project)
        generator.generate()?.writeToFile(rPath)
        
        // lock R.swift
        PluginHelper.runShellCommand("chmod 444 \(rPath.stringEscapeSpaces())")
    }
    
    private static func removeResourceFile(inProject project: (path: String, name: String)) {
        // remove R files
        PluginHelper.runShellCommand("find \(project.path.stringEscapeSpaces())/\(project.name.stringEscapeSpaces()) -name \(PluginHelper.TARGET_NAME_PATTERN_R) -type f -delete")
    }
    
    private static func registerResourceFileIfNeeded(inProject project: (path: String, name: String)) {
        let projectFilePath = PluginHelper.projectFilePath(inProject: project)
        
        // check status first
        let status = checkResourceFile(inProject: project)
        if (status == 1) { // the R.swift file is registered
            return
        } else if (status != 0) { // some parts of info have been registered, but not completed
            unregisterResourceFile(inProject: project)
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
            let matches = projectContent.matches("/\\* \(project.name) \\*/ = \\{\\n*?\\t*?isa = PBXGroup;\\n*?\\t*?children = \\(([\\s\\S]*?)\\n*?\\t*?\\);")
            if (!matches.isEmpty) {
                if let range = projectContent.rangeFromNSRange(matches[0].rangeAtIndex(1)) {
                    projectContent.insert("\n\t\t\t\t\(UUID2) /* R.swift */,", atIndex: range.endIndex)
                }
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
    
    private static func unregisterResourceFile(inProject project: (path: String, name: String)) {
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
            var count1 = 0
            var count2 = 0
            for pattern in REGISTERED_RESOURCE_FILE_PATTERNS {
                count1 += projectContent.matches(pattern).count
                count2++
            }
            
            if (count1 == 0 && count2 == 0) { // registered file not found
                return 0
            } else if (count1 == 4 && count2 == 4) { // registered file found
                return 1
            } else { // error
                return -1
            }
        } else {
            print("Cannot read the project.pbxproj file.")
            return -1
        }
    }
}

