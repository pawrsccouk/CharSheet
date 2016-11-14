//
//  PWSkill.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

private func addSpecialty(_ managedObjectContext: NSManagedObjectContext) -> Specialty
{
    return NSEntityDescription
		.insertNewObject(forEntityName: "Specialty",
			into:managedObjectContext) as! Specialty
}

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

    func appendSpecialty() -> Specialty
	{
        let newSpec = addSpecialty(self.managedObjectContext!)
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


	var specialtiesAsString: String {
		var str = ""
		if let specArray = self.specialties?.array {
			let specs = specArray.map{ $0 as! Specialty }
			str = specs.map{ "\($0.name!) + \($0.value)" }.joined(separator: "; ")
		}
		return str
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

    // MARK:- PWXMLClient implementation

extension Skill: XMLClient
{
    fileprivate enum Element: String  { case SKILL = "skill", SPECIALTIES = "specialties" }
    fileprivate enum Attribute: String { case NAME = "name", VALUE = "value", TICKS = "ticks" }
    
    
    func asXML() -> DDXMLElement
	{
        func attribute(_ name: Attribute, value: String!) -> DDXMLNode
		{
			return DDXMLNode.attribute(withName: name.rawValue, stringValue: value) as! DDXMLNode
		}
        
        let this = DDXMLElement.element(withName: Element.SKILL.rawValue) as! DDXMLElement
        this.addAttribute( attribute(Attribute.NAME , value: self.name             ) )
        this.addAttribute( attribute(Attribute.VALUE, value: self.value.description) )
        this.addAttribute( attribute(Attribute.TICKS, value: self.ticks.description) )
        
        let specs = DDXMLElement.element(withName: Element.SPECIALTIES.rawValue) as! DDXMLElement
        this.addChild(specs)
		//    specialties.enumerateObjects { (obj, idx, stop) in specs.addChild(obj.asXML()) }
		for child in specialties {
			specs.addChild((child as! XMLClient).asXML())
		}
        return this
    }

    func updateFromXML(_ element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(name: element.name, expectedName: Element.SKILL.rawValue)

        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .NAME  : self.name  = attrNode.stringValue
                case .VALUE : self.value = Int16(Int(attrNode.stringValue) ?? 0)
                case .TICKS : self.ticks = Int16(Int(attrNode.stringValue) ?? 0)
                }
            }
            else {
				throw XMLSupport.XMLError("Unrecognised attribute \(attrNode.name) in skill")
			}
        }

        if element.childCount != 1 {
			NSLog("Warning: Skill has more than one child. Should be just one: \(Element.SPECIALTIES)")
		}

        if(element.childCount > 0) {
            for specGroup in (element.children as! [DDXMLElement]) {
                if specGroup.name == Element.SPECIALTIES.rawValue {
					let value = try XMLSupport.dataFromNodes(specGroup, createFunc: { addSpecialty(self.managedObjectContext!) })
					self.specialties = value.mutableCopy() as! NSMutableOrderedSet
                }
                else {
					throw XMLSupport.XMLError("Unrecognised child \(specGroup.name) of skill element.")
				}
            }
        }
    }
}






