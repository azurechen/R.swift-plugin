//
//  ResourceGenerator.swift
//  AutoResource
//
//  Created by Azure Chen on 2/11/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

class ResourceGenerator {
    
    var content: String?
    
    func generate() -> String? {
        // 1. read template from the R_template.swift
        initFromTemplate()
        // 2. generate localizable strings
        
        
        return content
    }
    
    private func initFromTemplate() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("R_template", withExtension: "txt")
        content = try? String(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
    }
    
}