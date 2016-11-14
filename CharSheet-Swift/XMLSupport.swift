//
//  XMLSupport.c
//  CharSheet
//
//  Created by Patrick Wallace on 14/01/2013.
//
//

import Foundation


/// Protocol for model objects that load and save via XML.
@objc
protocol XMLClient
{
	/// Update the object data from the XML element given. Call recursively for child objects.
    func updateFromXML(_ element: DDXMLElement) throws
    
	/// Output the object (and it's children) as an XML element for inclusion in an XML tree.
    func asXML() -> DDXMLElement
}

struct XMLSupport
{
	static func XMLError(_ text: String) -> NSError
	{
        let domainXML_IMPORT = "CharSheet XML"
		let errorInfo = [
			NSHelpAnchorErrorKey     : text,
			NSLocalizedDescriptionKey: text]
        return NSError(domain:domainXML_IMPORT, code:0, userInfo:errorInfo)
	}

    typealias CreateFunc = () -> XMLClient
    
    static func dataFromNodes(
		_ parent     : DDXMLElement,
		createFunc : CreateFunc) throws -> NSOrderedSet
	{
        let xmlChildren = parent.children as? [DDXMLElement] ?? []
        let newLogs = NSMutableOrderedSet(capacity: xmlChildren.count)
        for element: DDXMLElement in xmlChildren {
            let newEntry: XMLClient = createFunc()
			try newEntry.updateFromXML(element)
			newLogs.add(newEntry)
        }
        return newLogs
    }

    
    // Takes an optional name, an expected name and an error pointer.
    // If the name doesn't exist, or doesn't match the expected name, sets error and returns false.
    // Otherwise returns true.
    
    static func validateElement(name: String?, expectedName: String) throws
	{
        if let s = name, s == expectedName {
			return // Success
        }
        let n = name ?? "[nil]"
		throw XMLError("Element \(n) unrecognised. Should be \(expectedName)")
    }
}

