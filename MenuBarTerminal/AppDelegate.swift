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

    ////
    
//    private let	_masterFileHandle:NSFileHandle
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
        //icon?.template = true // best for dark mode
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
    
//    func webView(webView: WebView!, shouldStartLoadWithRequest request: NSURLRequest!, navigationType: WWebViewNavigationType) -&gt; Bool {
//    return true;
//    }
    
    
//    func webViewDidStartLoad(webView: WebView!) {
//        print("Webview started Loading")
//    }
//    
//    func webViewDidFinishLoad(webView: WebView!) {
//        print("Webview did finish load")
//    }
    
//    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
//        print("Webview did finish load")
//    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        print("Webview did finish load")
        let script = "(function() { return terminalReady(); })();"
        if let returnedString = webView.stringByEvaluatingJavaScriptFromString(script) {
            if (returnedString == "ready") {
                self.initTerm("/bin/bash", arguments: ["/bin/bash", "--rcfile", "~/.profile", "-i", "-c", "eval `ssh-agent -s` && env && devops console"], environment: ["TERM=xterm-256color", "PATH=/bin:/usr/bin:/usr/local/bin", "USER=mavenlink", "HOME=/Users/mavenlink"])
            }
        }
    }
    func chung() {
        print("a")
        sleep(100)
        wang()
    }
    
    func tonite() {
        
    }
    
    func wang() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            self.chung();
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
                self.tonite()
            }
        }
    }

    ///	Provides simple access to BSD `pty`.
    ///
    ///	This spawns a new child process using supplied arguments,
    ///	and setup a proper pseudo terminal connected to it.
    ///
    ///	The child process will run in interactive mode terminal,
    ///	and will emit terminal escape code accordingly if you set
    ///	a proper terminal environment variable.
    ///
    ///		TERM=ansi
    ///
    ///	Here's full recommended example.
    ///
    ///		let	pty	=	PseudoTeletypewriter(path: "/bin/ls", arguments: ["/bin/ls", "-Gbla"], environment: ["TERM=ansi"])!
    ///		println(pty.masterFileHandle.readDataToEndOfFile().toString())
    ///		pty.waitUntilChildProcessFinishes()
    ///
    ///	It is recommended to use executable name as the first argument by convention.
    ///
    ///	The child process will be launched immediately when you
    ///	instantiate this class.
    ///
    ///	This is a sort of `NSTask`-like class and modeled on it.
    ///	This does not support setting terminal dimensions.
    
    func initTerm(path:String, arguments:[String], environment:[String]) {
        assert(arguments.count >= 1)
        assert(path.hasSuffix(arguments[0]))
        
        let	r	=	forkPseudoTeletypewriter()
        if r.result.ok {
            if r.result.isRunningInParentProcess {
                print("parent: ok, child pid = \(r.result.processID)")
                //self._masterFileHandle	=	r.master.toFileHandle(true)
                let	masterFileHandle:NSFileHandle = r.master.toFileHandle(true)
                
                //masterFileHandle.availableData
                masterFileHandle.waitForDataInBackgroundAndNotify()
                
                // Set up the observer function
                let notificationCenter = NSNotificationCenter.defaultCenter()
                notificationCenter.addObserver(self, selector: "receivedData:", name: NSFileHandleDataAvailableNotification, object: nil)
            } else {
                //print("child: ok")
                execute(path, arguments, environment)
                fatalError("Returning from `execute` means the command was failed. This is unrecoverable error in child process side, so just abort the execution.")
            }
        } else {
            print("`forkpty` failed.")
        }
    }

    func receivedData(notif : NSNotification) {
        // Unpack the FileHandle from the notification
        let fh:NSFileHandle = notif.object as! NSFileHandle
        fh.waitForDataInBackgroundAndNotify()

        // Get the data from the FileHandle
        let data = fh.availableData
        // Only deal with the data if it actually exists
        if data.length > 0 {
            let string = NSString(data: data, encoding: NSUTF8StringEncoding)

            var jsonObject = [String: NSString]()
            jsonObject["raw"] = string
            
            do {
                let outboundData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions(rawValue: 0))
                
                
                if let outboundJson = NSString(data: outboundData, encoding: NSUTF8StringEncoding) {
                    print("fff \(outboundJson)")
                    
                    if let res = self.webView.windowScriptObject.callWebScriptMethod("appendStdout", withArguments: [outboundJson]) {
                        print(res)
                    }
                }
                
            } catch {
                print("json error")
            }
        }
    }
}
