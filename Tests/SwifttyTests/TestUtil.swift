import Foundation

class TestUtil {
    @discardableResult
    static func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    static func send(string: String, toHost: String, port: Int) -> Int32 {
        let pipe = Pipe()
        
        let echo = Process()
        echo.launchPath = "/usr/bin/env"
        echo.arguments = ["echo", string]
        echo.standardOutput = pipe
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["nc", toHost, String(port)]
        task.standardInput = pipe
        
        echo.launch()
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
