//
//  PWSpecialty.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData


class Specialty : NSManagedObject {
    
    @NSManaged var name: String?, value: Int16, parent: Skill!
    
    override func awakeFromInsert() -> Void {
        super.awakeFromInsert()
        self.name = ""
        self.value = 0
    }
}

// MARK: - PWXMLClient implementation
private let SPECIALTY = "specialty"
private enum Attribute: String { case NAME = "name", VALUE = "value" }

extension Specialty: XMLClient {

    var asObject: NSObject { get { return self } }
    
    
    func asXML() -> DDXMLElement {
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
		let this = DDXMLElement.elementWithName(SPECIALTY) as! DDXMLElement
        this.addAttribute( attribute(.NAME , self.name ?? "No name") )
        this.addAttribute( attribute(.VALUE, self.value.description) )
        return this
    }

    func updateFromXML(element: DDXMLElement) -> NilResult {
		let result = XMLSupport.validateElementName(element.name, expectedName: SPECIALTY)
		if let e = result.error {
			return failure(e)
		}
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .NAME: self.name  = attrNode.stringValue
                case .VALUE:self.value = Int16(attrNode.stringValue.toInt() ?? 0)
                }
            }
            else {
				return XMLSupport.XMLFailure("Attribute \(attrNode.name) unrecognised in \(SPECIALTY)")
			}
        }
        return success()
    }
}

