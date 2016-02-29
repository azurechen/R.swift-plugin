//
//  SwizzledMethods.swift
//  Rauto
//
//  Created by Azure Chen on 2/28/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

extension NSWindow {
    // change window
    func hook_becomeKeyWindow() {
        self.hook_becomeKeyWindow()
        
        // create a state of current workspace at first time
        if let project = PluginHelper.project() {
            let key = "\(project.path)/\(project.name)"
            
            if (PluginHelper.states[key] == nil) {
                let rPath = PluginHelper.resourceFilePath(inProject: project)
                PluginHelper.states[key] = NSFileManager.defaultManager().fileExistsAtPath(rPath)
            }
        }
    }
}

extension NSTabView {
    // change tab
    func hook_selectTabViewItem(tabViewItem: NSTabViewItem?) {
        self.hook_selectTabViewItem(tabViewItem)
        NSLog("swizzle tab  \(tabViewItem!.label)")
    }
}

extension NSTabViewItem {
    // change file
    func hook_setLabel(label: String) {
        self.hook_setLabel(label)
        NSLog("swizzle file \(self.label)")
    }
}