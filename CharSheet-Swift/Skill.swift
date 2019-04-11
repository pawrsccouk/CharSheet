//
//  PWSkill.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

/// This Model object represents one skill. A character will have an array of these.
///
/// Each skill can have an array of specialties attached to it.
///
/// This class derives from NSManagedObject to add XML support and direct property access.

class Skill : NSManagedObject
{
	// MARK: Core Data
    @NSManaged var name: String?
	@NSManaged var ticks: Int16
	@NSManaged var value: Int16
	@NSManaged var order: Int16

	@NSManaged var parent: CharSheet!
	@NSManaged var specialties: NSMutableOrderedSet!

	// MARK: Private
	fileprivate let notificationCentre = NotificationCenter.default
}

// MARK: -

extension Skill
{
	// MARK: Overrides
    override func awakeFromInsert() -> Void
	{
        super.awakeFromInsert()
        name  = ""
        value = 0
		order = 0
    }

	override func awakeFromFetch()
	{
		super.awakeFromFetch()
		// Update the specialties array to match the order specified in the DB.
		specialties.sort(using: [NSSortDescriptor(key: "order", ascending: true)])
	}

	// MARK: Array of specialties.

	/// This is the name of a notification sent to the global NSNotificationCenter when I change the specialties.
	///
	/// I would prefer to use KVO or Protocols to handle this, but Swift cannot handle an array of protocol objects
	/// and KVO doesn't update when the contents of a set changes, only when the set itself does.
	/// So I use this global method by default.
	@nonobjc static let specialtiesChangedNotification = "SpecialtiesChangedNotification"

    func addSpecialty() -> Specialty
	{
		let newSpec = NSEntityDescription.insertNewObject(forEntityName: "Specialty", into:self.managedObjectContext!) as! Specialty

        newSpec.parent = self
        self.specialties.add(newSpec)
		notificationCentre.post(name: Notification.Name(rawValue: Skill.specialtiesChangedNotification), object: self)
        return newSpec
    }
    
    func removeSpecialtyAtIndex(_ index: Int) -> Void
	{
        let spec: Specialty = self.specialties[index] as! Specialty
        self.specialties.removeObject(at: index)
		self.managedObjectContext?.delete(spec)
		notificationCentre.post(name: Notification.Name(rawValue: Skill.specialtiesChangedNotification), object: self)
    }

    func moveSpecialtyFromIndex(_ sourceIndex: NSInteger, toIndex destIndex: NSInteger) -> Void
	{
        specialties.moveObjects(at: IndexSet(integer: sourceIndex), to:destIndex)
		notificationCentre.post(name: Notification.Name(rawValue: Skill.specialtiesChangedNotification), object: self)
    }

	var allSpecialties: [Specialty] {
		return (specialties?.array ?? []).map { $0 as! Specialty }
	}

	var specialtiesAsString: String {
		return allSpecialties.map { "\($0.name!) + \($0.value)" }.joined(separator: "; ")
	}


	// MARK: Methods

    func add(_ value: NSNumber, toAdd: NSInteger) -> NSNumber
	{
        return NSNumber(value: value.intValue + toAdd as Int)
    }



    func addTick()
	{
        if self.ticks >= 19 {
            self.ticks = 0
            self.value = self.value + 1
        }
        else {
            self.ticks = self.ticks + 1
        }
    }
}

    // MARK:- XMLClient implementation

private let SKILL = "skill", SPECIALTIES = "specialties"
private let NAME = "name", VALUE = "value", TICKS = "ticks"

extension Skill: XMLClient
{
	func asXML() throws -> DDXMLElement
	{
        let this = DDXMLElement.element(withName: SKILL) as! DDXMLElement
		try this.addAttribute( XMLSupport.attrExists(DDXMLNode.attribute(withName: NAME , stringValue: self.name ?? "")       , name: NAME ) )
        try this.addAttribute( XMLSupport.attrExists(DDXMLNode.attribute(withName: VALUE, stringValue: self.value.description), name: VALUE) )
        try this.addAttribute( XMLSupport.attrExists(DDXMLNode.attribute(withName: TICKS, stringValue: self.ticks.description), name: TICKS) )
        
        let specs = DDXMLElement.element(withName: SPECIALTIES) as! DDXMLElement
        this.addChild(specs)
		for child in allSpecialties {
			try specs.addChild(child.asXML())
		}
        return this
    }

    func update(from element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(element, expectedName: SKILL)

		for attrNode in element.attributes ?? [] {
			switch attrNode.name ?? "" {
			case NAME  : self.name  = attrNode.stringValue
			case VALUE : self.value = Int16(Int(attrNode.stringValue ?? "") ?? 0)
			case TICKS : self.ticks = Int16(Int(attrNode.stringValue ?? "") ?? 0)
			default    : throw XMLSupport.XMLError("Unrecognised attribute \(attrNode.name ?? "NULL") in skill")
			}
		}

        if element.childCount > 1 {
			NSLog("Warning: Skill has more than one child. Should be just one: \(SPECIALTIES)")
		}

        if(element.childCount > 0) {
            for specGroup in element.childElements {
                if specGroup.name == SPECIALTIES {
					let value = try XMLSupport.data(from: specGroup, createFunc: { addSpecialty() })
					self.specialties = (value.mutableCopy() as! NSMutableOrderedSet)
                }
                else {
					throw XMLSupport.XMLError("Unrecognised child \(specGroup.name ?? "NULL") of skill element.")
				}
            }
        }
    }
}






