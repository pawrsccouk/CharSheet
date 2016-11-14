//
//  PWSpecialty.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

/// Class representing a Specialty in the CharSheet model.
/// A Specialty has a name and a value (e.g. for the skill ES: Mountain, the specialty might be "Find Food").
///
/// Generally specialties are completely user-defined as opposed to Skills which are mostly chosen from a set.
/// Each skill can have any number of specialties. The total value of all specialties attached to the skill
/// should not be more than the number of points in the skill.
///
/// This is a subclass of NSManagedObject adding XML support and direct access to the fields.

class Specialty : NSManagedObject
{
	@NSManaged var name: String?
	@NSManaged var value: Int16
	@NSManaged var order: Int16
	@NSManaged var parent: Skill!
}

// MARK: Overrides

extension Specialty
{
    override func awakeFromInsert()
	{
        super.awakeFromInsert()
        self.name  = ""
        self.value = Int16(0)
		self.order = Int16(0)
    }
}

// MARK: - PWXMLClient implementation

private let SPECIALTY = "specialty"
private enum Attribute: String { case NAME = "name", VALUE = "value" }

extension Specialty: XMLClient
{
    func asXML() -> DDXMLElement
	{
        func attribute(_ name: Attribute, value: String) -> DDXMLNode
		{
			return DDXMLNode.attribute(withName: name.rawValue, stringValue: value) as! DDXMLNode
		}
		let this = DDXMLElement.element(withName: SPECIALTY) as! DDXMLElement
        this.addAttribute( attribute(.NAME , value: self.name ?? "No name") )
        this.addAttribute( attribute(.VALUE, value: self.value.description) )
        return this
    }

	func updateFromXML(_ element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(name: element.name, expectedName: SPECIALTY)

		for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .NAME: self.name  = attrNode.stringValue
                case .VALUE:self.value = Int16(Int(attrNode.stringValue) ?? 0)
                }
            }
            else {
				throw XMLSupport.XMLError("Attribute \(attrNode.name) unrecognised in \(SPECIALTY)")
			}
        }
    }
}

