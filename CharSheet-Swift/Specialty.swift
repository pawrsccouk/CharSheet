//
//  PWSpecialty.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData


class Specialty : NSManagedObject, XMLClient {
    
    @NSManaged var name: NSString?, value: Int16, parent: Skill!
    
    override func awakeFromInsert() -> Void
    {
        super.awakeFromInsert()
        self.name = ""
        self.value = 0
    }
    
    
    
    // MARK - PWXMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    
    let elementSPECIALTY = "specialty"
    let attributeNAME    = "name"
    let attributeVALUE   = "value"
    
    func asXML() -> DDXMLElement {
        var this  = DDXMLElement.elementWithName(elementSPECIALTY) as DDXMLElement
        var name  = DDXMLNode.attributeWithName(attributeNAME , stringValue:self.name) as DDXMLElement
        var value = DDXMLNode.attributeWithName(attributeVALUE, stringValue:self.value.description) as DDXMLElement
        this.addAttribute(name)
        this.addAttribute(value)
        return this
    }
    
    func updateFromXML(element: DDXMLElement, inout error:NSError?) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: elementSPECIALTY, error: &error) { return false }
        for attrNode in (element.attributes  as [DDXMLNode]) {
            if      attrNode.name == attributeNAME  { self.name  = attrNode.stringValue }
            else if attrNode.name == attributeVALUE {  self.value = Int16(attrNode.stringValue.toInt() ?? 0) }
            else { return XMLSupport.setError(&error, text:"Attribute \(attrNode.name) unrecognised in \(elementSPECIALTY)") }
        }
        return true
    }
    
}

