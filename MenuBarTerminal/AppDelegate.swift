//
//  AppDelegate.swift
//  MenuBarTerminal
//
//  Created by mavenlink on 1/16/16.
//
//

import Cocoa
import WebKit
import Foundation

//protocol AppDelegate {
//}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebFrameLoadDelegate {

    ////
    var masterFileHandle:NSFileHandle?
    var outboundJson:NSString?
    
    //@prop
    
    // = NSFileHandle(fileDescriptor: 0)
    
//    private let	_childProcessID:pid_t
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)

    
    @IBOutlet weak var terminaltem: NSMenuItem!
    @IBOutlet weak var terminalView: TerminalView!
    
    @IBOutlet weak var webView: WebView!
    
    @IBAction func quitClicked(sender: AnyObject) {
        
        NSApplication.sharedApplication().terminate(self)
        
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let icon = NSImage(named: "statusIcon")
        icon?.template = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        terminaltem.view = terminalView
        
        let path = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "Html")!
        let url = NSURL(string: path)!
        let urlRequest = NSURLRequest(URL: url)
        webView.mainFrame.loadRequest(urlRequest)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func webView(webView: WebView!, didFailLoadWithError error: NSError!) {
        print("Webview fail with error \(error)");
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        print("Webview did finish load")
        let script = "(function() { return terminalReady(); })();"
        if let returnedString = webView.stringByEvaluatingJavaScriptFromString(script) {
            if (returnedString == "ready") {
                self.initTerm("/bin/bash", arguments: ["/bin/bash", "--rcfile", "~/.profile", "-i", "-c", "eval `ssh-agent -s` && env && htop -d 5"], environment: ["TERM=xterm-256color", "PATH=/bin:/usr/bin:/usr/local/bin", "USER=mavenlink", "HOME=/Users/mavenlink"])
            }
        }
    }
    
    func run() {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.readData()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.sendData()
                self.run()
            })
        })
    }
    
    func initTerm(path:String, arguments:[String], environment:[String]) {
        assert(arguments.count >= 1)
        assert(path.hasSuffix(arguments[0]))
        
        let	r	=	forkPseudoTeletypewriter()
        if r.result.ok {
            if r.result.isRunningInParentProcess {
                print("parent: ok, child pid = \(r.result.processID)")
                self.masterFileHandle = r.master.toFileHandle(true)
                self.run()
            } else {
                execute(path, arguments, environment)
                fatalError("Returning from `execute` means the command was failed. This is unrecoverable error in child process side, so just abort the execution.")
            }
        } else {
            print("`forkpty` failed.")
        }
    }

    func sendData() { //(notif : NSNotification) {
        if (self.outboundJson != nil) {
            if let res = self.webView.windowScriptObject.callWebScriptMethod("appendStdout", withArguments: [self.outboundJson!]) {
                if (false) { print(res) }
            }
            self.outboundJson = nil
        }
    }
    
    func readData() {
        // Get the data from the FileHandle
        let data = self.masterFileHandle?.availableData
        
        // Only deal with the data if it actually exists
        if data?.length > 0 {
            let string = NSString(data: data!, encoding: NSUTF8StringEncoding)

            var jsonObject = [String: NSString]()
            jsonObject["raw"] = string
            
            do {
                let outboundData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions(rawValue: 0))
                
                self.outboundJson = NSString(data: outboundData, encoding: NSUTF8StringEncoding)
                
            } catch {
                print("json error")
                self.outboundJson = nil
            }
        }
    }
}
