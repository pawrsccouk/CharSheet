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
    
    private enum Element: String { case STAT = "stat" }
    private enum Attribute: String { case NAME = "name", VALUE = "value" }
    
    func asXML() -> DDXMLElement {
        func attribute(name: Attribute, value: String) -> DDXMLNode {
			return DDXMLNode.attributeWithName(name.rawValue, stringValue: value) as! DDXMLNode
		}
        let this  = DDXMLElement(name: Element.STAT.rawValue)
        this.addAttribute( attribute(.NAME , self.name!) )
        this.addAttribute( attribute(.VALUE, self.value.description) )
        return this
    }
    
    func updateFromXML(element: DDXMLElement, inout error: NSError?) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: Element.STAT.rawValue, error: &error) {
            return false
        }
        for attrNode in element.attributes {
            if let attrName = Attribute(rawValue: attrNode.name) {
                switch attrName {
                case .NAME:  self.name  = attrNode.stringValue
                case .VALUE: self.value = Int16(attrNode.integerValue)
                }
            }
            else {
                let n = attrNode.name ?? "[nil]"
                return XMLSupport.setError(&error, text: "Attribute \(n) unrecognised in \(Element.STAT)")
            }
        }
        return true
    }
}

