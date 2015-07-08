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

class Skill : NSManagedObject {

    @NSManaged var name: String?, ticks: Int16, value: Int16, parent: CharSheet!, specialties: NSMutableOrderedSet!

    override func awakeFromInsert() -> Void {
        super.awakeFromInsert()
        self.name = ""
        self.value = 0
    }

	// MARK: Array of specialties.

    func appendSpecialty() -> Specialty {
        var newSpec = addSpecialty(self.managedObjectContext!)
        newSpec.parent = self
        self.specialties.addObject(newSpec)
        return newSpec
    }
    
    func removeSpecialtyAtIndex(index: Int) -> Void {
        var spec: Specialty = self.specialties[index] as! Specialty
        self.specialties.removeObjectAtIndex(index)
        self.managedObjectContext?.deleteObject(spec)
    }

    func moveSpecialtyFromIndex(sourceIndex: NSInteger, toIndex destIndex: NSInteger) -> Void {
        self.specialties.moveObjectsAtIndexes(NSIndexSet(index: sourceIndex), toIndex:destIndex)
    }


    var specialtiesAsString: String {
        var str = "", first = true
        for spec in (self.specialties.array as! [Specialty]) {
            if first {
                str += "\(spec.name!) +\(spec.value)"
                first = false
            } else {
                str += "; \(spec.name!) +\(spec.value)"
            }
        }
        return str
    }


	// MARK: Methods

    func add(value: NSNumber, toAdd: NSInteger) -> NSNumber {
        return NSNumber(integer:value.integerValue + toAdd)
    }



    func addTick() {
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

extension Skill: XMLClient {

    var asObject: NSObject { get { return self } }
    
    private enum Element: String  { case SKILL = "skill", SPECIALTIES = "specialties" }
    private enum Attribute: String { case NAME = "name", VALUE = "value", TICKS = "ticks" }
    
    
    func asXML() -> DDXMLElement {
        let this = DDXMLElement.elementWithName(Element.SKILL.rawValue) as! DDXMLElement
        func attribute(name: Attribute, value: String!) -> DDXMLNode { return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode }
        
        this.addAttribute( attribute(Attribute.NAME , self.name             ) )
        this.addAttribute( attribute(Attribute.VALUE, self.value.description) )
        this.addAttribute( attribute(Attribute.TICKS, self.ticks.description) )
        
        let specialties = DDXMLElement.elementWithName(Element.SPECIALTIES.rawValue) as! DDXMLElement
        this.addChild(specialties)
        self.specialties.enumerateObjectsUsingBlock { obj, idx, stop in specialties.addChild(obj.asXML()) }
        return this
    }

    func updateFromXML(element: DDXMLElement) -> NilResult
	{
        if let err = XMLSupport.validateElementName(element.name, expectedName: Element.SKILL.rawValue).error {
			return failure(err)
		}
        
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if let nodeName = Attribute(rawValue: attrNode.name) {
                switch nodeName {
                case .NAME  : self.name  = attrNode.stringValue
                case .VALUE : self.value = Int16(attrNode.stringValue.toInt() ?? 0)
                case .TICKS : self.ticks = Int16(attrNode.stringValue.toInt() ?? 0)
                }
            }
            else {
				return XMLSupport.XMLFailure("Unrecognised attribute \(attrNode.name) in skill")
			}
        }

        if element.childCount != 1 {
			NSLog("Warning: Skill has more than one child. Should be just one: \(Element.SPECIALTIES)")
		}

        if(element.childCount > 0) {
            for specGroup in (element.children as! [DDXMLElement]) {
                if specGroup.name == Element.SPECIALTIES.rawValue {
					switch XMLSupport.dataFromNodes(specGroup, createFunc: { addSpecialty(self.managedObjectContext!) }) {
					case .Success(let value): self.specialties = value.unwrap.mutableCopy() as! NSMutableOrderedSet
					case .Error(let err): return failure(err)
					}
                }
                else {
					return XMLSupport.XMLFailure("Unrecognised child \(specGroup.name) of skill element.")
				}
            }
        }
        return success()
    }
}



