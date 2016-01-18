//
//  BSD.swift
//  pty1
//
//  Created by Hoon H. on 2015/01/12.
//  Copyright (c) 2015 Eonil. All rights reserved.
//
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

import Foundation

//	BSD functions properly wrapped in more simple and typesafe Swift manner.

public struct FileDescriptor {
	public func toFileHandle(closeOnDealloc: Bool) -> NSFileHandle {
		return	NSFileHandle(fileDescriptor: value, closeOnDealloc: closeOnDealloc)
	}
	private var	value:Int32
}

public struct ForkResult {
	public var ok:Bool {
		get {
			return	value != 1
		}
	}
	public var isRunningInParentProcess:Bool {
		get {
			return	value > 0
		}
	}
	public var isRunningInChildProcess:Bool {
		get {
			return	value == 0
		}
	}
	
	///	Calling this in child process side will crash the program.
	public var processID:pid_t {
		get {
			precondition(isRunningInParentProcess, "You tried to read this property from child process side. It is not allowed.")
			return	value
		}
	}
	private var	value:pid_t
}



///	BSD `fork` function.
///	https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man2/fork.2.html
public func fork() -> ForkResult {
	let	pid1	=	Eonil____BSD_C_fork()
	return	ForkResult(value: pid1)
}

///	BSD `forkpty`.
///	https://developer.apple.com/library/ios/documentation/System/Conceptual/ManPages_iPhoneOS/man3/openpty.3.html
public func forkPseudoTeletypewriter() -> (result:ForkResult, master:FileDescriptor) {
	var	amaster		=	0 as Int32

    let	pid			=	forkpty(&amaster, nil, nil, nil)
    
	return	(ForkResult(value: pid), FileDescriptor(value: amaster))
}

///	BSD `execve`
///	Does not return on success.
///	Returns on any error.
///	https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/exec.3.html
public func execute(path:String, _ arguments:[String], _ environment:[String]) {
	path.withCString { (pathP:UnsafePointer<Int8>) -> () in
		withCPointerToNullTerminatingCArrayOfCStrings(arguments, { (argP:UnsafePointer<UnsafeMutablePointer<Int8>>) -> () in
			withCPointerToNullTerminatingCArrayOfCStrings(environment, { (envP:UnsafePointer<UnsafeMutablePointer<Int8>>) -> () in
				execve(pathP, argP, envP)
				return
			})
		})
		fatalError("`execve` call returned that means failure.")
	}
}

///	MARK:

///	Generates proper pointer arrays for `exec~` family calls.
///	Terminatin `NULL` is required for `exec~` family calls.
private func withCPointerToNullTerminatingCArrayOfCStrings(strings:[String], _ block:(UnsafePointer<UnsafeMutablePointer<Int8>>)->()) {
	///	Keep this in memory until the `block` to be finished.
	let	a	=	strings.map { (s:String) -> NSMutableData in
		let	b	=	s.cStringUsingEncoding(NSUTF8StringEncoding)!
		assert(b[b.endIndex-1] == 0)
		return	NSData.fromCCharArray(b).mutableCopy() as! NSMutableData
	}
	
	let	a1	=	a.map { (d:NSMutableData) -> UnsafeMutablePointer<Int8> in
		return	UnsafeMutablePointer<Int8>(d.mutableBytes)
		} + [nil as UnsafeMutablePointer<Int8>]
	//print(a1)
	
	a1.withUnsafeBufferPointer { (p:UnsafeBufferPointer<UnsafeMutablePointer<Int8>>) -> () in
		block(p.baseAddress)
	}
}
