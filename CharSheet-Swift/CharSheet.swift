//
//  PWCharSheet.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

class CharSheet : NSManagedObject {
    
    // MARK: Properties - Core Data

    @NSManaged var age: Int16, level: Int16
    @NSManaged var experience: Int32
    @NSManaged var woundsPhysical: Int16, woundsSubdual: Int16
    @NSManaged var game: String?, gender: String?, name: String?, notes: String?, player: String?
    @NSManaged var skills: NSMutableOrderedSet, xp: NSMutableOrderedSet
    @NSManaged var logs: NSMutableSet
	@NSManaged var dexterity: Int16, strength: Int16, constitution: Int16, speed: Int16
	@NSManaged var intelligence: Int16, perception: Int16, luck: Int16, charisma: Int16

    // MARK: Properties - Derived

	// These are calculated values from the other stats.
	var meleeAdds: Int {
		return max(0, strength - 12) + max(0, luck - 12)
	}

	var rangedAdds: Int {
		return max(0, luck - 12)
	}

	// Sorted copy of the log entries, sorted by date & time.
	var sortedLogs: [LogEntry] {

		func byDate(l1: LogEntry, l2: LogEntry) -> Bool
		{
			let d1 = l1.dateTime, d2 = l2.dateTime
			return d1.earlierDate(d2) == d1
		}

		return logs.allObjects
			.map { $0 as! LogEntry }
			.sorted(byDate)
	}

	// Returns a string indicating the character's health in both physical and subdual, as a fraction of their CON.
	var health: String {
		let physHealth = constitution - woundsPhysical
		let subdHealth = constitution - woundsSubdual
		return "P: \(physHealth) / \(constitution), S: \(subdHealth) / \(constitution)"
	}


    // MARK: - PrivateMethods
    
//    // Checks if any extra D4s are needed for this skill.  Returns the number of D4s to add.
//    func extraDiceForSkill(skill: Skill) -> Int16
//	{
//        // TODO: Either (a) set this in Preferences app-wide, or (b) allow the users to select it when creating the skills
//        // or (c) make it a property of the game itself and have the users set the game when creating the character.
//        return 1   // Default is +1D4 for all except magic skills.
//    }

	override var description: String {
		return self.fault
			? super.description
			: "CharSheet: \(super.description) <\(name)>"
	}

	override func awakeFromInsert()
	{
		super.awakeFromInsert()
		strength     = 0
		constitution = 0
		speed        = 0
		dexterity    = 0
		charisma     = 0
		intelligence = 0
		perception   = 0
		luck         = 0
		woundsPhysical = 0
		woundsSubdual  = 0
	}


	func statValueForName(name: String) -> Int16?
	{
		switch name {
		case "Strength"    : return strength
		case "Dexterity"   : return dexterity
		case "Speed"       : return speed
		case "Constitution": return constitution
		case "Perception"  : return perception
		case "Intelligence": return intelligence
		case "Luck"        : return luck
		case "Charisma"    : return charisma
		default            : return nil
		}
	}

    // Skills

    func addSkill(managedObjectContext: NSManagedObjectContext) -> Skill {
        return NSEntityDescription.insertNewObjectForEntityForName("Skill", inManagedObjectContext:managedObjectContext) as! Skill
    }

    func removeSkillAtIndex(index: Int) {
		if let skill = self.skills[index] as? Skill {
			self.skills.removeObject(skill)
			self.managedObjectContext?.deleteObject(skill)
		}
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


    func exportToXML() -> Result<NSData>
	{
        let rawXML = "<xml></xml>"
		return
			DDXMLDocument.documentWithXMLString(rawXML, options: 0)
			.andThen {
				let rootElement = $0.rootElement as! DDXMLElement
				rootElement.addChild(self.asXML())
				return $0.xmlDataWithOptions(UInt(DDXMLNodeCompactEmptyElement))
			}
    }


	/// Check if a character name clashes with an already-existing name and update the name to make it unique.
	///
	/// Called after importing a character from XML, to avoid overwriting an existing character.
	private func renameIfNecessary()
	{
		/// Checks if parameter NAME already exists as the name of any other character.
		func nameAlreadyExists(name: String) -> Bool
		{
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


		// If the new character has the same name as an existing one, then append the import date to it.
		// e.g. "John Smith - Imported 23/11/2013 11:14pm"
		// so the user can compare it to the existing version and delete whichever they prefer.
		name = name ?? "Unknown"
		if nameAlreadyExists(name!) {
			var dateFormatter = NSDateFormatter()
			dateFormatter.dateStyle = .MediumStyle
			dateFormatter.timeStyle = .MediumStyle
			name = String(format:"%@ : %@", name!, dateFormatter.stringFromDate(NSDate()))
		}
	}
}
    // MARK: - XMLClient implementation

extension CharSheet: XMLClient {

    var asObject: NSObject {
		get { return self }
	}

    private enum Element: String {
        case CHAR_SHEET = "charSheet"
		case SKILLS = "skills", LOGS = "logs", NOTES = "notes", XP_GAINS = "xp_gains"
    }
    
    private enum Attribute: String {
        case NAME  = "name", SEX = "gender", GAME  = "game", PLAYER = "player"
		case LEVEL = "level" , EXPERIENCE = "experience"
		case STRENGTH = "strength", SPEED = "speed", DEXTERITY = "dexterity", CONSTITUTION = "constitution"
		case PERCEPTION = "perception", INTELLIGENCE = "intelligence", CHARISMA = "charisma", LUCK = "luck"
    }
    


    func asXML() -> DDXMLElement {
        
        func addXMLAttributeStr(element: DDXMLElement, attrName: Attribute, attrValue: String)
		{
            let attr = DDXMLNode.attributeWithName(attrName.rawValue, stringValue:attrValue) as! DDXMLNode
            element.addAttribute(attr)
        }

        func addXMLAttributeInt(element: DDXMLElement, attrName: Attribute, attrValue: Int16)
		{
			let strValue = attrValue.description
            let attr = DDXMLNode.attributeWithName(attrName.rawValue, stringValue:strValue) as! DDXMLNode
            element.addAttribute(attr)
        }
        
        func saveChildrenAsXML(parent: DDXMLElement, elementName: Element, collection: NSArray) {
            var element = DDXMLElement.elementWithName(elementName.rawValue) as! DDXMLElement
            parent.addChild(element)
            collection.enumerateObjectsUsingBlock { obj, index, stop in element.addChild(obj.asXML()) }
        }
       
        var this = DDXMLElement.elementWithName(Element.CHAR_SHEET.rawValue) as! DDXMLElement
        addXMLAttributeStr(this, .NAME      , name   ?? "Unknown")
        addXMLAttributeStr(this, .SEX       , gender ?? "Unknown")
        addXMLAttributeStr(this, .GAME      , game   ?? "Unknown")
        addXMLAttributeStr(this, .PLAYER    , player ?? "Unknown")
        addXMLAttributeStr(this, .LEVEL     , level.description     )
        addXMLAttributeStr(this, .EXPERIENCE, experience.description)

		// The stats
		addXMLAttributeInt(this, .STRENGTH    , strength)
		addXMLAttributeInt(this, .SPEED       , speed)
		addXMLAttributeInt(this, .DEXTERITY   , dexterity)
		addXMLAttributeInt(this, .CONSTITUTION, constitution)
		addXMLAttributeInt(this, .PERCEPTION  , perception)
		addXMLAttributeInt(this, .INTELLIGENCE, intelligence)
		addXMLAttributeInt(this, .LUCK        , luck)
		addXMLAttributeInt(this, .CHARISMA    , charisma)
        
        saveChildrenAsXML(this, .LOGS    , logs.allObjects )
        saveChildrenAsXML(this, .SKILLS  , skills.array    )
        saveChildrenAsXML(this, .XP_GAINS, xp.array        )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        var elemNotes = DDXMLElement.elementWithName(Element.NOTES.rawValue, stringValue:self.notes) as! DDXMLElement
        this.addChild(elemNotes)
        
        return this
    }


    
    func updateFromXML(element: DDXMLElement) -> NilResult
	{
        // Check the name of the XML node, and set the appropriate CharSheet attribute to its value.
        // Returns true if successful, false if the attribute was not recognised.
        func setAttributeFromXML(this: CharSheet, node: DDXMLNode) -> Bool
		{
            if let attributeName = Attribute(rawValue: node.name) {
                switch attributeName {
                case .NAME       : this.name       = node.stringValue
                case .SEX        : this.gender     = node.stringValue
                case .GAME       : this.game       = node.stringValue
                case .PLAYER     : this.player     = node.stringValue
                case .LEVEL      : this.level      = Int16(node.stringValue.toInt() ?? 0)
                case .EXPERIENCE : this.experience = Int32(node.stringValue.toInt() ?? 0)

				case .PERCEPTION   : this.perception   = Int16(node.stringValue.toInt() ?? 0)
				case .INTELLIGENCE : this.intelligence = Int16(node.stringValue.toInt() ?? 0)
				case .CHARISMA     : this.charisma     = Int16(node.stringValue.toInt() ?? 0)
				case .LUCK         : this.luck         = Int16(node.stringValue.toInt() ?? 0)
				case .STRENGTH     : this.strength     = Int16(node.stringValue.toInt() ?? 0)
				case .DEXTERITY    : this.dexterity    = Int16(node.stringValue.toInt() ?? 0)
				case .SPEED        : this.speed        = Int16(node.stringValue.toInt() ?? 0)
				case .CONSTITUTION : this.constitution = Int16(node.stringValue.toInt() ?? 0)
                }
                return true
            }
            return false // Error - attribute not recognised.
        }

		if let err = XMLSupport.validateElementName(element.name, expectedName: Element.CHAR_SHEET.rawValue).error {
			return failure(err)
		}
        
        // Set each attribute.
        for attrNode in (element.attributes as! [DDXMLNode]) {
            if !setAttributeFromXML(self, attrNode) {
                return XMLSupport.XMLFailure("XML Attribute \(attrNode.name) not recognised in \(Element.CHAR_SHEET)")
            }
        }
        
        // Stats will have already been created, so just find each stat and update it.
        // Otherwise create a collection of the appropriate element and then replace the existing collection with it.
        for node in (element.children as! [DDXMLElement]) {
            if let elementName = Element(rawValue: node.name) {
                switch elementName {
                case .LOGS:
					switch XMLSupport.dataFromNodes(node, createFunc: { self.addLogEntry() }) {
					case .Success(let value): self.logs = NSMutableSet(array: value.unwrap.array)
					case .Error(let err): return failure(err)
					}
                case .SKILLS:
					switch XMLSupport.dataFromNodes(node, createFunc: { self.addSkill(self.managedObjectContext!) }) {
					case .Success(let value): self.skills = NSMutableOrderedSet(orderedSet: value.unwrap)
					case .Error(let err): return failure(err)
					}
                case .XP_GAINS:
					switch XMLSupport.dataFromNodes(node, createFunc: { self.addXPGain(self.managedObjectContext!) }) {
					case .Success(let value): self.xp = NSMutableOrderedSet(orderedSet: value.unwrap)
					case .Error(let err): return failure(err)

					}
                    // Notes are stored as elements as they are too big to hold in attributes.
                case .NOTES:
					self.notes = node.stringValue
                    
                case .CHAR_SHEET:
					return XMLSupport.XMLFailure("XML CharSheet entity cannot contain another CharSheet entity.")
                }
            }
            else {
				return XMLSupport.XMLFailure("XML entity \(node.name) not recognised as child of \(Element.CHAR_SHEET)")
            }
        }
        
 		// Rename the sheet to avoid name clashes with an already-existing one, if any.
		renameIfNecessary()
		return success()
    }
}

