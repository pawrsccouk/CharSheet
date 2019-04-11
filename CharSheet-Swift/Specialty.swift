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

private let SPECIALTY = "specialty", NAME = "name", VALUE = "value"

extension Specialty: XMLClient
{
	func asXML() throws -> DDXMLElement
	{
		let element = DDXMLElement.element(withName: SPECIALTY) as! DDXMLElement
        element.addAttribute( try XMLSupport.attrExists(DDXMLNode.attribute(withName: NAME , stringValue: self.name ?? "No name"), name: NAME ) )
        element.addAttribute( try XMLSupport.attrExists(DDXMLNode.attribute(withName: VALUE, stringValue: self.value.description), name: VALUE) )
        return element
    }

	func update(from element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(element, expectedName: SPECIALTY)

		for attrNode in (element.attributes ?? []) {
			switch attrNode.name ?? "" {
			case NAME:	self.name  = attrNode.stringValue
			case VALUE:	self.value = Int16(attrNode.stringValue ?? "") ?? 0
			default:	throw XMLSupport.XMLError("Attribute \(attrNode.name ?? "NULL") unrecognised in \(SPECIALTY)")
			}
		}
	}
}

