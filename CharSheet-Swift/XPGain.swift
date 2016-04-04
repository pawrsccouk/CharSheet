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
private enum Attribute: String { case AMOUNT = "amount", REASON = "reason" }

extension XPGain: XMLClient
{
    func asXML() -> DDXMLElement
	{
        func attribute(name: Attribute, value: String) -> DDXMLNode
		{
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        let this = DDXMLElement.elementWithName(XP_ENTRY) as! DDXMLElement
        this.addAttribute( attribute( .AMOUNT, value: self.amount.description) )
        this.addAttribute( attribute( .REASON, value: self.reason!) )
        return this
    }
    
    func updateFromXML(element: DDXMLElement) throws
	{
        try XMLSupport.validateElementName(element.name, expectedName: XP_ENTRY)

		for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .AMOUNT : self.amount = Int16(Int(attrNode.stringValue) ?? 0)
                case .REASON : self.reason = attrNode.stringValue
                }
            }
            else {
				throw XMLSupport.XMLError("Unrecognised XP entry attribute: \(attrNode.name)")
			}
        }
    }
}
