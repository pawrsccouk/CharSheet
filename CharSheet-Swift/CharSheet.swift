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
		return logs.allObjects
			.map { $0 as! LogEntry }
			.sort{
				let d1 = $0.dateTime
				return d1.earlierDate($1.dateTime) == d1
		}
	}

	// Returns a string indicating the character's health in both physical and subdual, as a fraction of their CON.
	var health: String {
		let physHealth = constitution - woundsPhysical
		let subdHealth = constitution - woundsSubdual
		return "P: \(physHealth) / \(constitution), S: \(subdHealth) / \(constitution)"
	}


    // MARK: PrivateMethods

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

    // Skills

    func addSkill(managedObjectContext: NSManagedObjectContext) -> Skill
	{
        return NSEntityDescription.insertNewObjectForEntityForName(
			"Skill", inManagedObjectContext:managedObjectContext) as! Skill
    }

    func removeSkillAtIndex(index: Int)
	{
		if let skill = self.skills[index] as? Skill {
			self.skills.removeObject(skill)
			self.managedObjectContext?.deleteObject(skill)
		}
    }

    func appendSkill() -> Skill
	{
        let newSkill = addSkill(self.managedObjectContext!)
        newSkill.parent = self
        self.skills.addObject(newSkill)
        return newSkill
    }


    // Log Entries

    func addLogEntry() -> LogEntry
	{
        let entry = NSEntityDescription.insertNewObjectForEntityForName(
			"LogEntry", inManagedObjectContext:self.managedObjectContext!) as! LogEntry
        entry.parent  = self
        self.logs.addObject(entry)
        return entry
    }
    
    func removeLogEntry(entry: LogEntry)
	{
        self.logs.removeObject(entry)
        entry.parent = nil
    }

    // XP Gains

    func addXPGain(context: NSManagedObjectContext) -> XPGain
	{
        return NSEntityDescription.insertNewObjectForEntityForName(
			"XPGain", inManagedObjectContext:context) as! XPGain
    }

    // Create a new xp entry and append it to the list. Returns the new xp.
    func appendXPGain() -> XPGain
	{
        let xpGain = addXPGain(self.managedObjectContext!)
        xpGain.parent  = self
        self.xp.addObject(xpGain)
        return xpGain
    }

        // Remove the xp entry at the given index. It will be destroyed at the next commit.
	func removeXPGainAtIndex(index: Int)
	{
		if let xpGain = self.xp[index] as? XPGain {
			self.xp.removeObject(xpGain)
			xpGain.parent = nil
			self.managedObjectContext!.deleteObject(xpGain)
		}
	}




    // MARK: Misc


    func exportToXML() -> Result<NSData>
	{
        let rawXML = "<xml></xml>"
		return
			DDXMLDocument.documentWithXMLString(rawXML, options: 0)
			.andThen {
				($0.rootElement as! DDXMLElement).addChild(self.asXML())
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
			let request = NSFetchRequest()
			request.entity = NSEntityDescription.entityForName("CharSheet", inManagedObjectContext:managedObjectContext!)
			request.predicate = NSPredicate(format:"(name == %@)  AND (self != %@)", name, self)

			let error = NSErrorPointer()
			do {
				let array = try managedObjectContext!.executeFetchRequest(request)
				return array.isEmpty
			} catch let error1 as NSError {  // Deal with error. Log it and assume the name already exists for safety's sake.
				error.memory = error1
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
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateStyle = .MediumStyle
			dateFormatter.timeStyle = .MediumStyle
			name = String(format:"%@ : %@", name!, dateFormatter.stringFromDate(NSDate()))
		}
	}
}

// MARK: - XMLClient implementation

private enum AttrType { case String, Integer }

/// Collection of attribute names and the associated attribute type.
///
/// :todo: Can this be got from the entity?
///
/// This assumes the attributes in the XML are named the same as the attributes on the object.
private let attributes: [(String, AttrType)] = [
		("name", .String), ("gender", .String), ("game", .String), ("player", .String), ("level", .Integer), ("experience", .Integer),
		("strength", .Integer), ("speed", .Integer), ("dexterity", .Integer), ("constitution", .Integer),
		("perception", .Integer), ("intelligence", .Integer), ("charisma", .Integer), ("luck", .Integer)
	]

extension CharSheet: XMLClient
{
	var asObject: NSObject {
		return self
	}

    private enum Element: String
	{
        case CHAR_SHEET = "charSheet"
		case SKILLS = "skills", LOGS = "logs", NOTES = "notes", XP_GAINS = "xp_gains"
    }
    
    func asXML() -> DDXMLElement
	{
        func saveChildrenAsXML(parent: DDXMLElement, elementName: Element, collection: NSArray)
		{
            let element = DDXMLElement.elementWithName(elementName.rawValue) as! DDXMLElement
            parent.addChild(element)
            collection.enumerateObjectsUsingBlock { obj, index, stop in element.addChild(obj.asXML()) }
        }
       
        let thisElement = DDXMLElement.elementWithName(Element.CHAR_SHEET.rawValue) as! DDXMLElement
		// Use KVO to get the attribute data.
		for (attrName, _) in attributes {
			let sv = (valueForKey(attrName) ?? "").description
			thisElement.addAttribute(DDXMLNode.attributeWithName(attrName, stringValue:sv) as! DDXMLNode)
		}
        saveChildrenAsXML(thisElement, elementName: .LOGS    , collection: logs.allObjects )
        saveChildrenAsXML(thisElement, elementName: .SKILLS  , collection: skills.array    )
        saveChildrenAsXML(thisElement, elementName: .XP_GAINS, collection: xp.array        )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        let elemNotes = DDXMLElement.elementWithName(
			Element.NOTES.rawValue, stringValue:self.notes) as! DDXMLElement
        thisElement.addChild(elemNotes)
        return thisElement
    }


    
    func updateFromXML(element: DDXMLElement) -> NilResult
	{
		if let err = XMLSupport.validateElementName(element.name, expectedName: Element.CHAR_SHEET.rawValue).error {
			return failure(err)
		}
		// Use KVO to set the attributes from the XML element provided.
		for (attrName, attrType) in attributes {
			if let node = element.attributeForName(attrName) {
				switch attrType {
				case .String:
					setValue(node.stringValue, forKey: attrName)
				case .Integer:
					setValue(Int(node.stringValue) ?? 0, forKey: attrName)
				}
			} else {
				NSLog("CharSheet import: Attribute named \(attrName) not found in the XML we are importing. Skipping it.")
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

