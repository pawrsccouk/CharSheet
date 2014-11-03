//
//  PWSkill.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

func addSpecialty(managedObjectContext: NSManagedObjectContext) -> Specialty
{
    return NSEntityDescription.insertNewObjectForEntityForName("Specialty", inManagedObjectContext:managedObjectContext) as Specialty
}

class Skill : NSManagedObject, XMLClient {

    @NSManaged var name: NSString, ticks: NSNumber, value: NSNumber, parent: CharSheet!, specialties: NSMutableOrderedSet!

    override func awakeFromInsert() -> Void {
        super.awakeFromInsert()
        self.name = ""
        self.value = 0
    }


    func appendSpecialty() -> Specialty
    {
        var newSpec = addSpecialty(self.managedObjectContext!)
        self.specialties.addObject(newSpec)
        return newSpec
        
        // TODO:  Bug in Core Data - addXXObject don't work for ordered data items.
        //    [self addSkillsObject:newSkill];
        // Work-around = Copy all the data, append your extra item and assign it to the set item.
        // Core Data should automatically note this and sent update notifications.
        
        //    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.specialties];
        //    [tempSet addObject:newSpec];
        //    self.specialties = tempSet;
        //    return newSpec;
    }
    
    func removeSpecialtyAtIndex(index: Int) -> Void {
        var spec: Specialty = self.specialties[index] as Specialty
        self.specialties.removeObjectAtIndex(index)
        
//        var newSet = NSMutableOrderedSet(orderedSet:self.specialties)
//        newSet.removeObjectAtIndex(index)
//        self.specialties = newSet;
//        
        self.managedObjectContext?.deleteObject(spec)
    }

    func moveSpecialtyFromIndex(sourceIndex: NSInteger, toIndex destIndex: NSInteger) -> Void {
        self.specialties.moveObjectsAtIndexes(NSIndexSet(index: sourceIndex), toIndex:destIndex)
//        var newSet = NSMutableOrderedSet orderedSetWithOrderedSet:self.specialties];
//        [newSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndex] toIndex:destIndex];
//        self.specialties = newSet;
    }


    func specialtiesAsString() -> NSString {
        var str = NSMutableString()
        for spec in (self.specialties.array as [Specialty]) {
                str.appendFormat("%@ +%@; ", spec.name, spec.value)
        }
        // Remove the final "; "
        if str.length > 2 {
            str.replaceCharactersInRange(NSMakeRange(str.length - 2, 2), withString:"")
        }
        return str
    }


    func add(value: NSNumber, toAdd: NSInteger) -> NSNumber {
        return NSNumber(integer:value.integerValue + toAdd)
    }



    func addTick() -> Bool {
        if self.ticks.integerValue >= 19 {
            self.ticks = 0
            self.value = self.value.integerValue + 1
            return true
        }
        else {
            self.ticks = self.ticks.integerValue + 1
            return false
        }
    }
    
    
    // MARK:- PWXMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    let elementSKILL       = "skill"
    let elementSPECIALTIES = "specialties"
    let attributeNAME      = "name"
    let attributeVALUE     = "value"
    let attributeTICKS     = "ticks"
    
    
    func asXML() -> DDXMLElement {
        var this = DDXMLElement.elementWithName(elementSKILL) as DDXMLElement
        
        var name  = DDXMLNode.attributeWithName(attributeNAME , stringValue:self.name) as DDXMLNode
        var value = DDXMLNode.attributeWithName(attributeVALUE, stringValue:self.value.stringValue) as DDXMLNode
        var ticks = DDXMLNode.attributeWithName(attributeTICKS, stringValue:self.ticks.stringValue) as DDXMLNode
        this.addAttribute(name)
        this.addAttribute(value)
        this.addAttribute(ticks)
        
        var specialties = DDXMLElement.elementWithName(elementSPECIALTIES) as DDXMLElement
        this.addChild(specialties)
        self.specialties.enumerateObjectsUsingBlock { obj, idx, stop in specialties.addChild(obj.asXML()) }
        return this
    }

    func updateFromXML(element: DDXMLElement, error:NSErrorPointer) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: elementSKILL, error: error) { return false }
        
        for attrNode in (element.attributes as [DDXMLNode]) {
            let nodeName = attrNode.name
            if      nodeName == attributeNAME  { self.name  = attrNode.stringValue }
            else if nodeName == attributeVALUE { self.value = XMLSupport.numberFromNode(attrNode) }
            else if nodeName == attributeTICKS { self.ticks = XMLSupport.numberFromNode(attrNode) }
            else { return XMLSupport.setError(error, format: "Unrecognised attribute %@ in skill", arguments: nodeName) }
        }
        
        if element.childCount != 1 { NSLog("Warning: Skill has more than one child. Should be just one: %@", elementSPECIALTIES) }
        if(element.childCount > 0) {
            for specGroup in (element.children as [DDXMLElement]) {
                if specGroup.name == elementSPECIALTIES {
                    var specialties = XMLSupport.dataFromNodes(specGroup, createFunc: { addSpecialty(self.managedObjectContext!) }, error: error)
                    if specialties == nil { return false }
                    self.specialties = specialties?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
                }
                else { return XMLSupport.setError(error, format:"Unrecognised child %@ of skill element.", arguments:specGroup.name) }
            }
        }
        return true
    }
}



