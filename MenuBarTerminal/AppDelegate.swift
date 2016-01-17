//
//  AppDelegate.swift
//  MenuBarTerminal
//
//  Created by mavenlink on 1/16/16.
//
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

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
        webView.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: "https://archive.org")!))
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

