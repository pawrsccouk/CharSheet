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
    
    
    private enum Element: String { case SPECIALTY = "specialty" }
    private enum Attribute: String { case NAME = "name", VALUE = "value" }
    
    func asXML() -> DDXMLElement {
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
		let this = DDXMLElement.elementWithName(Element.SPECIALTY.rawValue) as! DDXMLElement
        this.addAttribute( attribute(.NAME , self.name as! String) )
        this.addAttribute( attribute(.VALUE, self.value.description) )
        return this
    }

    func updateFromXML(element: DDXMLElement, inout error:NSError?) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: Element.SPECIALTY.rawValue, error: &error) { return false }
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .NAME: self.name  = attrNode.stringValue
                case .VALUE:self.value = Int16(attrNode.stringValue.toInt() ?? 0)
                }
            }
            else {
				return XMLSupport.setError(&error
					, text:"Attribute \(attrNode.name) unrecognised in \(Element.SPECIALTY)") }
        }
        return true
    }
    
}

