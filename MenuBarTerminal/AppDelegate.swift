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


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebFrameLoadDelegate {


    var masterFileHandle:NSFileHandle?
    var outboundJson:NSString?
    var list:Array<NSData>?
    var outList:Array<NSString>?
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let script = "(function() { return terminalReady(); })();"


    //@IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var terminaltem: NSMenuItem!
    @IBOutlet weak var terminalView: TerminalView!
    @IBOutlet weak var webView: WebView!


    @IBAction func quitClicked(sender: AnyObject) {
        //TODO: clean shutdown
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
        if let returnedString = webView.stringByEvaluatingJavaScriptFromString(self.script) {
            if (returnedString == "ready") {
                self.statusItem.view?.window?.makeFirstResponder(self.webView)
                self.initTerm("/bin/bash",
                    arguments: ["/bin/bash", "--rcfile", "~/.profile", "-c", "eval `ssh-agent -s` && htop -d 5"],
                    environment: [
                    "LANG=en_US.UTF-8",
                    "TERM=xterm-256color",
                    "PATH=/bin:/usr/bin:/usr/local/bin",
                    "USER=mavenlink",
                    "HOME=/Users/mavenlink"])
            }
        }
    }


    func run() {
        let qualityOfServiceClass = QOS_CLASS_USER_INTERACTIVE //QOS_CLASS_BACKGROUND
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

        let	r = forkPseudoTeletypewriter()
        if r.result.ok {
            if r.result.isRunningInParentProcess {
                print("parent: ok, child pid = \(r.result.processID)")

                self.list = Array<NSData>()
                self.outList = Array<NSString>()

                let handler =  { (file:NSFileHandle!) -> Void in
                    if let ready:NSData = file.availableData {
                        if (ready.length > 0) {
                            self.sync(self.list!) {
                                self.list!.append(ready)
                            }
                        } else {
                            print("done")
                            exit(0)
                        }
                    }
                }


                self.masterFileHandle = r.master.toFileHandle(true)
                self.masterFileHandle?.readabilityHandler = handler


                self.run()
            } else {
                execute(path, arguments, environment)
                fatalError("Returning from `execute` means the command was failed. This is unrecoverable error in child process side, so just abort the execution.")
            }
        } else {
            print("`forkpty` failed.")
        }
    }


    func sendData() {
        self.sync(self.outList!) {
            for outboundJson in self.outList! {
                self.webView.windowScriptObject.callWebScriptMethod("appendStdout", withArguments: [outboundJson])
            }
            self.outList!.removeAll()
        }

        if let res:String = self.webView.windowScriptObject.callWebScriptMethod("fetchStdin", withArguments: []) as AnyObject? as? String {
            self.masterFileHandle?.writeData(res.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
    }


    func readData() {
        let allData = NSMutableData()

        sync(self.list!) {
            if (self.list!.count > 0) {
                for data in self.list! {
                    allData.appendData(data)
                }
            }
            self.list!.removeAll()
        }

        let string = NSString(data: allData, encoding: NSASCIIStringEncoding)
        
        var jsonObject = [String: NSString]()
        jsonObject["raw"] = string
        
        do {
            let outboundData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions(rawValue: 0))
            self.sync(self.outList!) {
                self.outList!.append(NSString(data: outboundData, encoding: NSUTF8StringEncoding)!)
            }
        } catch {
            print("json error")
        }
    }


    func sync(lock: AnyObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}