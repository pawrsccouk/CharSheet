//
//  PWCharSheet.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

class CharSheet : NSManagedObject, XMLClient {
    
    // MARK: Properties - Core Data

    @NSManaged var age: Int16
    @NSManaged var level: Int16
    @NSManaged var experience: Int32
    @NSManaged var woundsPhysical: Int16
    @NSManaged var woundsSubdual: Int16
    @NSManaged var game: String?
    @NSManaged var gender: String?
    @NSManaged var name: String?
    @NSManaged var notes: String?
    @NSManaged var player: String?
    @NSManaged var skills: NSMutableOrderedSet, xp: NSMutableOrderedSet
    @NSManaged var logs: NSMutableSet, stats: NSMutableSet
    
    // MARK: Properties - Derived
    
//    var woundsPhysical: Int16 = 0
//    var woundsSubdual: Int16 = 0
    
    // These are calculated values from the other stats.
    var meleeAdds: Int {
        get { return max(0, strength.value - 12) }
    }
    
    var rangedAdds: Int {
        get { return max(0, luck.value - 12) }
    }
    
    // Sorted copy of the log entries, sorted by date & time.
    var sortedLogs: [LogEntry] {
        return logs
			.sortedArrayUsingDescriptors([NSSortDescriptor(key: "dateTime", ascending: true)])
			.map{ $0 as! LogEntry }
    }

    // Returns a string indicating the character's health in both physical and subdual, as a fraction of their CON.
    var health: String {
        let conValue = constitution.value, physHealth = conValue - woundsPhysical, subdHealth = conValue - woundsSubdual
        return "P: \(physHealth) / \(conValue), S: \(subdHealth) / \(conValue)"
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
		get {
			return (stats.allObjects as! [Stat])
			.map{ $0 as Stat }
			.sorted{ $0.name!.compare($1.name!) == NSComparisonResult.OrderedAscending}}
	}

    // Set of all stat names, in alphabetical order.
    var statNames: NSOrderedSet {
        get {
			return NSOrderedSet(array: allStats.map { $0.name! })
		}
    }
    
    func statByName(name: String) -> Stat? {
        let stat = self.allStats.filter{ $0.name == name }
        return stat.first
    }



    // MARK: - PrivateMethods
    
    // Checks if any extra D4s are needed for this skill.  Returns the number of D4s to add.
    func extraDiceForSkill(skill: Skill) -> Int16 {
        // TODO: Either (a) set this in Preferences app-wide, or (b) allow the users to select it when creating the skills
        // or (c) make it a property of the game itself and have the users set the game when creating the character.
        return 1   // Default is +1D4 for all except magic skills.
    }
    
    override var description: String {
        get {
            if self.fault { return super.description }
            var desc = NSMutableString()
            desc.appendFormat("<%p: %@>", self, (self.allStats as NSArray).componentsJoinedByString(", "))
            return (desc as String)
        }
    }

	class func createStat(parent: CharSheet, name: String) -> Stat {
		let newStat = NSEntityDescription.insertNewObjectForEntityForName("Stat",
			inManagedObjectContext: parent.managedObjectContext!) as! Stat
		newStat.name = name
		newStat.value = 0
		newStat.parent = parent
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
        stats.removeAllObjects()
        stats.addObjectsFromArray(objects)
        woundsPhysical = 0
        woundsSubdual = 0
    }


    // Skills
  
    func removeSkillAtIndex(index: Int) {
		if let skill = self.skills[index] as? Skill {
			self.skills.removeObject(skill)
			self.managedObjectContext?.deleteObject(skill)
		}
    }

    func addSkill(managedObjectContext: NSManagedObjectContext) -> Skill {
        return NSEntityDescription.insertNewObjectForEntityForName("Skill", inManagedObjectContext:managedObjectContext) as! Skill
    }

    func appendSkill() -> Skill {
        var newSkill = addSkill(self.managedObjectContext!)
        newSkill.parent = self
        self.skills.addObject(newSkill)
        return newSkill
    }


    // Log Entries

    func addLogEntry() -> LogEntry {
        let entry = NSEntityDescription.insertNewObjectForEntityForName("LogEntry",
			inManagedObjectContext:self.managedObjectContext!) as! LogEntry
        entry.parent  = self
        self.logs.addObject(entry)
        return entry
    }
    
    func removeLogEntry(entry: LogEntry) {
        self.logs.removeObject(entry)
        entry.parent = nil
    }

    // XP Gains

    func addXPGain(context: NSManagedObjectContext) -> XPGain {
        return NSEntityDescription.insertNewObjectForEntityForName("XPGain",
			inManagedObjectContext:context) as! XPGain
    }

    // Create a new xp entry and append it to the list. Returns the new xp.
    func appendXPGain() -> XPGain {
        var xpGain = addXPGain(self.managedObjectContext!)
        xpGain.parent  = self
        self.xp.addObject(xpGain)
        return xpGain
    }

        // Remove the xp entry at the given index. It will be destroyed at the next commit.
	func removeXPGainAtIndex(index: Int) {
		if let xpGain = self.xp[index] as? XPGain {
			self.xp.removeObject(xpGain)
			xpGain.parent = nil
			self.managedObjectContext!.deleteObject(xpGain)
		}
	}




    // MARK: - Misc


    func exportToXML(inout error: NSError?) -> NSData? {
        let rawXML = "<xml></xml>"
        var err: NSErrorPointer = NSErrorPointer()
        var xmlDocument = DDXMLDocument(XMLString: rawXML, options: 0, error: err)
        if xmlDocument == nil {
            let error = err.memory
            NSLog("XML Error: %@", error!.localizedDescription)
            if let helpAnchor = error?.helpAnchor {
                NSLog("%@", helpAnchor)
                return nil
            }
            else {
                assert(xmlDocument != nil, "No XML document and no error given.")
                return nil
            }
        }
        
        if let rootElement = xmlDocument.rootElement as? DDXMLElement {
            rootElement.addChild(self.asXML())
            return xmlDocument.XMLDataWithOptions(UInt(DDXMLNodeCompactEmptyElement))
        } else {
            XMLSupport.setError(&error, text: "XML Export error: No document root element for \(xmlDocument)")
            return nil
        }
    }



    // Called after importing a character from XML, to avoid overwriting an existing character.
    // If the new character has the same name as an existing one, then append the import date to it.
    // e.g. "John Smith - Imported 23/11/2013 11:14pm" so the user can compare it to the existing version and delete whichever they prefer.
    private func renameIfNecessary() {
        
        // Checks if parameter NAME already exists as the name of any other character.
        func nameAlreadyExists(name: String) -> Bool  {
            var request = NSFetchRequest()
            request.entity = NSEntityDescription.entityForName("CharSheet", inManagedObjectContext:managedObjectContext!)
            request.predicate = NSPredicate(format:"(name == %@)  AND (self != %@)", name, self)
            
            var error = NSErrorPointer()
            if var array = managedObjectContext!.executeFetchRequest(request, error:error) {
                return array.isEmpty
            }
            else {  // Deal with error. Log it and assume the name already exists for safety's sake.
                if let err = error.memory {
                    NSLog("nameAlreadyExists: Fetch returned error: %@ / %@", err, err.userInfo ?? "nil")
                } else {
                    NSLog("nameAlreadyExists: Fetch failed with an unknown error")
                }
                return true
            }
        }
        
        
        if name == nil { name = "Unknown" }
        if nameAlreadyExists(name!) {
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .MediumStyle
            dateFormatter.timeStyle = .MediumStyle
            name = String(format:"%@ : %@", name!, dateFormatter.stringFromDate(NSDate()))
        }
        
    }
    
    // MARK: - XMLClient implementation

    var asObject: NSObject { get { return self } }
    
    private enum Element: String {
        case CHAR_SHEET = "charSheet", STATS = "stats", SKILLS = "skills", LOGS = "logs", NOTES = "notes", XP_GAINS = "xp_gains"
    }
    
    private enum Attribute: String {
        case NAME  = "name", SEX = "gender", GAME  = "game", PLAYER = "player", LEVEL = "level" , EXPERIENCE = "experience"
    }
    


    func asXML() -> DDXMLElement {
        
        func addXMLAttribute(element: DDXMLElement, attrName: Attribute, attrValue: String) {
            let attr = DDXMLNode.attributeWithName(attrName.rawValue, stringValue:attrValue) as! DDXMLNode
            element.addAttribute(attr)
        }
        
        func saveChildrenAsXML(parent: DDXMLElement, elementName: Element, collection: NSArray) {
            var element = DDXMLElement.elementWithName(elementName.rawValue) as! DDXMLElement
            parent.addChild(element)
            collection.enumerateObjectsUsingBlock { obj, index, stop in element.addChild(obj.asXML()) }
        }
       
        var this = DDXMLElement.elementWithName(Element.CHAR_SHEET.rawValue) as! DDXMLElement
        addXMLAttribute(this, .NAME      , self.name   ?? "Unknown")
        addXMLAttribute(this, .SEX       , self.gender ?? "Unknown")
        addXMLAttribute(this, .GAME      , self.game   ?? "Unknown")
        addXMLAttribute(this, .PLAYER    , self.player ?? "Unknown")
        addXMLAttribute(this, .LEVEL     , self.level.description     )
        addXMLAttribute(this, .EXPERIENCE, self.experience.description)
        
        saveChildrenAsXML(this, .STATS   , self.stats.allObjects)
        saveChildrenAsXML(this, .LOGS    , self.logs.allObjects )
        saveChildrenAsXML(this, .SKILLS  , self.skills.array    )
        saveChildrenAsXML(this, .XP_GAINS, self.xp.array        )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        var elemNotes = DDXMLElement.elementWithName(Element.NOTES.rawValue, stringValue:self.notes) as! DDXMLElement
        this.addChild(elemNotes)
        
        return this
    }


    
    func updateFromXML(element: DDXMLElement, inout error: NSError?) -> Bool {
        
        // Check the name of the XML node, and set the appropriate CharSheet attribute to its value.
        // Returns true if successful, false if the attribute was not recognised.
        func setAttributeFromXML(this: CharSheet, node: DDXMLNode) -> Bool {
            if let attributeName = Attribute(rawValue: node.name) {
                switch attributeName {
                case .NAME       : this.name       = node.stringValue
                case .SEX        : this.gender     = node.stringValue
                case .GAME       : this.game       = node.stringValue
                case .PLAYER     : this.player     = node.stringValue
                case .LEVEL      : this.level      = Int16(node.stringValue.toInt() ?? 0)
                case .EXPERIENCE : this.experience = Int32(node.stringValue.toInt() ?? 0)
                }
                return true
            }
            return false // Error - attribute not recognised.
        }
        
        
        // Checks the name of the XML element provided against the name of each of the char sheet's stats.
        // If it matches, call the stat's updateFromXML method passing in the element and return true, otherwise return false and set error.
        func updateStatsFromXML(this: CharSheet, element: DDXMLElement, inout error: NSError?) -> Bool {
            for statElement in (element.children as! [DDXMLElement]) {
                var nameAttr = statElement.attributeForName(Attribute.NAME.rawValue)
                if !(nameAttr != nil) {
                    return XMLSupport.setError(&error,
						text: "Attribute \(Attribute.NAME) not found in stat \(statElement)")
                }
                
                var stat = this.statByName(nameAttr.stringValue)
                if stat == nil {
                    return XMLSupport.setError(&error, text: "Unrecognised stat \(nameAttr.name)")
                }
                if !stat!.updateFromXML(statElement, error: &error) { return false }
            }
            return true
        }
        if !XMLSupport.validateElementName(element.name, expectedName: Element.CHAR_SHEET.rawValue, error: &error) { return false
		}
        
        
        // Set each attribute.
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if !setAttributeFromXML(self, attrNode) {
                return XMLSupport.setError(&error, text: "XML Attribute \(attrNode.name) not recognised in \(Element.CHAR_SHEET)" )
            }
        }
        
        // Stats will have already been created, so just find each stat and update it.
        // Otherwise create a collection of the appropriate element and then replace the existing collection with it.
        for node in (element.children as! [DDXMLElement]) {
            if let elementName = Element(rawValue: node.name) {
                switch elementName {
                case .STATS: if(!updateStatsFromXML(self, node, &error)) { return false }
                
                case .LOGS:
                    var newLogs = XMLSupport.dataFromNodes(node, createFunc: { self.addLogEntry() }, error: &error)
                    if newLogs == nil { return false }
                    self.logs = NSMutableSet(array: newLogs!.array)
                
                case .SKILLS:
                    var newSkills = XMLSupport.dataFromNodes(node, createFunc: { self.addSkill(self.managedObjectContext!) }, error: &error)
                    if newSkills == nil { return false }
                    self.skills = NSMutableOrderedSet(orderedSet:newSkills)
                
                case .XP_GAINS:
                    var newXPGains = XMLSupport.dataFromNodes(node, createFunc: { self.addXPGain(self.managedObjectContext!) }, error: &error)
                    if newXPGains == nil { return false }
                    self.xp = NSMutableOrderedSet(orderedSet:newXPGains)
                
                    // Notes are stored as an element as it is too big for an attribute.
                case .NOTES: self.notes = node.stringValue
                    
                case .CHAR_SHEET: return XMLSupport.setError(&error, text: "XML CharSheet entity cannot contain another CharSheet entity.")
                }
            }
            else {
                return XMLSupport.setError(&error, text: "XML entity \(node.name) not recognised as child of \(Element.CHAR_SHEET)" )
            }
        }
        
        renameIfNecessary()    // Rename the sheet to avoid name clashes with an already-existing one, if any.
        return true // Loaded successfully.
    }

}

