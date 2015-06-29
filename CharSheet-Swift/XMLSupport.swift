//
//  XMLSupport.c
//  CharSheet
//
//  Created by Patrick Wallace on 14/01/2013.
//
//

import Foundation


// Protocol for objects that load and save via XML.

//@objc
protocol XMLClient {
    
    // Update the object data from the XML element given. Call recursively for child objects.
    func updateFromXML(element: DDXMLElement, inout error: NSError?) -> Bool
    
    // Output the object (and it's children) as an XML element for inclusion in an XML tree.
    func asXML() -> DDXMLElement
    
    // The object cast to an NSObject (so that it can go in an NSArray)
    // TODO: If I mark the protocol as @objc, can I then just cast it?
    var asObject: NSObject{ get }
}

class XMLSupport {
    
    // Function used to return from a test with an error. Returns false, so you can use it as
    // if test-failed { return XMLError(&error, "Test failed with error condition %@", errorCondition) }
    
//    class func setError(error: NSErrorPointer, format: String, arguments: AnyObject...) -> Bool {
//        var errorText = String(format:format, arguments)
//        let domainXML_IMPORT = "CharSheet XML"
//        if error != nil {
//            let errorInfo = NSDictionary(object:errorText, forKey:NSHelpAnchorErrorKey)
//            error.memory = NSError(domain:domainXML_IMPORT, code:0, userInfo:errorInfo)
//        }
//        return false
//    }
   
    
    class func setError(inout error: NSError?, text: String) -> Bool {
        let domainXML_IMPORT = "CharSheet XML"
		let errorInfo = [NSHelpAnchorErrorKey: text]
        error = NSError(domain:domainXML_IMPORT, code:0, userInfo:errorInfo)
        return false
    }

    typealias CreateFunc = () -> XMLClient
    
    class func dataFromNodes(parent: DDXMLElement, createFunc: CreateFunc, inout error:NSError?) -> NSOrderedSet? {
        var xmlChildren: [DDXMLElement] = parent.children as! [DDXMLElement]
        var newLogs = NSMutableOrderedSet(capacity: xmlChildren.count)
        for element: DDXMLElement in xmlChildren  {
            let newEntry: XMLClient = createFunc()
            if !newEntry.updateFromXML(element, error: &error) {
                return nil
            }
            newLogs.addObject(newEntry.asObject)
        }
        return newLogs;
    }
    
    
    // Takes an optional name, an expected name and an error pointer.
    // If the name doesn't exist, or doesn't match the expected name, sets error and returns false.
    // Otherwise returns true.
    
    class func validateElementName(name: String?, expectedName: String, inout error: NSError?) -> Bool {
        if let s: String = name {
            if (s == expectedName) {
                return true
            }
        }
        let n = name ?? "[nil]"
        return XMLSupport.setError(&error, text:"Element \(n) unrecognised. Should be \(expectedName)")
    }
    
//    class func numberFromNode(node: DDXMLNode) -> NSNumber {
//        var v: NSString = node.stringValue
//        return NSNumber(integer:v.integerValue)
//    }


}

//
//BOOL PWXMLSetError(NSError **error, NSString *format, ...)
//{
//    va_list args;
//    va_start(args, format);
//    NSString *errorText = [[NSString alloc] initWithFormat:format arguments:args];
//    va_end(args);
//    
//    NSString *domainXML_IMPORT = @"CharSheet XML Import";
//    if(error) {
//        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorText
//                                                              forKey:NSHelpAnchorErrorKey];
//        
//        *error = [NSError errorWithDomain:domainXML_IMPORT code:0 userInfo:errorInfo];
//    }
//    return NO;
//}
//
//    // Loop through the children of parent, creating a new Core Data object by calling createBlock()
//    // and then calling updateFromXML:error: on the new object. Returns the set of objects, or nil on failure.
//NSOrderedSet *PWXMLDataFromNodes(DDXMLElement *parent, id(^createBlock)(), NSError **error)
//{
//    NSMutableOrderedSet *newLogs = [NSMutableOrderedSet orderedSetWithCapacity:parent.childCount];
//    for(DDXMLElement *element in parent.children) {
//        id<PWXMLClient> newEntry = createBlock();
//        if(! [newEntry updateFromXML:element error:error])
//            return nil;
//        [newLogs addObject:newEntry];
//    }
//    return newLogs;
//}
//
//NSNumber *numberFromNode(DDXMLNode *node) { return [NSNumber numberWithInteger:node.stringValue.integerValue]; }
