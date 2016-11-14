//
//  PWCharSheet.m
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
//

import Foundation
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


/// Model object for a character sheet, the root of the datamodel.
///
/// This subclasses NSManagedObject to give XML support and direct access to the entity properties.

class CharSheet : NSManagedObject
{    
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
		return max(0, strength - 12) + max(0, luck - 12)
	}

	var rangedAdds: Int {
		return max(0, luck - 12)
	}

	/// Sorted copy of the log entries, sorted by date & time.
	var sortedLogs: [LogEntry] {
		return logs.allObjects
			.map { $0 as! LogEntry }
			.sorted{
				let d1 = $0.dateTime
				return (d1 as NSDate).earlierDate($1.dateTime as Date) == d1 as Date
		}
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

    func addSkill(_ managedObjectContext: NSManagedObjectContext) -> Skill
	{
        return NSEntityDescription.insertNewObject(
			forEntityName: "Skill", into:managedObjectContext) as! Skill
    }

    func removeSkillAtIndex(_ index: Int)
	{
		if let skill = self.skills[index] as? Skill {
			self.skills.remove(skill)
			self.managedObjectContext?.delete(skill)
		}
    }

    func appendSkill() -> Skill
	{
        let newSkill = addSkill(self.managedObjectContext!)
        newSkill.parent = self
        self.skills.add(newSkill)
        return newSkill
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
    
    func removeLogEntry(_ entry: LogEntry)
	{
        self.logs.remove(entry)
        entry.parent = nil
    }

    // XP Gains

    func addXPGain(_ context: NSManagedObjectContext) -> XPGain
	{
        return NSEntityDescription.insertNewObject(
			forEntityName: "XPGain", into:context) as! XPGain
    }

    // Create a new xp entry and append it to the list. Returns the new xp.
    func appendXPGain() -> XPGain
	{
        let xpGain = addXPGain(self.managedObjectContext!)
        xpGain.parent  = self
        self.xp.add(xpGain)
        return xpGain
    }

        // Remove the xp entry at the given index. It will be destroyed at the next commit.
	func removeXPGainAtIndex(_ index: Int)
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
		guard let root = document.rootElement as? DDXMLElement else {
			fatalError("Document \(document) has invalid root element \(document.rootElement)")
		}
		root.addChild(self.asXML())
		guard let documentData = document.xmlData(withOptions: UInt(DDXMLNodeCompactEmptyElement)) else {
			throw XMLSupport.XMLError("document.XMLDataWithOptions failed for document \(document)")
		}
		return documentData
    }


	/// Check if a character name clashes with an already-existing name and update the name to make it unique.
	///
	/// Called after importing a character from XML, to avoid overwriting an existing character.
	fileprivate func renameIfNecessary() throws
	{
		/// Checks if parameter NAME already exists as the name of any other character.
		func nameAlreadyExists(_ name: String) throws -> Bool
		{
			let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CharSheet")
			request.predicate = NSPredicate(format:"name == %@", name)

			let count = try managedObjectContext?.count(for: request)
			assert(count != NSNotFound, "Error returned but exception not thrown.")
			return count > 1
		}


		// If the new character has the same name as an existing one, then append the import date to it.
		// e.g. "John Smith - Imported 23/11/2013 11:14pm"
		// so the user can compare it to the existing version and delete whichever they prefer.
		name = name ?? "Unknown"
		if try nameAlreadyExists(name!) {
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .medium
			name = String(format:"%@ : %@", name!, dateFormatter.string(from: Date()))
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
		("name", .string), ("gender", .string), ("game", .string), ("player", .string), ("level", .integer), ("experience", .integer),
		("strength", .integer), ("speed", .integer), ("dexterity", .integer), ("constitution", .integer),
		("perception", .integer), ("intelligence", .integer), ("charisma", .integer), ("luck", .integer)
	]

extension CharSheet: XMLClient
{
    fileprivate enum Element: String
	{
        case CHAR_SHEET = "charSheet"
		case SKILLS = "skills", LOGS = "logs", NOTES = "notes", XP_GAINS = "xp_gains"
    }
    
    func asXML() -> DDXMLElement
	{
        func saveChildrenAsXML(_ parent: DDXMLElement, elementName: Element, collection: [Any])
		{
            let element = DDXMLElement.element(withName: elementName.rawValue) as! DDXMLElement
            parent.addChild(element)
			for child in collection {
				let childNode = child as! XMLClient
				element.addChild(childNode.asXML())
			}
        }

        let thisElement = DDXMLElement.element(withName: Element.CHAR_SHEET.rawValue) as! DDXMLElement
		// Use KVO to get the attribute data.
		for (attrName, _) in attributes {
			let sv = ((value(forKey: attrName) ?? "") as AnyObject).description
			thisElement.addAttribute(DDXMLNode.attribute(withName: attrName, stringValue:sv) as! DDXMLNode)
		}
        saveChildrenAsXML(thisElement, elementName: .LOGS    , collection: logs.allObjects )
        saveChildrenAsXML(thisElement, elementName: .SKILLS  , collection: skills.array    )
        saveChildrenAsXML(thisElement, elementName: .XP_GAINS, collection: xp.array        )
        
        // Store notes as a separate element as it's too big to go as an attribute.
        let elemNotes = DDXMLElement.element(
			withName: Element.NOTES.rawValue, stringValue:self.notes) as! DDXMLElement
        thisElement.addChild(elemNotes)
        return thisElement
    }


    
    func updateFromXML(_ element: DDXMLElement) throws
	{
		try XMLSupport.validateElement(name: element.name, expectedName: Element.CHAR_SHEET.rawValue)

		// Use KVO to set the attributes from the XML element provided.
		for (attrName, attrType) in attributes {
			if let node = element.attribute(forName: attrName) {
				switch attrType {
				case .string:
					setValue(node.stringValue, forKey: attrName)
				case .integer:
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
					let value = try XMLSupport.dataFromNodes(node, createFunc: { self.addLogEntry() })
					self.logs = NSMutableSet(array: value.array)
                case .SKILLS:
					let value = try XMLSupport.dataFromNodes(node, createFunc: { self.addSkill(self.managedObjectContext!) })
					self.skills = NSMutableOrderedSet(orderedSet: value)
                case .XP_GAINS:
					let value = try XMLSupport.dataFromNodes(node, createFunc: { self.addXPGain(self.managedObjectContext!) })
					self.xp = NSMutableOrderedSet(orderedSet: value)
                    // Notes are stored as elements as they are too big to hold in attributes.
                case .NOTES:
					self.notes = node.stringValue
                    
                case .CHAR_SHEET:
					throw XMLSupport.XMLError("XML CharSheet entity cannot contain another CharSheet entity.")
                }
            }
            else {
				throw XMLSupport.XMLError("XML entity \(node.name) not recognised as child of \(Element.CHAR_SHEET)")
            }
        }
        
 		// Rename the new sheet to avoid name clashes with an already-existing one, if any.
		try renameIfNecessary()
    }
}

