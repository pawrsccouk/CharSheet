//
//  Misc.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//

import Foundation
//#import "DDXML.h"

typealias VoidCallback         = () -> Void
typealias SimpleBlockPredicate = (AnyObject) -> Bool
typealias ArrayTransformBlock  = (AnyObject) -> AnyObject
typealias ArrayReduceBlock     = (AnyObject, AnyObject) -> AnyObject


extension NSArray {

    // Simple wrapper around filteredArrayUsingPredicate that creates the predicate
    // and ignores the binding dict.
    func filteredArrayUsingBlock(block: SimpleBlockPredicate) -> NSArray {
        return self.filteredArrayUsingPredicate(NSPredicate(block: { object, bindings in block(object) }))
    }

    // Returns a new array where each element is formed by calling block() on the item
    // in the existing array.
    func transformedArrayUsingBlock(block: ArrayTransformBlock) -> NSArray {
        var results = NSMutableArray(capacity: self.count)
        self.enumerateObjectsUsingBlock { obj, idx, stop in  results[idx] = block(obj) }
        return results;
    }

    // Call reduce on the array. This method calls <block> on the first 2 values
    // of the array, then again with the result of that and the next value and so on.
    // Returns the final result, the first item (if the array has only one item) or nil if the array is empty.
    func reducedArrayUsingBlock(block: ArrayReduceBlock) -> AnyObject? {

        if self.count == 0 { return nil }
        var p: AnyObject = self[0]
        for var i: NSInteger = 1, c: NSInteger = self.count; i < c; ++i {
            p = block(p, self[i])
        }
        return p;
    }
    
    
    // This version takes a starting value, and calls <block> with that value
    // and the first element, then goes through the subsequent elements calling block
    // on the results.  Returns <value> if the array is empty.

    func reducedArrayUsingBlock(block: ArrayReduceBlock, startingValue:AnyObject) -> AnyObject {
        var p: AnyObject = startingValue
        for i in self {
            p = block(p, i)
        }
        return p;
    }

}



extension NSOrderedSet {

    func filteredOrderedSetUsingBlock(block: SimpleBlockPredicate) -> NSOrderedSet
	{
        return self.filteredOrderedSetUsingPredicate(
			NSPredicate{ evaluatedObject, bindings in return block(evaluatedObject) })
    }
    
}

