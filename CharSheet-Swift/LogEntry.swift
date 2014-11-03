//
//  PWLogEntry.m
//  CharSheet
//
//  Created by Patrick Wallace on 03/01/2013.
//
//

import Foundation
import CoreData

class LogEntry : NSManagedObject, XMLClient {
    
    
    // MARK: CoreData dynamic properties.
    
    @NSManaged var dateTime: NSDate, summary: String, change: String, parent: CharSheet!
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        self.dateTime = NSDate()
        self.summary  = "Summary"
        self.change   = "Description of change."
    }
    
    // MARK: - PWXMLClient implementation
    
    // XML entity and attribute tags for this object.
    let elementLOG_ENTRY   = "logEntry"
    let attributeDATE_TIME = "dateTime"
    let attributeSUMMARY   = "summary"
    
    var asObject: NSObject { get { return self } }
    
    private var _cachedFormatter: NSDateFormatter? = nil
    var fullDateFormatter: NSDateFormatter {
        get {
            if _cachedFormatter == nil {
                _cachedFormatter = NSDateFormatter()
                _cachedFormatter!.dateStyle = .FullStyle
                _cachedFormatter!.timeStyle = .FullStyle
            }
            return _cachedFormatter!
        }
    }
    
    
    
    func asXML() -> DDXMLElement {
        var this    = DDXMLElement.elementWithName(elementLOG_ENTRY , stringValue:self.change) as DDXMLElement
        var date    = DDXMLNode.attributeWithName(attributeDATE_TIME, stringValue:self.fullDateFormatter.stringFromDate(self.dateTime)) as DDXMLNode
        var summary = DDXMLNode.attributeWithName(attributeSUMMARY  , stringValue:self.summary) as DDXMLNode
        this.addAttribute(date)
        this.addAttribute(summary)
        return this;
    }
    
    
    
    func updateFromXML(element: DDXMLElement, error: NSErrorPointer) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: elementLOG_ENTRY, error: error) { return false }
        for attrNode in (element.attributes as [DDXMLNode]) {
            let nodeName = attrNode.name
            if      nodeName  == attributeDATE_TIME { self.dateTime = fullDateFormatter.dateFromString(attrNode.stringValue)! }
            else if nodeName  == attributeSUMMARY   { self.summary  = attrNode.stringValue }
            else { return XMLSupport.setError(error, format: "Unrecognised log entry attribute: %@", arguments: attrNode.name) }
        }
        
        self.change = element.stringValue
        return true
    }
    
}
