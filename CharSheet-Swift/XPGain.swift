//
//  PWXPGain.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import CoreData
import Foundation

class XPGain : NSManagedObject, XMLClient {
    
    // MARK: - Properties - CoreData
    @NSManaged var amount: Int16, reason: String?, parent: CharSheet!
    
    override func awakeFromInsert() -> Void {
        super.awakeFromInsert()
        self.amount  = 0
        self.reason  = "Reason"
    }
    
    // MARK: - PWXMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    // XML entity and attribute tags for this object.
    private enum Element: String { case XP_ENTRY = "xpEntry" }
    private enum Attribute: String { case AMOUNT = "amount", REASON = "reason" }
    
    func asXML() -> DDXMLElement {
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        let this    = DDXMLElement.elementWithName(Element.XP_ENTRY.rawValue) as! DDXMLElement
        this.addAttribute( attribute( .AMOUNT, self.amount.description) )
        this.addAttribute( attribute( .REASON, self.reason!) )
        return this
    }
    
    func updateFromXML(element: DDXMLElement, inout error:NSError?) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: Element.XP_ENTRY.rawValue, error: &error) {
				return false
		}
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .AMOUNT : self.amount = Int16(attrNode.stringValue.toInt() ?? 0)
                case .REASON : self.reason = attrNode.stringValue
                }
            }
            else {
				return XMLSupport.setError(&error, text: "Unrecognised XP entry attribute: \(attrNode.name)")
			}
        }
        return true
    }
}
