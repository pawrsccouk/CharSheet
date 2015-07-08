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
    @NSManaged var amount: Int16, reason: String?, parent: CharSheet!
    
    override func awakeFromInsert() -> Void
	{
        super.awakeFromInsert()
        self.amount  = 0
        self.reason  = "Reason"
    }
}
    // MARK: - XMLClient implementation

    // XML entity and attribute tags for this object.
private let XP_ENTRY = "xpEntry"
private enum Attribute: String { case AMOUNT = "amount", REASON = "reason" }

extension XPGain: XMLClient
{
    var asObject: NSObject {
		get { return self }
	}
    
    
    func asXML() -> DDXMLElement {
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        let this = DDXMLElement.elementWithName(XP_ENTRY) as! DDXMLElement
        this.addAttribute( attribute( .AMOUNT, self.amount.description) )
        this.addAttribute( attribute( .REASON, self.reason!) )
        return this
    }
    
    func updateFromXML(element: DDXMLElement) -> NilResult {
        let result = XMLSupport.validateElementName(element.name, expectedName: XP_ENTRY)
		if let err = result.error {
			return failure(err)
		}
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .AMOUNT : self.amount = Int16(attrNode.stringValue.toInt() ?? 0)
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
