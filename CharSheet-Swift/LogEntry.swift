//
//  PWLogEntry.m
//  CharSheet
//
//  Created by Patrick Wallace on 03/01/2013.
//
//

import Foundation
import CoreData

/// This model object represents one entry in the log of dice rolled.
///
/// This is a subclass of NSManagedObject, adding XML support and direct access to the properties.

class LogEntry : NSManagedObject
{
    // MARK: CoreData dynamic properties.
    @NSManaged var dateTime: NSDate, summary: String?, change: String?, parent: CharSheet!
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        self.dateTime = NSDate()
        self.summary  = "Summary"
        self.change   = "Description of change."
    }
}

private var fullDateFormatter: NSDateFormatter = {
	let cachedFormatter = NSDateFormatter()
	cachedFormatter.dateStyle = .FullStyle
	cachedFormatter.timeStyle = .FullStyle
	return cachedFormatter
}()

// XML entity and attribute tags for this object.
private let LOG_ENTRY = "logEntry"
private enum Attribute: String { case DATE_TIME = "dateTime", SUMMARY = "summary" }

    // MARK: - PWXMLClient implementation
    
extension LogEntry: XMLClient
{
	func asXML() -> DDXMLElement
	{
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        let this = DDXMLElement.elementWithName(LOG_ENTRY, stringValue:self.change) as! DDXMLElement
        this.addAttribute( attribute(.DATE_TIME, value: fullDateFormatter.stringFromDate(self.dateTime)) )
        this.addAttribute( attribute(.SUMMARY  , value: self.summary!) )
        return this;
    }

    
    
    func updateFromXML(element: DDXMLElement) throws
	{
        try XMLSupport.validateElementName(element.name, expectedName: LOG_ENTRY)
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .DATE_TIME: self.dateTime = fullDateFormatter.dateFromString(attrNode.stringValue)!
                case .SUMMARY:   self.summary  = attrNode.stringValue
                }
            }
            else {
				throw XMLSupport.XMLError("Unrecognised log entry attribute: \(attrNode.name)")
			}
        }
        self.change = element.stringValue
    }
}
