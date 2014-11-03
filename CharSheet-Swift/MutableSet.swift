//
//  MutableSet.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 03/11/2014.
//  Copyright (c) 2014 Patrick Wallace. All rights reserved.
//

import Foundation

// Type-safe wrappers around NSMutableSet and NSMutableOrderedSet for Swift.

class MutableSet<T: AnyObject> {
    private var _set: NSMutableSet = NSMutableSet()
    
    func add(t: T) {
        _set.addObject(t)
    }
    
    func remove(t: T) {
        _set.removeObject(t)
    }
    
    func contains(t: T) -> Bool {
        return _set.containsObject(t)
    }
    
    var array: [T] {
        get { return _set.allObjects as [T] }
    }
    
    var count: Int {
        get { return _set.count }
    }
}

class MutableOrderedSet<T: AnyObject> {
    private var _set: NSMutableOrderedSet = NSMutableOrderedSet()
    
    func add(t: T) {
        _set.addObject(t)
    }
    
    func remove(t: T) {
        _set.removeObject(t)
    }
    
    func contains(t: T) -> Bool {
        return _set.containsObject(t)
    }
    
    var array: [T] {
        get { return _set.array as [T] }
    }
    
    var count: Int {
        get { return _set.count }
    }
}

