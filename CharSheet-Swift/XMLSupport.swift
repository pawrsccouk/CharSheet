//
//  XMLSupport.c
//  CharSheet
//
//  Created by Patrick Wallace on 14/01/2013.
//
//

import Foundation


/// Protocol for model objects that load and save via XML.
protocol XMLClient
{
	/// Update the object data from the XML element given. Call recursively for child objects.
    func updateFromXML(element: DDXMLElement) -> Result<()>
    
	/// Output the object (and it's children) as an XML element for inclusion in an XML tree.
    func asXML() -> DDXMLElement
    
	/// The object cast to an NSObject (so that it can go in an NSArray)
	///
	/// :TODO: If I mark the protocol as @objc, can I then just cast it?
	var asObject: NSObject{ get }
}

struct XMLSupport
{
    static func XMLFailure(text: String) -> NilResult
	{
        return failure(XMLError(text))
    }

	static func XMLError(text: String) -> NSError
	{
        let domainXML_IMPORT = "CharSheet XML"
		let errorInfo = [NSHelpAnchorErrorKey: text]
        return NSError(domain:domainXML_IMPORT, code:0, userInfo:errorInfo)
	}

    typealias CreateFunc = () -> XMLClient
    
    static func dataFromNodes(parent: DDXMLElement,
		createFunc                  : CreateFunc) -> Result<NSOrderedSet>
	{
        var xmlChildren: [DDXMLElement] = parent.children as! [DDXMLElement]
        var newLogs = NSMutableOrderedSet(capacity: xmlChildren.count)
        for element: DDXMLElement in xmlChildren  {
            let newEntry: XMLClient = createFunc()
			let result = newEntry.updateFromXML(element)
			if let e = result.error {
				return failure(e)
			}
			newLogs.addObject(newEntry.asObject)
        }
        return success(newLogs)
    }
    
    
    // Takes an optional name, an expected name and an error pointer.
    // If the name doesn't exist, or doesn't match the expected name, sets error and returns false.
    // Otherwise returns true.
    
    static func validateElementName(
		name        : String?,
		expectedName: String) -> NilResult
	{
        if let s = name where s == expectedName {
			return success()
        }
        let n = name ?? "[nil]"
		return XMLFailure("Element \(n) unrecognised. Should be \(expectedName)")
    }
}

