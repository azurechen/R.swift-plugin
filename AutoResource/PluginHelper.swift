//
//  PluginHelper.swift
//  AutoResource
//
//  Created by Azure Chen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

class PluginHelper {
    
    static func workspacePath() -> String? {
        if let anyClass = NSClassFromString("IDEWorkspaceWindowController") as? NSObject.Type,
            let windowControllers = anyClass.valueForKey("workspaceWindowControllers") as? [NSObject],
            let window = NSApp.keyWindow ?? NSApp.windows.first {
                
                for controller in windowControllers {
                    if controller.valueForKey("window")?.isEqual(window) == true,
                        let workspacePath = controller.valueForKey("_workspace")?.valueForKeyPath("representingFilePath._pathString") as? NSString {
                            return workspacePath.stringByDeletingLastPathComponent as String
                    }
                }
        }
        return nil
    }
    
    static func projectName(atPath projectPath: String) -> String {
        return projectPath.componentsSeparatedByString("/").last!
    }
    
    static func projectFilePath(atPath projectPath: String) -> String {
        let projectName = PluginHelper.projectName(atPath: projectPath)
        return "\(projectPath)/\(projectName).xcodeproj/project.pbxproj"
    }
    
    static func resourceFilePath(atPath projectPath: String) -> String {
        let projectName = PluginHelper.projectName(atPath: projectPath)
        return "\(projectPath)/\(projectName)/R.swift"
    }
    
    static func baseLocalizableFilePath(atPath projectPath: String) -> String {
        let projectName = PluginHelper.projectName(atPath: projectPath)
        return "\(projectPath)/\(projectName)/Base.lproj/Localizable.strings"
    }
    
    static func runShellCommand(command: String) -> String? {
        let pipe = NSPipe()
        let task = NSTask()
        
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", String(format: "%@", command)]
        task.standardOutput = pipe
        task.launch()
        
        let file = pipe.fileHandleForReading
        if let result = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)?.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()) {
            return result as String
        }
        return nil
    }
    
    static func UUID(withLength len: Int) -> String {
        var uuid = ""
        for (var i = 0; i < len; i++){
            let rand = arc4random_uniform(16)
            uuid += String(format:"%X", Int(rand))
        }
        
        return uuid
    }
    
}