//
//  PWSkill.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

func addSpecialty(managedObjectContext: NSManagedObjectContext) -> Specialty {
    return NSEntityDescription.insertNewObjectForEntityForName("Specialty",
		inManagedObjectContext:managedObjectContext) as! Specialty
}

class Skill : NSManagedObject
{
    @NSManaged var name: String?, ticks: Int16, value: Int16, order: Int16
	@NSManaged var parent: CharSheet!, specialties: NSMutableOrderedSet!

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
		specialties.sortUsingDescriptors([NSSortDescriptor(key: "order", ascending: true)])
	}

	// MARK: Array of specialties.

    func appendSpecialty() -> Specialty
	{
        let newSpec = addSpecialty(self.managedObjectContext!)
        newSpec.parent = self
        self.specialties.addObject(newSpec)
        return newSpec
    }
    
    func removeSpecialtyAtIndex(index: Int) -> Void
	{
        let spec: Specialty = self.specialties[index] as! Specialty
        self.specialties.removeObjectAtIndex(index)
        self.managedObjectContext?.deleteObject(spec)
    }

    func moveSpecialtyFromIndex(sourceIndex: NSInteger, toIndex destIndex: NSInteger) -> Void
	{
        self.specialties.moveObjectsAtIndexes(NSIndexSet(index: sourceIndex), toIndex:destIndex)
    }


	var specialtiesAsString: String {
		var str = ""
		if let specArray = self.specialties?.array {
			let specs = specArray.map{ $0 as! Specialty }
			str = specs.map{ "\($0.name!) + \($0.value)" }.joinWithSeparator("; ")
		}
		return str
	}


	// MARK: Methods

    func add(value: NSNumber, toAdd: NSInteger) -> NSNumber
	{
        return NSNumber(integer:value.integerValue + toAdd)
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
    private enum Element: String  { case SKILL = "skill", SPECIALTIES = "specialties" }
    private enum Attribute: String { case NAME = "name", VALUE = "value", TICKS = "ticks" }
    
    
    func asXML() -> DDXMLElement
	{
        func attribute(name: Attribute, value: String!) -> DDXMLNode
		{
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        
        let this = DDXMLElement.elementWithName(Element.SKILL.rawValue) as! DDXMLElement
        this.addAttribute( attribute(Attribute.NAME , value: self.name             ) )
        this.addAttribute( attribute(Attribute.VALUE, value: self.value.description) )
        this.addAttribute( attribute(Attribute.TICKS, value: self.ticks.description) )
        
        let specialties = DDXMLElement.elementWithName(Element.SPECIALTIES.rawValue) as! DDXMLElement
        this.addChild(specialties)
        self.specialties.enumerateObjectsUsingBlock { obj, idx, stop in specialties.addChild(obj.asXML()) }
        return this
    }

    func updateFromXML(element: DDXMLElement) throws
	{
        try XMLSupport.validateElementName(element.name, expectedName: Element.SKILL.rawValue)

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






