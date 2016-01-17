//
//  AppDelegate.swift
//  MenuBarTerminal
//
//  Created by mavenlink on 1/16/16.
//
//

import Cocoa
import WebKit
//import BSD

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebFrameLoadDelegate {

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
        
        //NSBundle.mainBundle().pathForResource(<#T##name: String?##String?#>, ofType: <#T##String?#>, inDirectory: <#T##String?#>)
        let path = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "Html")!
        let url = NSURL(string: path)!
        let urlRequest = NSURLRequest(URL: url)
        webView.mainFrame.loadRequest(urlRequest)
        
        

        //webView.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: "https://archive.org")!))
        
        //webView.mainFrame.navigationDelegate = self
        

        
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
        //webView.stringByEvaluatingJavaScriptFromString(<#T##script: String!##String!#>)
        let script = "(function() { return document.body.innerHTML; })();"
        if let returnedString = webView.stringByEvaluatingJavaScriptFromString(script) {
            print("the result is \(returnedString)")
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
    ///
    //public class PseudoTeletypewriter {

    /*
    public init?(path:String, arguments:[String], environment:[String]) {
        assert(arguments.count >= 1)
        assert(path.hasSuffix(arguments[0]))
        
        let	r	=	forkPseudoTeletypewriter()
        if r.result.ok {
            if r.result.isRunningInParentProcess {
                debugLog("parent: ok, child pid = \(r.result.processID)")
                self._masterFileHandle	=	r.master.toFileHandle(true)
                self._childProcessID	=	r.result.processID
            } else {
                debugLog("child: ok")
                execute(path, arguments, environment)
                fatalError("Returning from `execute` means the command was failed. This is unrecoverable error in child process side, so just abort the execution.")
            }
        } else {
            debugLog("`forkpty` failed.")
            
            ///	Below two lines are useless but inserted to suppress compiler error.
            _masterFileHandle	=	NSFileHandle()
            _childProcessID		=	0
            return	nil
        }
    }
    deinit {
        
    }
    
    
    public var	masterFileHandle:NSFileHandle {
        get {
            return	_masterFileHandle
        }
    }
    
    public var	childProcessID:pid_t {
        get {
            return	_childProcessID
        }
    }
    
    ///	Waits for child process finishes synchronously.
    public func waitUntilChildProcessFinishes() {
        var	stat_loc	=	0 as Int32
        let	childpid1	=	waitpid(_childProcessID, &stat_loc, 0)
        debugLog("child process quit: pid = \(childpid1)")
    }
    
    
    
    
    
    
    ////
    
    private let	_masterFileHandle:NSFileHandle
    private let	_childProcessID:pid_t

    
*/
}

