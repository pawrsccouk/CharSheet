////
////  PWCharSheet.m
////  CharSheet
////
////  Created by Patrick Wallace on 20/11/2012.
////
////
//
//#import "PWCharSheet.h"
//#import "PWSkill.h"
//#import "PWStat.h"
//#import "PWSpecialty.h"
//#import "Misc.h"
//#import "PWLogEntry.h"
//#import "PWXPGain.h"
//
//#import "XMLSupport.h"
//
import Foundation
import CoreData

class CharSheet : NSManagedObject, XMLClient {
    
    // MARK: Properties - Core Data

    @NSManaged var age: NSNumber
    @NSManaged var level: NSNumber, experience: NSNumber
    @NSManaged var game: NSString, gender: NSString, name: NSString, notes: NSString, player: NSString
    @NSManaged var skills: NSMutableOrderedSet, xp: NSMutableOrderedSet
    @NSManaged var logs: NSMutableSet, stats: NSSet
    
    // MARK: Properties - Derived
    
    // These are calculated values from the other stats.
    var meleeAdds: NSNumber {
        get { return max(0, strength.value.integerValue - 12) }
    }
    
    var rangedAdds: NSNumber {
        get { return max(0, luck.value.integerValue - 12) }
    }
    
    // Sorted copy of the log entries, sorted by date & time.
    var sortedLogs: NSArray {
        get { return logs.sortedArrayUsingDescriptors([NSSortDescriptor(key: "dateTime", ascending: true)]) }
    }

    
    var strength:     Stat { get { return statByName("Strength"    )! } }
    var dexterity:    Stat { get { return statByName("Dexterity"   )! } }
    var speed:        Stat { get { return statByName("Speed"       )! } }
    var constitution: Stat { get { return statByName("Constitution")! } }
    var charisma:     Stat { get { return statByName("Charisma"    )! } }
    var intelligence: Stat { get { return statByName("Intelligence")! } }
    var perception:   Stat { get { return statByName("Perception"  )! } }
    var luck:         Stat { get { return statByName("Luck"        )! } }
    
    // Array of all stats attached, in alphabetical order.
    var allStats: [Stat] {
        get { return stats.allObjects.map{ obj in obj as Stat }.sorted{ stat1, stat2 in
            stat1.name.compare(stat2.name) == NSComparisonResult.OrderedAscending } }
    }
    
    // Set of all stat names, in alphabetical order.
    var statNames: NSOrderedSet {
        get { return NSOrderedSet(array: allStats.map { obj in obj.name }) }
    }
    
    func statByName(name: String) -> Stat? {
        let allStats: NSArray = self.allStats
        var index = allStats.indexOfObjectPassingTest { obj, idx, stop in obj.isEqualToString(name) }
        return index == NSNotFound ? nil : allStats[index] as? Stat
    }



    // MARK: - PrivateMethods
    
    // Checks if any extra D4s are needed for this skill.  Returns the number of D4s to add.
    func extraDiceForSkill(skill: Skill) -> Int {
        // TODO: Either (a) set this in Preferences app-wide, or (b) allow the users to select it when creating the skills
        // or (c) make it a property of the game itself and have the users set the game when creating the character.
        return 1;   // Default is +1D4 for all except magic skills.
    }
    
    override var description: String {
        get {
            if self.fault { return super.description }
            var desc = NSMutableString()
            desc.appendFormat("<%p: %@>", self, (self.allStats as NSArray).componentsJoinedByString(", "))
            return desc
        }
    }
    
    class func createStat(parent: CharSheet, name: String) -> Stat {
        var newStat = NSEntityDescription.insertNewObjectForEntityForName("Stat", inManagedObjectContext: parent.managedObjectContext!) as Stat
        newStat.name = name
        newStat.value = 0
        return newStat
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        let objects = [
            CharSheet.createStat(self, name: "Strength"),
            CharSheet.createStat(self, name: "Dexterity"),
            CharSheet.createStat(self, name: "Constitution"),
            CharSheet.createStat(self, name: "Speed"),
            CharSheet.createStat(self, name: "Charisma"),
            CharSheet.createStat(self, name: "Intelligence"),
            CharSheet.createStat(self, name: "Perception"),
            CharSheet.createStat(self, name: "Luck")
        ]
        self.stats = NSSet(objects: objects)
    }


//-(void)logStatsWithContext:(NSString *)context
//{
//    PW_CD_Log(@"BEGIN %@: %@", [self class], context);
//    PW_CD_Log(@"%@", [self.allStats componentsJoinedByString:@"\n"]);
//    PW_CD_Log(@"END %@: %@", [self class], context);
//}
//
//
//
//
//
//
// MARK:  - Core Data Collection bugfixes
//    // Bug in Core Data: Add/Remove/Update don't work for the NSOrderedSet objects created.
//    // Work-around = Copy all the data into a new set, append your extra item and assign it to the set item.
//    // Core Data should automatically note this and send update notifications.
//
//
// Skills
  
    func removeSkillAtIndex(index: Int) {
        var skill = self.skills[index] as Skill
        self.skills.removeObject(skill)
        self.managedObjectContext?.deleteObject(skill)
        //
        //        // Work around Core Data bug in removeSkillsObject
        //    NSMutableOrderedSet *newSkills = [NSMutableOrderedSet orderedSetWithOrderedSet:self.skills];
        //    [newSkills removeObjectAtIndex:index];
        //    self.skills = newSkills;
        //
    }

    func addSkill(managedObjectContext: NSManagedObjectContext) -> Skill {
        return NSEntityDescription.insertNewObjectForEntityForName("Skill", inManagedObjectContext:managedObjectContext) as Skill
    }

func appendSkill() -> Skill {
    var newSkill = addSkill(self.managedObjectContext!)
    
//    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.skills];
//    [tempSet addObject:newSkill];
//    self.skills = tempSet;
    self.skills.addObject(newSkill)
    return newSkill
}

//-(void)moveSkillFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destIndex
//{
//        //   Bug in Core Data - addXXObject don't work for ordered data items.
//    NSMutableOrderedSet *newSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.skills];
//    [newSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndex] toIndex:destIndex];
//    self.skills = newSet;
//}

    // Log Entries

    func addLogEntry() -> LogEntry {
        var entry = NSEntityDescription.insertNewObjectForEntityForName("LogEntry", inManagedObjectContext:self.managedObjectContext!) as LogEntry
        entry.parent  = self
        self.logs.addObject(entry)
        return entry
    }
    
    func removeLogEntry(entry: LogEntry) {
        self.logs.removeObject(entry)
        entry.parent = nil
    }

//
//
// XP Gains
//
//
    func addXPGain(context: NSManagedObjectContext) -> XPGain {
        return NSEntityDescription.insertNewObjectForEntityForName("XPGain", inManagedObjectContext:context) as XPGain
    }

    // Create a new xp entry and append it to the list. Returns the new xp.
    func appendXPGain() -> XPGain {
        var xpGain = addXPGain(self.managedObjectContext!)
        xpGain.parent  = self
        self.xp.addObject(xpGain)
        //    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.xp];
        //    [tempSet addObject:xpGain];
        //    self.xp = tempSet;
        return xpGain
    }

        // Remove the xp entry at the given index. It will be destroyed at the next commit.
    func removeXPGainAtIndex(index: Int) {
        var xpGain = self.xp[index] as XPGain
        self.xp.removeObject(xpGain)
        xpGain.parent = nil
        //        // Work around Core Data bug in removeSkillsObject
        //    NSMutableOrderedSet *newXP = [NSMutableOrderedSet orderedSetWithOrderedSet:self.xp];
        //    [newXP removeObjectAtIndex:index];
        //    self.xp = newXP;
        
        self.managedObjectContext!.deleteObject(xpGain)
    }
    
    
    // Re-order two xp entries in the list.
//-(void)moveXPGainFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destIndex
//{
//    NSMutableOrderedSet *newSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.xp];
//    [newSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndex] toIndex:destIndex];
//    self.xp = newSet;
//}
//
    // MARK: - Misc


    func exportToXML(error: NSErrorPointer ) -> NSData? {
        let rawXML = "<xml></xml>"
        var xmlDocument = DDXMLDocument(XMLString:rawXML, options:0, error:error)
        if xmlDocument == nil {
            if let errorObj = error.memory {
                NSLog("XML Error: %@", errorObj.localizedDescription)
                if errorObj.helpAnchor != nil {
                    NSLog("%@", errorObj.helpAnchor!)
                    return nil
                }
            }
            else {
                assert(xmlDocument != nil, "No XML document and no error given.")
                return nil
            }
        }
        
        
        if let rootElement = xmlDocument.rootElement() {
            rootElement.addChild(self.asXML())
            return xmlDocument.XMLDataWithOptions(UInt(DDXMLNodeCompactEmptyElement))
        } else {
            XMLSupport.setError(error, format: "XML Export error: No document root element for %@", arguments:xmlDocument)
            return nil
        }
    }
//
//
//-(BOOL)nameAlreadyExists:(NSString*)name
//{
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    request.entity = [NSEntityDescription entityForName:@"CharSheet"
//                                 inManagedObjectContext:self.managedObjectContext];
//    request.predicate = [NSPredicate predicateWithFormat:@"(name == %@)  AND (self != %@)", name, self];
//    
//    NSError *error;
//    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
//    if (array)
//        return (array.count > 0);
//    else {  // Deal with error. Log it and assume the 
//        NSLog(@"Fetch returned error: %@ / %@", error, error.userInfo);
//        return YES;
//    }
//}
//
//
//-(void)renameIfNecessary
//{
//        // If the new character has the same name as an existing one, then append the import date to it.
//        // e.g. "John Smith - Imported 23/11/2013 11:14pm" so the user can compare it to the existing version and delete whichever they prefer.
//    if([self nameAlreadyExists:self.name]) {
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
//        self.name = [NSString stringWithFormat:@"%@ : %@", self.name, [dateFormatter stringFromDate:[NSDate date]]];
//    }
//    
//}
//
    // MARK - XMLClient implementation

    var asObject: NSObject { get { return self } }
    
    let elementCHAR_SHEET   = "charSheet" ,  elementSTATS      = "stats"
    let elementSKILLS       = "skills"    ,  elementLOGS       = "logs"
    let elementNOTES        = "notes"     ,  elementXP_GAINS   = "xp_gains"
    let attributeNAME       = "name"      ,  attributeGENDER   = "gender"
    let attributeGAME       = "game"     //, attributeNOTES    = "notes"
    let attributePLAYER     = "player"    ,  attributeLEVEL    = "level"
    let attributeEXPERIENCE = "experience"

    func addXMLAttribute(element: DDXMLElement, attrName: String, attrValue: String)
    {
        let attr = DDXMLNode.attributeWithName(attrName, stringValue:attrValue) as DDXMLNode
        element.addAttribute(attr)
    }

    func saveChildrenAsXML(parent: DDXMLElement, elementName: String, collection: NSArray) {
        var element = DDXMLElement.elementWithName(elementName) as DDXMLElement
        parent.addChild(element)
        collection.enumerateObjectsUsingBlock { obj, index, stop in element.addChild(obj.asXML()) }
    }

    func asXML() -> DDXMLElement {
        var this = DDXMLElement.elementWithName(elementCHAR_SHEET) as DDXMLElement
        addXMLAttribute(this, attrName: attributeNAME      , attrValue: self.name  )
        addXMLAttribute(this, attrName: attributeGENDER    , attrValue: self.gender)
        addXMLAttribute(this, attrName: attributeGAME      , attrValue: self.game  )
        addXMLAttribute(this, attrName: attributePLAYER    , attrValue: self.player)
        addXMLAttribute(this, attrName: attributeLEVEL     , attrValue: self.level.stringValue     )
        addXMLAttribute(this, attrName: attributeEXPERIENCE, attrValue: self.experience.stringValue)
        
        saveChildrenAsXML(this, elementName: elementSTATS   , collection: self.stats.allObjects)
        saveChildrenAsXML(this, elementName: elementLOGS    , collection: self.logs.allObjects )
        saveChildrenAsXML(this, elementName: elementSKILLS  , collection: self.skills.array    )
        saveChildrenAsXML(this, elementName: elementXP_GAINS, collection: self.xp.array        )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        var elemNotes = DDXMLElement.elementWithName(elementNOTES, stringValue:self.notes) as DDXMLElement
        this.addChild(elemNotes)
        
        return this
    }



    func setAttributeFromXML(this: CharSheet, node: DDXMLNode) -> Bool {
        if let nodeName = node.name {
            if      attributeNAME       == nodeName { this.name       = node.stringValue }
            else if attributeGENDER     == nodeName { this.gender     = node.stringValue }
            else if attributeGAME       == nodeName { this.game       = node.stringValue }
            else if attributePLAYER     == nodeName { this.player     = node.stringValue }
            else if attributeLEVEL      == nodeName { this.level      = XMLSupport.numberFromNode(node) }
            else if attributeEXPERIENCE == nodeName { this.experience = XMLSupport.numberFromNode(node) }
            else { return false } // Error - attribute not recognised.
        }
        return true
    }

    func updateStatsFromXML(this: CharSheet, element: DDXMLElement, error: NSErrorPointer) -> Bool {
        for statElement in (element.children as [DDXMLElement]) {
            var nameAttr = statElement.attributeForName(attributeNAME)
            if !(nameAttr != nil) { return XMLSupport.setError(error, format: "Attribute %@ not found in stat %@", arguments: attributeNAME, statElement) }
            
            var stat = this.statByName(nameAttr.stringValue)
            if stat == nil { return XMLSupport.setError(error, format: "Unrecognised stat %@", arguments: nameAttr.name) }
            if !stat!.updateFromXML(statElement, error:error) { return false }
        }
        return true
    }
    
    func updateFromXML(element: DDXMLElement, error: NSErrorPointer) -> Bool {
        if !XMLSupport.validateElementName(element.name, expectedName: elementCHAR_SHEET, error: error) { return false }
        
        for attrNode in (element.attributes as [DDXMLNode]) {
            if !setAttributeFromXML(self, node: attrNode) {
                return XMLSupport.setError(error, format: "XML Attribute %@ not recognised in %@", arguments: attrNode.name, elementCHAR_SHEET)
            }
        }
        
        // Stats will have already been created, so just find each stat and update it.
        // Otherwise create a collection of the appropriate element and then replace the existing collection with it.
        for node in (element.children as [DDXMLElement]) {
            if let nodeName = node.name {
                if nodeName == elementSTATS {
                    if(!updateStatsFromXML(self, element: node, error: error)) { return false }
                }
                else if nodeName == elementLOGS {
                    var newLogs = XMLSupport.dataFromNodes(node, createFunc: { self.addLogEntry() }, error: error)
                    if newLogs == nil { return false }
                    self.logs = NSMutableSet(array: newLogs!.array)
                }
                else if nodeName == elementSKILLS {
                    var newSkills = XMLSupport.dataFromNodes(node, createFunc: { self.addSkill(self.managedObjectContext!) }, error: error)
                    if newSkills == nil { return false }
                    self.skills = NSMutableOrderedSet(orderedSet:newSkills)
                }
                else if nodeName == elementXP_GAINS {
                    var newXPGains = XMLSupport.dataFromNodes(node, createFunc: { self.addXPGain(self.managedObjectContext!) }, error: error)
                    if newXPGains == nil { return false }
                    self.xp = NSMutableOrderedSet(orderedSet:newXPGains)
                }
                    // Notes are stored as an element as it is too big for an attribute.
                else if nodeName == elementNOTES {
                    self.notes = node.stringValue
                }
                else { return XMLSupport.setError(error, format: "XML entity %@ not recognised as child of %@", arguments:nodeName, elementCHAR_SHEET) }
            }
        }
        return true // Loaded successfully.
    }

}

