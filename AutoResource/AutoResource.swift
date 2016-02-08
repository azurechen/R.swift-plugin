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
        let alert = NSAlert()
        alert.messageText = PluginHelper.workspacePath() ?? "N/A"
        alert.runModal()
    }
    
}

