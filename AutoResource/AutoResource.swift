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
            
            let rPath = "\(projectPath!)/\(projectName!)/R.swift"
            // if R file doesn't exist
            if (!NSFileManager.defaultManager().fileExistsAtPath(rPath)) {
                NSFileManager.defaultManager().createFileAtPath(rPath, contents: nil, attributes: nil)
            }
        }
        
    }
}

