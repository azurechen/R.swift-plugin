//
//  NSObject_Extension.swift
//
//  Created by AzureChen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import Foundation

extension NSObject {
    
    class func pluginDidLoad(bundle: NSBundle) {
        let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? NSString
        if appName == "Xcode" {
        	if sharedPlugin == nil {
        		sharedPlugin = Rauto(bundle: bundle)
        	}
        }
    }
    
    func swizzleClass(aClass: AnyClass, replace originalSelector: Selector, with swizzledSelector: Selector) {        
        let originalMethod = class_getInstanceMethod(aClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(aClass, swizzledSelector)
        print("swizzle \(aClass) \(originalMethod), \(swizzledMethod)")
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}