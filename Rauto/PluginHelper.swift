//
//  PluginHelper.swift
//  Rauto
//
//  Created by Azure Chen on 2/8/16.
//  Copyright © 2016 AzureChen. All rights reserved.
//

import AppKit

class PluginHelper {
    
    typealias Project = (path: String, name: String)
    
    static var states: [String: Bool] = [:] // [workspace: enable]
    
    static func project() -> Project? {
        if let path = workspacePath(), let name = projectName(atPath: path) {
            return (path, name)
        } else {
            return nil
        }
    }
    
    private static func workspacePath() -> String? {
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
    
    private static func projectName(atPath projectPath: String) -> String? {
        let projectFilePath = runShellCommand("ls \(projectPath) | grep .xcodeproj")
        return projectFilePath?.stringByReplacingOccurrencesOfString(".xcodeproj", withString: "")
    }
    
    static func projectFilePath(inProject project: Project) -> String {
        return "\(project.path)/\(project.name).xcodeproj/project.pbxproj"
    }
    
    static func resourceFilePath(inProject project: Project) -> String {
        return "\(project.path)/\(project.name)/R.swift"
    }
    
    static func baseLocalizableFilePath(inProject project: Project) -> String {
        return "\(project.path)/\(project.name)/Base.lproj/Localizable.strings"
    }
    
    static func colorFilePaths(inProject project: Project) -> [String] {
        return findFilePaths("Color.strings", inProject: project)
    }
    
    static func imageDirPaths(inProject project: Project) -> [String] {
        return findFilePaths(".*?.xcassets", inProject: project)
    }
    
    private static func findFilePaths(pattern: String, inProject project: Project) -> [String] {
        let projectFilePath = PluginHelper.projectFilePath(inProject: project)
        
        var paths: [String] = []
        if let projectContent = String.readFile(projectFilePath) {
            do {
                let regex = try NSRegularExpression(pattern: "/\\* \(pattern) \\*/.*?path = (.*?);", options: .CaseInsensitive)
                let matches = regex.matchesInString(projectContent, options: [], range: NSMakeRange(0, projectContent.characters.count))
                
                for match in matches {
                    let relativePath = (projectContent as NSString).substringWithRange(match.rangeAtIndex(1)) as String
                    paths.append("\(project.path)/\(project.name)/\(relativePath)")
                }
            } catch {
            }
        }
        
        return paths
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