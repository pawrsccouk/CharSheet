//
//  PWXPGain.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import CoreData
import Foundation

/// This Model object represents one time the character gained XP. A character will have an array of these.
///
/// Each XP Gain has an amount and a reason.
///
/// This class derives from NSManagedObject to add XML support and direct property access.

class XPGain : NSManagedObject
{
    
    // MARK: - Properties - CoreData
	@NSManaged var amount: Int16
	@NSManaged var reason: String?
	@NSManaged var parent: CharSheet!
	@NSManaged var order: Int16
}

// MARK: -

extension XPGain
{
	// MARK: Overrides
	override func awakeFromInsert() -> Void
	{
        super.awakeFromInsert()
        amount = 0
        reason = "Reason"
		order  = 0
    }
}


// MARK: - XMLClient implementation

// XML entity and attribute tags for this object.
private let XP_ENTRY = "xpEntry"
private let AMOUNT = "amount", REASON = "reason"

extension XPGain: XMLClient
{
	func asXML() throws -> DDXMLElement
	{
		let element = DDXMLElement.element(withName: XP_ENTRY) as! DDXMLElement
		let amtAttr = DDXMLNode.attribute(withName: AMOUNT, stringValue: self.amount.description)
		try element.addAttribute( XMLSupport.attrExists(amtAttr, name: AMOUNT) )
		let rsnAttr = DDXMLNode.attribute(withName: REASON, stringValue: self.reason ?? "")
		try element.addAttribute( XMLSupport.attrExists(rsnAttr, name: REASON) )
        return element
    }
    
	func update(from element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(element, expectedName: XP_ENTRY)

		for attrNode in element.allAttributes {
			switch attrNode.name ?? "" {
			case AMOUNT : self.amount = Int16(Int(attrNode.stringValue ?? "") ?? 0)
			case REASON : self.reason = attrNode.stringValue
			default     : throw XMLSupport.XMLError("Unrecognised XP entry attribute: \(attrNode.name ?? "NULL")")
			}
		}
	}
}
