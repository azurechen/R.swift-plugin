//
//  SwizzledMethods.swift
//  R.swift-plugin
//
//  Created by Azure Chen on 2/28/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

extension NSWindow {
    // change window
    func hook_becomeKeyWindow() {
        self.hook_becomeKeyWindow()
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            // create a state of current workspace at first time
            if let project = PluginHelper.project() {
                let key = "\(project.path)/\(project.name)"
                
                if (MainPlugin.states[key] == nil) {
                    let rPath = PluginHelper.resourceFilePath(inProject: project)
                    MainPlugin.states[key] = NSFileManager.defaultManager().fileExistsAtPath(rPath)
                }
            }
            
            // sync
            MainPlugin.autoSyncIfNeeded(document: nil)
        }
    }
}

extension NSTabView {
    // change tab
    func hook_selectTabViewItem(tabViewItem: NSTabViewItem?) {
        self.hook_selectTabViewItem(tabViewItem)
        
        // sync
        MainPlugin.autoSyncIfNeeded(document: tabViewItem?.label)
    }
}

extension NSTabViewItem {
    // change file
    func hook_setLabel(label: String) {
        self.hook_setLabel(label)
        
        // sync
        MainPlugin.autoSyncIfNeeded(document: self.label)
    }
}