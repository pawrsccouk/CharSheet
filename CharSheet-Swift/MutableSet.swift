//
//  MutableSet.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 03/11/2014.
//  Copyright (c) 2014 Patrick Wallace. All rights reserved.
//

import Foundation

/// Type-safe wrapper around NSMutableSet for Swift.
///
/// - todo: This may not be necessary as sets may now be part of the Swift standard library.

class MutableSet<T: AnyObject> {
    fileprivate var _set: NSMutableSet
    
    init() {
        _set = NSMutableSet()
    }
    
    init(array: [T]) {
        _set = NSMutableSet(array: array)
    }
    
    func add(_ t: T) {
        _set.add(t)
    }
    
    func remove(_ t: T) {
        _set.remove(t)
    }
    
    func contains(_ t: T) -> Bool {
        return _set.contains(t)
    }
    
    func filter(_ prediate: (T) -> Bool) -> MutableSet<T> {
        return MutableSet<T>(array: self.array.map{ $0 as T }.filter(prediate))
    }
    
    
    var array: [T] {
        get { return _set.allObjects as! [T] }
    }
    
    var count: Int {
        get { return _set.count }
    }
    
    func mutableCopy() -> MutableSet<T> {
        // Return a shallow copy of this object.
        return MutableSet(array: self.array)
    }

    func addObjects(_ newItems: [T]) {
        _set.addObjects(from: newItems)
    }
}

/// Add an array of items to the existing set.
func += <T: AnyObject> (set: inout MutableSet<T>, newItems: [T]) {
    set.addObjects(newItems)
}

/// Return a new set with the new items included.
func + <T: AnyObject> (set: MutableSet<T>, newItems: [T]) -> MutableSet<T> {
    let s = set.mutableCopy()
    s.addObjects(newItems)
    return s
}

/// Type-safe wrapper around NSMutableOrderedSet for Swift.
///
/// - todo: This may not be necessary as sets may now be part of the Swift standard library.

class MutableOrderedSet<T: AnyObject> {
    fileprivate var _set: NSMutableOrderedSet
    
    // Constructor. Construct as empty.
    init() {
        _set = NSMutableOrderedSet()
    }
    
	/// Constructor. Construct from an array of items.
    init(array: [T]) {
        _set = NSMutableOrderedSet(array: array)
    }
    
    func add(_ t: T) {
        _set.add(t)
    }
    
    func remove(_ t: T) {
        _set.remove(t)
    }
    
    func contains(_ t: T) -> Bool {
        return _set.contains(t)
    }
    
    func filter(_ prediate: (T) -> Bool) -> MutableOrderedSet<T> {
        return MutableOrderedSet<T>(array: self.array.map{ $0 as T }.filter(prediate))
    }
    
    var array: [T] {
        get { return _set.array as! [T] }
    }
    
    var count: Int {
        get { return _set.count }
    }
    
    func indexOfObject(_ object: T) -> Int {
        return _set.index(of: object)
    }
    
    func objectAtIndex(_ idx: Int) -> T {
        return _set.object(at: idx) as! T
    }
    
    subscript(idx: Int) -> T {
        return _set[idx] as! T
    }
    
    func addObjects(_ newObjects: [T])  {
        _set.addObjects(from: newObjects)
    }
    
    func removeObjectAtIndex(_ idx: Int) {
        _set.removeObject(at: idx)
    }

	func replaceObjectAtIndex(_ idx: Int, withObject object: AnyObject)
	{
		_set.replaceObject(at: idx, with: object)
	}

    func mutableCopy() -> MutableOrderedSet<T> {
        //return a shallow copy of this object
        return MutableOrderedSet(array: self.array)
    }
}

/// Add an array of items to the existing set.
func += <T: AnyObject> (set: inout MutableOrderedSet<T>, newItems: [T]) {
    set.addObjects(newItems)
}

/// Return a new set with the new items included.
func + <T: AnyObject> (set: MutableOrderedSet<T>, newItems: [T]) -> MutableOrderedSet<T> {
    let s = set.mutableCopy()
    s.addObjects(newItems)
    return s
}
