//
//  PWXPGain.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import CoreData
import Foundation

class XPGain : NSManagedObject
{
    
    // MARK: - Properties - CoreData
	@NSManaged var amount: Int16, reason: String?, parent: CharSheet!, order: Int16

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
    var asObject: NSObject {
		return self
	}
    
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
    
    func updateFromXML(element: DDXMLElement) -> NilResult
	{
        let result = XMLSupport.validateElementName(element.name, expectedName: XP_ENTRY)
		if let err = result.error {
			return failure(err)
		}
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .AMOUNT : self.amount = Int16(Int(attrNode.stringValue) ?? 0)
                case .REASON : self.reason = attrNode.stringValue
                }
            }
            else {
				return XMLSupport.XMLFailure("Unrecognised XP entry attribute: \(attrNode.name)")
			}
        }
        return success()
    }
}
