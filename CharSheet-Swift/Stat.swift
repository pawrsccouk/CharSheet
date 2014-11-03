//
//  PWStat.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//

import Foundation
import CoreData

class Stat : NSManagedObject, XMLClient {
    // MARK: Properties - Core Data
    @NSManaged var name: NSString, value: NSNumber, parent: CharSheet
    
    // MARK: Properties - Derived
    var shortName: String {
        // Use the first 3 letters of the name for the short name, except for Luck, which is Lck as Luc looks weird.
        get { return name.isEqualToString("Luck") ? "Lck" : name.substringWithRange(NSRange(location: 0, length: 3)) }
    }
    
    // MARK: Private methods
    
    // Stat logging description: Superclass info, name, value
    override var description: String {
        get { return fault ? super.description : String(format: "<%@: %@ %@>", super.description, self.name, self.value) }
    }
    
    // MARK: XMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    let elementStat = "stat", attributeName = "name", attributeValue = "value"
    
    func asXML() -> DDXMLElement {
        var this  = DDXMLElement(name: elementStat)
        var name  = DDXMLNode.attributeWithName(attributeName, stringValue: self.name) as DDXMLNode
        var value = DDXMLNode.attributeWithName(attributeValue, stringValue: self.value.stringValue) as DDXMLNode
        this.addAttribute(name)
        this.addAttribute(value)
        return this
    }
    
    func updateFromXML(element: DDXMLElement, error: NSErrorPointer) -> Bool {
        if !XMLSupport.validateElementName(element.name(), expectedName: elementStat, error:error) {
            return false
        }
        for attrNode in element.attributes() {
            if attrNode.isEqualToString(attributeName)       { self.name  = attrNode.stringValue  }
            else if attrNode.isEqualToString(attributeValue) { self.value = attrNode.integerValue }
            else {
                return XMLSupport.setError(error, format: "Attribute %@ unrecognised in %@", arguments: attrNode.name, elementStat)
            }
        }
        return true;
    }
}

//
//-(BOOL)updateFromXML:(DDXMLElement *)element error:(NSError *__autoreleasing *)error
//{
//    if(! [element.name isEqualToString:elementSTAT])
//        return PWXMLSetError(error, [NSString stringWithFormat:@"Element %@ unrecognised. Should be %@", element.name, elementSTAT]);
//    for (DDXMLNode *attrNode in element.attributes) {
//        if([attrNode.name isEqualToString:attributeNAME])        self.name  = [attrNode stringValue];
//        else if([attrNode.name isEqualToString:attributeVALUE])  self.value = numberFromNode(attrNode);
//        else return PWXMLSetError(error, [NSString stringWithFormat:@"Attribute %@ unrecognised in %@", attrNode.name, elementSTAT]);
//    }
//    return YES;
//}
//
//
//@end
