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
    @NSManaged var amount: NSNumber, reason: String, parent: CharSheet?
    
    override func awakeFromInsert() -> Void {
        super.awakeFromInsert()
        self.amount  = 0
        self.reason  = "Reason"
    }
    
    // MARK: - PWXMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    // XML entity and attribute tags for this object.
    let elementXP_ENTRY   = "xpEntry"
    let attributeAMOUNT   = "amount"
    let attributeREASON   = "reason"
    
    func asXML() -> DDXMLElement {
        var this    = DDXMLElement.elementWithName(elementXP_ENTRY) as DDXMLElement
        var amount  = DDXMLNode.attributeWithName(attributeAMOUNT, stringValue:self.amount.stringValue) as DDXMLNode
        var reason  = DDXMLNode.attributeWithName(attributeREASON, stringValue:self.reason) as DDXMLNode
        this.addAttribute(amount)
        this.addAttribute(reason)
        return this
    }
    
    func updateFromXML(element: DDXMLElement, error:NSErrorPointer) -> Bool {
        if !XMLSupport.validateElementName(element.name(), expectedName: elementXP_ENTRY, error: error) { return false }
        for attrNode in (element.attributes() as [DDXMLNode]) {
            let nodeName = attrNode.name()
            if      nodeName == attributeAMOUNT { self.amount = XMLSupport.numberFromNode(attrNode) }
            else if nodeName == attributeREASON { self.reason = attrNode.stringValue() }
            else { return XMLSupport.setError(error, format: "Unrecognised XP entry attribute: %@", arguments: attrNode.name())
            }
        }
        return true
    }
}
