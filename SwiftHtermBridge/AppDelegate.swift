//
//  AppDelegate.swift
//  MenuBarTerminal
//
//  Created by diclophis on 1/16/16.
//
//

import Cocoa
import WebKit
import Foundation


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebFrameLoadDelegate {


    private var masterFileHandle:NSFileHandle!
    private var list = [NSData]()
    private var outList = [NSString]()

    private let script = "(function() { return terminalReady(); })();"
    //let qualityOfServiceClass = QOS_CLASS_USER_INTERACTIVE //QOS_CLASS_BACKGROUND // //
    private let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)



    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var webView: WebView!


    @IBAction func quitClicked(sender: AnyObject) {
        //TODO: clean shutdown
        NSApplication.sharedApplication().terminate(self)
    }


    func applicationDidFinishLaunching(aNotification: NSNotification) {
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
                if (self.masterFileHandle != nil) {
                    print("!@#!@#!@#!@#")
                } else {
                    self.initTerm("/bin/bash",
                        arguments: ["/bin/bash", "-i", "-l"], //"--rcfile", "~/.profile"
                        environment: [
                        "LANG=en_US.UTF-8",
                        "TERM=xterm-256color",
                        "PATH=/bin:/usr/bin:/usr/local/bin",
                        "USER=\(NSUserName())",
                        "HOME=\(NSHomeDirectory())"])
                }
            }
        }
    }


    func run() {
        self.sendData()
        dispatch_async(backgroundQueue, {
            self.readData()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
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


                let handler =  { (file:NSFileHandle!) -> Void in
                    self.sync(self) {
                        if let ready:NSData = file.availableData {
                            if ready.length > 0 {
                                self.list.append(ready)
                            }
                        } else {
                            print("done")
                            exit(0)
                        }
                    }
                }


                self.masterFileHandle = r.master.toFileHandle(false)
                self.masterFileHandle!.readabilityHandler = handler


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
        self.sync(self) {
            if let res:NSString = self.webView.windowScriptObject.callWebScriptMethod("fetchStdin", withArguments: self.outList) as? NSString {
                do {
                    if let raw = try NSJSONSerialization.JSONObjectWithData(res.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject],
                        data = raw["data"] as? NSString {
                        if let dd:NSData = data.dataUsingEncoding(NSUTF8StringEncoding) {
                            self.masterFileHandle.writeData(dd)
                        }
                    } else {
                        print("json parsing error in stdin - a")

                    }
                } catch {
                    print("json parsing error in stdin")
                }
            }
            self.outList.removeAll()
        }
    }


    func readData() {
        sync(self) {
            let allData = NSMutableData()

            if (self.list.count > 0) {
                for data in self.list {
                    allData.appendData(data)
                }
            }


            if allData.length > 0 {
                let string = NSString(data: allData, encoding: NSUTF8StringEncoding)
                
                var jsonObject = [NSString: NSString]()
                jsonObject["raw"] = string
                
                do {
                    let outboundData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions(rawValue: 0))
                    self.outList.append(NSString(data: outboundData, encoding: NSUTF8StringEncoding)!)
                } catch {
                    print("json error")
                }
            }

            self.list.removeAll()
        }
    }


    func sync(lock: AnyObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}