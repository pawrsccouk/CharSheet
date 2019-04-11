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
    func update(from element: DDXMLElement) throws
    
	/// Output the object (and it's children) as an XML element for inclusion in an XML tree.
	func asXML() throws -> DDXMLElement
}

struct XMLSupport
{
	/// Work-around for the fact that the KissXML library returns attributes with a type of 'id' instead of DDXMLNode.
	/// Converts attr into a DDXMLNode object and returns it.
	/// Throws an NSError object if attr is nil or not a DDXMLNode object and uses the name to describe what failed.
	static func attrExists(_ attr: Any?, name: String) throws -> DDXMLNode
	{
		guard let a = attr as? DDXMLNode else {
			throw XMLSupport.XMLError("Failed to create a new attribute for '\(name)'")
		}
		return a
	}

	static func XMLError(_ text: String) -> NSError
	{
        let domainXML_IMPORT = "CharSheet XML"
		let errorInfo = [
			NSHelpAnchorErrorKey     : text,
			NSLocalizedDescriptionKey: text]
        return NSError(domain:domainXML_IMPORT, code:0, userInfo:errorInfo)
	}

    typealias CreateFunc = (() -> XMLClient)

	/// This takes data from an XML Element and uses it to create new Model objects (e.g. Skill, LogEntry etc.)
	///
	/// - parameter parent: The XML element to search for child-nodes.
	/// - parameter createFunc: A function which will be called for each child. It must return a newly-created entry for that child (a NSManagedObject subclass).
	///
	/// For each child, createFunc is called to create a new CoreData object for the child. This has it's updateFrom method called to populate it
	/// with the data extracted from the XML.  The set of new children is then returned in the same order we retrieved them from the XML.
    static func data(from parent: DDXMLElement, createFunc: CreateFunc) throws -> NSOrderedSet
	{
        let xmlChildren = parent.children ?? []
        let newChildren = NSMutableOrderedSet(capacity: xmlChildren.count)
        for element in xmlChildren {
            let newEntry = createFunc()
			try newEntry.update(from: element as! DDXMLElement)
			newChildren.add(newEntry)
        }
        return newChildren
    }

    
	/// Takes an element and an expected name and throws if they do not match.
	///
	/// If the element's name doesn't exist, or doesn't match the expected name, throws an exception.

	static func validateElement(_ element: DDXMLElement, expectedName: String) throws
	{
        if let s = element.name, s == expectedName {
			return // Success
        }
        let n = element.name ?? "[nil]"
		throw XMLError("Element \(n) unrecognised. Should be \(expectedName)")
    }
}


extension DDXMLElement
{
	/// Returns an array of all the children of this element.
	/// The array is guaranteed to exist and the contents are converted to DDXMLElement objects.
	var childElements: [DDXMLElement] {
		return (children ?? []).map { $0 as! DDXMLElement }
	}

	/// Returns an array of all the attributes in the element.
	var allAttributes: [DDXMLNode] {
		return attributes ?? []
	}
}
