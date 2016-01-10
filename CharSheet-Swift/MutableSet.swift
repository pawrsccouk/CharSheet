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
    private var _set: NSMutableSet
    
    init() {
        _set = NSMutableSet()
    }
    
    init(array: [T]) {
        _set = NSMutableSet(array: array)
    }
    
    func add(t: T) {
        _set.addObject(t)
    }
    
    func remove(t: T) {
        _set.removeObject(t)
    }
    
    func contains(t: T) -> Bool {
        return _set.containsObject(t)
    }
    
    func filter(prediate: (T) -> Bool) -> MutableSet<T> {
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

    func addObjects(newItems: [T]) {
        _set.addObjectsFromArray(newItems)
    }
}

/// Add an array of items to the existing set.
func += <T: AnyObject> (inout set: MutableSet<T>, newItems: [T]) {
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
    private var _set: NSMutableOrderedSet
    
    // Constructor. Construct as empty.
    init() {
        _set = NSMutableOrderedSet()
    }
    
	/// Constructor. Construct from an array of items.
    init(array: [T]) {
        _set = NSMutableOrderedSet(array: array)
    }
    
    func add(t: T) {
        _set.addObject(t)
    }
    
    func remove(t: T) {
        _set.removeObject(t)
    }
    
    func contains(t: T) -> Bool {
        return _set.containsObject(t)
    }
    
    func filter(prediate: (T) -> Bool) -> MutableOrderedSet<T> {
        return MutableOrderedSet<T>(array: self.array.map{ $0 as T }.filter(prediate))
    }
    
    var array: [T] {
        get { return _set.array as! [T] }
    }
    
    var count: Int {
        get { return _set.count }
    }
    
    func indexOfObject(object: T) -> Int {
        return _set.indexOfObject(object)
    }
    
    func objectAtIndex(idx: Int) -> T {
        return _set.objectAtIndex(idx) as! T
    }
    
    subscript(idx: Int) -> T {
        return _set[idx] as! T
    }
    
    func addObjects(newObjects: [T])  {
        _set.addObjectsFromArray(newObjects)
    }
    
    func removeObjectAtIndex(idx: Int) {
        _set.removeObjectAtIndex(idx)
    }

	func replaceObjectAtIndex(idx: Int, withObject object: AnyObject)
	{
		_set.replaceObjectAtIndex(idx, withObject: object)
	}

    func mutableCopy() -> MutableOrderedSet<T> {
        //return a shallow copy of this object
        return MutableOrderedSet(array: self.array)
    }
}

/// Add an array of items to the existing set.
func += <T: AnyObject> (inout set: MutableOrderedSet<T>, newItems: [T]) {
    set.addObjects(newItems)
}

/// Return a new set with the new items included.
func + <T: AnyObject> (set: MutableOrderedSet<T>, newItems: [T]) -> MutableOrderedSet<T> {
    let s = set.mutableCopy()
    s.addObjects(newItems)
    return s
}
