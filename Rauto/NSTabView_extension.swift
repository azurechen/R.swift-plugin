//
//  NSTabView_extension.swift
//  Rauto
//
//  Created by Azure Chen on 2/28/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

extension NSTabView {
    func hook_selectTabViewItem(tabViewItem: NSTabViewItem?) {
        self.hook_selectTabViewItem(tabViewItem)
        NSLog("swizzle tab  \(tabViewItem?.label)")
    }
}

extension NSTabViewItem {
    func hook_setLabel(label: String) {
        self.hook_setLabel(label)
        NSLog("swizzle file \(self.label)")
    }
}