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
    
    @NSManaged var name: String?
    @NSManaged var value: Int16
    @NSManaged var parent: CharSheet
    
    // MARK: Properties - Derived
    
    
    var shortName: String {
        // Use the first 3 letters of the name for the short name, except for Luck, which is Lck as Luc looks weird.
        let s = (name! as NSString).substringWithRange(NSRange(location:0, length:3))
        return s == "Luc" ? "Lck" : s
    }
    
    // MARK: Private methods
    
    // Stat logging description: Superclass info, name, value
    override var description: String {
        if fault { return super.description } // Don't trigger any un-faulting if this hasn't been loaded yet.
        let name = self.name ?? "No name"
        return "<\(super.description): \(name) \(value)>"
    }
    
    // MARK: XMLClient implementation
    
    var asObject: NSObject { get { return self } }
    
    private let elementSTAT = "stat", attributeNAME = "name", attributeVALUE = "value"
    
    func asXML() -> DDXMLElement {
        var this  = DDXMLElement(name: elementSTAT)
        var name  = DDXMLNode.attributeWithName(attributeNAME, stringValue: self.name) as DDXMLNode
        var value = DDXMLNode.attributeWithName(attributeVALUE, stringValue: self.value.description) as DDXMLNode
        this.addAttribute(name)
        this.addAttribute(value)
        return this
    }
    
    func updateFromXML(element: DDXMLElement, inout error: NSError?) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: elementSTAT, error: &error) {
            return false
        }
        for attrNode in element.attributes {
            if attrNode.isEqualToString(attributeNAME)       { self.name  = attrNode.stringValue  }
            else if attrNode.isEqualToString(attributeVALUE) { self.value = Int16(attrNode.integerValue) }
            else {
                let n = attrNode.name ?? "[nil]"
                return XMLSupport.setError(&error, text: "Attribute \(n) unrecognised in \(elementSTAT)")
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
