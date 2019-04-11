//
//  PWCharSheet.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData

/// Model object for a character sheet, the root of the datamodel.
///
/// This subclasses NSManagedObject to give XML support and direct access to the entity properties.

class CharSheet : NSManagedObject
{
	func delete()
	{
		managedObjectContext?.delete(self)
	}

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
	@NSManaged var skills: NSMutableOrderedSet
	@NSManaged var xp: NSMutableOrderedSet
	@NSManaged var logs: NSMutableSet
	@NSManaged var dexterity: Int16
	@NSManaged var strength: Int16
	@NSManaged var constitution: Int16
	@NSManaged var speed: Int16
	@NSManaged var intelligence: Int16
	@NSManaged var perception: Int16
	@NSManaged var luck: Int16
	@NSManaged var charisma: Int16

    // MARK: Properties - Derived

	// These are calculated values from the other stats.
	var meleeAdds: Int {
		return max(0, Int(strength) - 12) + max(0, Int(luck) - 12)
	}

	var rangedAdds: Int {
		return max(0, Int(luck) - 12)
	}

	var allSkills: [Skill] {
		return skills.array.map { $0 as! Skill }
	}

	var allLogEntries: [LogEntry] {
		return logs.allObjects.map { $0 as! LogEntry }
	}

	/// Sorted copy of the log entries, sorted by date & time.
	var sortedLogs: [LogEntry] {
		return allLogEntries.sorted {
			let d1 = $0.dateTime
			return (d1 as NSDate).earlierDate($1.dateTime as Date) == d1 as Date
		}
	}

	var allXPGains: [XPGain] {
		return xp.array.map { $0 as! XPGain }
	}

	/// Returns a string indicating the character's health in both physical and subdual, as a fraction of their CON.
	var health: String {
		let physHealth = constitution - woundsPhysical
		let subdHealth = constitution - woundsSubdual
		return "P: \(physHealth) / \(constitution), S: \(subdHealth) / \(constitution)"
	}
}


// MARK: -

extension CharSheet
{
    // MARK: Overrides

	override var description: String {
		return self.isFault
			? super.description
			: "CharSheet: \(super.description) <\(name ?? "NULL")>"
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

    func addSkill() -> Skill
	{
        let skill = NSEntityDescription.insertNewObject(forEntityName: "Skill", into: self.managedObjectContext!) as! Skill
        skill.parent = self
        skills.add(skill)
        return skill
    }

	func removeSkill(at index: Int)
	{
		if let skill = self.skills[index] as? Skill {
			self.skills.remove(skill)
			self.managedObjectContext?.delete(skill)
		}
    }


    // Log Entries

    func addLogEntry() -> LogEntry
	{
        let entry = NSEntityDescription.insertNewObject(
			forEntityName: "LogEntry", into:self.managedObjectContext!) as! LogEntry
        entry.parent  = self
        self.logs.add(entry)
        return entry
    }
    
    func remove(logEntry: LogEntry)
	{
        self.logs.remove(logEntry)
        logEntry.parent = nil
    }

    // XP Gains

    func addXPGain() -> XPGain
	{
        let xpGain = NSEntityDescription.insertNewObject(forEntityName: "XPGain", into: self.managedObjectContext!) as! XPGain
        xpGain.parent  = self
        self.xp.add(xpGain)
        return xpGain
    }

        // Remove the xp entry at the given index. It will be destroyed at the next commit.
	func removeXPGain(at index: Int)
	{
		if let xpGain = self.xp[index] as? XPGain {
			self.xp.remove(xpGain)
			xpGain.parent = nil
			self.managedObjectContext!.delete(xpGain)
		}
	}




    // MARK: Misc


    func exportToXML() throws -> Data
	{
		let document = try DDXMLDocument(xmlString: "<xml></xml>", options: 0)
		guard let root = document.rootElement() else {
			throw XMLSupport.XMLError("Document \(document) has invalid root element.")
		}
		try root.addChild(self.asXML())
		return document.xmlData(withOptions: UInt(DDXMLNodeCompactEmptyElement))
    }


	/// Check if a character name clashes with an already-existing name and update the name to make it unique.
	///
	/// Called after importing a character from XML, to avoid overwriting an existing character.
	fileprivate func renameIfNecessary() throws
	{
		/// Checks if parameter NAME already exists as the name of any other character.
		func nameAlreadyExists(_ name: String) throws -> Bool
		{
			guard let moc = managedObjectContext else {
				fatalError("No managed object context.")
			}
			let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CharSheet")
			request.predicate = NSPredicate(format:"name == %@", name)

			let count = try moc.count(for: request)
			assert(count != NSNotFound, "Error returned but exception not thrown.")
			return count > 1
		}


		// If the new character has the same name as an existing one, then append the import date to it.
		// e.g. "John Smith - Imported 23/11/2013 11:14pm"
		// so the user can compare it to the existing version and delete whichever they prefer.
		let charName = name ?? "Unknown"
		if try nameAlreadyExists(charName) {
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .medium
			name = String(format:"%@ : %@", charName, dateFormatter.string(from: Date()))
		}
	}
}

// MARK: - XMLClient implementation

private enum AttrType { case string, integer }

/// Collection of attribute names and the associated attribute type.
///
/// This assumes the attributes in the XML are named the same as the attributes on the object.
///
/// - todo: Can this be got from the entity?

private let attributes: [(String, AttrType)] = [
		("name", .string), ("gender", .string), ("game", .string), ("player", .string), ("level", .integer), ("experience", .integer), ("age", .integer),
		("strength", .integer), ("speed", .integer), ("dexterity", .integer), ("constitution", .integer),
		("perception", .integer), ("intelligence", .integer), ("charisma", .integer), ("luck", .integer)
	]

private let CHAR_SHEET = "charSheet"
private let SKILLS = "skills", LOGS = "logs", NOTES = "notes", XP_GAINS = "xp_gains"

extension CharSheet: XMLClient
{
	private func string(forKey: String) -> String
	{
		let val = value(forKey: forKey) as AnyObject
		return val.description ?? "Unknown"
	}

	func asXML() throws -> DDXMLElement
	{
        func saveChildrenAsXML(_ parent: DDXMLElement, elementName: String, collection: [XMLClient]) throws
		{
            let element = DDXMLElement.element(withName: elementName)
            parent.addChild(element)
			for child in collection {
				try element.addChild(child.asXML())
			}
        }

        let thisElement = DDXMLElement.element(withName: CHAR_SHEET)
		// Use KVO to get the attribute data.
		for (attrName, _) in attributes {
			let val = self.string(forKey: attrName)
			let attr = try XMLSupport.exists(DDXMLNode.attribute(withName: attrName, stringValue:val), name: "Attribute for \(attrName)")
			thisElement.addAttribute(attr)
		}
		try saveChildrenAsXML(thisElement, elementName: LOGS    , collection: allLogEntries )
		try saveChildrenAsXML(thisElement, elementName: SKILLS  , collection: allSkills )
		try saveChildrenAsXML(thisElement, elementName: XP_GAINS, collection: allXPGains )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        let elemNotes = DDXMLElement.element(withName: NOTES, stringValue:self.notes ?? "")
        thisElement.addChild(elemNotes)
        return thisElement
    }


    
    func update(from element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(element, expectedName: CHAR_SHEET)

		// Use KVO to set the attributes from the XML element provided.
		for (attrName, attrType) in attributes {
			if let node = element.attribute(forName: attrName) {
				switch attrType {
				case .string:  setValue(node.stringValue, forKey: attrName)
				case .integer: setValue(Int(node.stringValue ?? "") ?? 0, forKey: attrName)
				}
			} else {
				NSLog("CharSheet import: Attribute named \(attrName) not found in the XML we are importing. Skipping it.")
			}
		}

        // Stats will have already been created, so just find each stat and update it.
        // Otherwise create a collection of the appropriate element and then replace the existing collection with it.
		for element in element.childElements {
			switch element.name ?? "" {
			case LOGS:
				let value = try XMLSupport.data(from: element, createFunc: { self.addLogEntry() })
				self.logs = NSMutableSet(array: value.array)
			case SKILLS:
				let value = try XMLSupport.data(from: element, createFunc: { self.addSkill() })
				self.skills = NSMutableOrderedSet(orderedSet: value)
			case XP_GAINS:
				let value = try XMLSupport.data(from: element, createFunc: { self.addXPGain() })
				self.xp = NSMutableOrderedSet(orderedSet: value)
			// Notes are stored as elements as they are too big to hold in attributes.
			case NOTES:
				self.notes = element.stringValue

			case CHAR_SHEET:
				throw XMLSupport.XMLError("XML CharSheet entity cannot contain another CharSheet entity.")
			default:
				throw XMLSupport.XMLError("XML entity \(element.name ?? "NULL") not recognised as child of \(CHAR_SHEET)")
            }
        }
        
 		// Rename the new sheet to avoid name clashes with an already-existing one, if any.
		try renameIfNecessary()
    }
}

