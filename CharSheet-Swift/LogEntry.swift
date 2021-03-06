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
	@NSManaged var dateTime: Date
	@NSManaged var summary: String?
	@NSManaged var change: String?
	@NSManaged var parent: CharSheet!
}

// MARK: -

extension LogEntry
{
	// MARK: Overrides
    override func awakeFromInsert() {
        super.awakeFromInsert()
        self.dateTime = Date()
        self.summary  = "Summary"
        self.change   = "Description of change."
    }
}

/// A date formatter designed to output dates to XML files 
///
/// This outputs dates in a format which will not change even if the user's locale does.
private var xmlDateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	// en_US_POSIX is a locale which gives standard US-like date and time formats and which is guaranteed never to change.
	dateFormatter.locale = Locale(identifier: "en_US_POSIX")
	dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
	return dateFormatter
}()

/// This was the old date formatter, kept for backwards compatibility.
///
/// - note: Do not write dates with this, it is just for reading old formats.
///         Use **xmlDateFormatter** instead.
private var backwardsCompatibleDateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.dateStyle = .full
	dateFormatter.timeStyle = .full
	return dateFormatter
}()

// XML entity and attribute tags for this object.
private let LOG_ENTRY = "logEntry"
private let DATE_TIME = "dateTime", SUMMARY = "summary"

    // MARK: - PWXMLClient implementation
    
extension LogEntry: XMLClient
{
	func asXML() throws -> DDXMLElement
	{
        let element = DDXMLElement.element(withName: LOG_ENTRY, stringValue:self.change ?? "") as! DDXMLElement
		let dateString = xmlDateFormatter.string(from: self.dateTime), summaryString = self.summary ?? ""
		let dateAttr = DDXMLNode.attribute(withName: DATE_TIME, stringValue: dateString)
		let summAttr = DDXMLNode.attribute(withName: SUMMARY  , stringValue: summaryString)
		try element.addAttribute( XMLSupport.attrExists(dateAttr, name: DATE_TIME) )
		try element.addAttribute( XMLSupport.attrExists(summAttr, name: SUMMARY  ) )
        return element
    }

    
    
    func update(from element: DDXMLElement) throws
	{
		/// Attempt to parse a date using multiple date formatters for backwards compatibility.
		/// 
		/// This first tries to parse the date using the 'standard' xml date formatter provided.
		/// If this fails, it tries to use the default date formatter, which was how we used to parse dates.
		/// This allows me to update the format while still being able to load in old files.
		func parseDate(_ dateText: String) throws -> Date
		{
			var date = xmlDateFormatter.date(from: dateText)
			if date == nil {
				date = backwardsCompatibleDateFormatter.date(from: dateText)
			}
			guard let d = date else {
				throw XMLSupport.XMLError("Error converting \(dateText) into a date.")
			}
			return d
		}


		try XMLSupport.validateElement(element, expectedName: LOG_ENTRY)
		for attrNode in element.allAttributes {
			switch attrNode.name ?? "" {
			case DATE_TIME: self.dateTime = try parseDate(attrNode.stringValue ?? "")
			case SUMMARY:   self.summary  = attrNode.stringValue
			default:		throw XMLSupport.XMLError("Unrecognised log entry attribute: \(attrNode.name ?? "NULL")")
			}
		}
		self.change = element.stringValue
	}
}
