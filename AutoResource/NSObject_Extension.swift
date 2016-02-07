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
        		sharedPlugin = AutoResource(bundle: bundle)
        	}
        }
    }
}