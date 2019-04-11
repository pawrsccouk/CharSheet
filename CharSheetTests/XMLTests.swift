//
//  XMLTests.swift
//  CharSheet
//
//  Created by Patrick Wallace on 18/11/2016.
//  Copyright © 2016 Patrick Wallace. All rights reserved.
//

import XCTest
import CoreData
import Foundation
@testable import CharSheet

//fileprivate func newCharacter(context: NSManagedObjectContext, entity: NSEntityDescription) throws -> CharSheet
//{
//	if let entName = entity.name, let newCharacter = NSEntityDescription.insertNewObject(forEntityName: entName, into:context) as? CharSheet {
//		newCharacter.name = "XCTest Character"
//		return newCharacter
//	}
//	fatalError("Error creating character sheet from Core Data")
//}

fileprivate func count(ofEntity entityName: String, inContext context: NSManagedObjectContext) throws -> Int
{
	let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
	return try context.count(for: fetchedRequest)
}

fileprivate let notset: String = "not-set"

fileprivate func testAttrib(element: DDXMLElement, attribName: String, expectedText: String)
{
	let attr = element.attribute(forName: attribName)
	XCTAssertNotNil(attr, "Attribute [\(attribName)] not present.")
	XCTAssertEqual(attr?.stringValue ?? notset, expectedText, "Attribute [\(attribName)] not \(expectedText).")
}

// MARK: -

class XMLTests: XCTestCase {

	private var charSheet: CharSheet!
	private var coreDataController: CoreDataController!
	private var model: Model!

	// This method is called before the invocation of each test method in the class.
    override func setUp()
	{
        super.setUp()

		do {
			coreDataController = try CoreDataController(persistentStoreName: "CharSheetTests.sqlite")
		} catch let error as NSError {
			XCTFail("Failed to initialize Core Data with error \(error), \(error.userInfo)")
		}
		model = Model(coreDataController: coreDataController)

		// Ensure the datastore is empty before the test runs.
		do {
			var c = try count(ofEntity: "CharSheet", inContext: coreDataController.managedObjectContext)
			XCTAssertEqual(c, 0, "The CharSheet table was not empty on startup.")
			c = try count(ofEntity: "Skill", inContext: coreDataController.managedObjectContext)
			XCTAssertEqual(c, 0, "The Skill table was not empty on startup.")
			c = try count(ofEntity: "XPGain", inContext: coreDataController.managedObjectContext)
			XCTAssertEqual(c, 0, "The XPGain table was not empty on startup.")
			c = try count(ofEntity: "Specialty", inContext: coreDataController.managedObjectContext)
			XCTAssertEqual(c, 0, "The Specialty table was not empty on startup.")
		} catch let error as NSError {
			XCTFail("Failed to query the datastore for initial values: error \(error), \(error.userInfo)")
		}

		// Create a default character to act as a parent to other objects.
		do {
			charSheet = try model.newCharacter()
		} catch let error as NSError {
			XCTFail("Failed to create character with error \(error), \(error.userInfo)")
		}
    }
    
	// This method is called after the invocation of each test method in the class.
    override func tearDown()
	{
        super.tearDown()
    }

    func testXPGainSave()
	{
		let reasonText = "Test Reason 1"
		let amtNum:Int16 = 1001, amtText = "1001"
		let xpGain1 = charSheet.addXPGain()
		xpGain1.reason = reasonText
		xpGain1.amount = amtNum

		do {
			let xmlElement = try xpGain1.asXML()
			XCTAssertEqual(xmlElement.name ?? notset, "xpEntry", "Element name not xpEntry")
			XCTAssertEqual(xmlElement.attributes?.count ?? 0, 2, "xpEntry element doesn't have 2 attributes.")

			testAttrib(element: xmlElement, attribName: "amount", expectedText: amtText)
			testAttrib(element: xmlElement, attribName: "reason", expectedText: reasonText)
		}
		catch let error as NSError {
			XCTFail("XPGain.asXML failed with error \(error), \(error.userInfo)")
		}
    }

	func testXPGainLoad()
	{
		let reasonText = "Test Reason XPGain", amtTxt = "2211", amtNum: Int16 = 2211
		let xmlXPGain = DDXMLElement(name: "xpEntry")
		xmlXPGain.addAttribute(DDXMLNode.attribute(withName: "amount", stringValue: amtTxt) as! DDXMLNode)
		xmlXPGain.addAttribute(DDXMLNode.attribute(withName: "reason", stringValue: reasonText) as! DDXMLNode)

		let xpGain = charSheet.addXPGain()
		do {
			try xpGain.update(from: xmlXPGain)
		} catch let error as NSError {
			XCTFail("xpGain.update failed with error \(error), \(error.userInfo)")
		}

		XCTAssertEqual(xpGain.reason, reasonText, "Reason didn't match XML attribute.")
		XCTAssertEqual(xpGain.amount, amtNum, "Amount didnt match XML attribute.")
	}

	func testSkillSave()
	{
		let nameText = "Test name 1"
		let valueNum: Int16 = 1001, valueString = "1001"
		let ticksNum: Int16 = 17, ticksString = "17"

		let skill = charSheet.addSkill()
		skill.name = nameText
		skill.value = valueNum
		skill.ticks = ticksNum

		do {
			let xmlElement = try skill.asXML()
			XCTAssertEqual(xmlElement.name ?? notset, "skill", "Element name not skill")
			XCTAssertEqual(xmlElement.attributes?.count ?? 0, 3, "Skill element doesn't have 3 attributes.")

			testAttrib(element: xmlElement, attribName: "value", expectedText: valueString)
			testAttrib(element: xmlElement, attribName: "name" , expectedText: nameText)
			testAttrib(element: xmlElement, attribName: "ticks", expectedText: ticksString)
		}
		catch let error as NSError {
			XCTFail("Skill.asXML failed with error \(error), \(error.userInfo)")
		}
	}

	func testSkillLoad()
	{
		let nameText = "Test Skill name"
		let valueNum: Int16 = 2221, valueString = "2221"
		let ticksNum: Int16 = 27, ticksString = "27"

		let xmlSkill = DDXMLElement(name: "skill")
		xmlSkill.addAttribute(DDXMLNode.attribute(withName: "value", stringValue: valueString) as! DDXMLNode)
		xmlSkill.addAttribute(DDXMLNode.attribute(withName: "name" , stringValue: nameText   ) as! DDXMLNode)
		xmlSkill.addAttribute(DDXMLNode.attribute(withName: "ticks", stringValue: ticksString) as! DDXMLNode)

		let skill = charSheet.addSkill()
		do {
			try skill.update(from: xmlSkill)
		} catch let error as NSError {
			XCTFail("skill.update() failed with error \(error), \(error.userInfo)")
		}

		XCTAssertEqual(skill.name , nameText, "Name didn't match XML attribute.")
		XCTAssertEqual(skill.value, valueNum, "Value didnt match XML attribute.")
		XCTAssertEqual(skill.ticks, ticksNum, "Ticks didnt match XML attribute.")
	}

	func testSpecialtySave()
	{
		let nameText = "Test name 1"
		let valueNum: Int16 = 1001, valueString = "1001"

		let skill = charSheet.addSkill()
		let specialty = skill.addSpecialty()
		specialty.name = nameText
		specialty.value = valueNum

		do {
			let xmlElement = try specialty.asXML()
			XCTAssertEqual(xmlElement.name ?? notset, "specialty", "Element name not specialty")
			XCTAssertEqual(xmlElement.attributes?.count ?? 0, 2, "Specialty element doesn't have 2 attributes.")

			testAttrib(element: xmlElement, attribName: "value", expectedText: valueString)
			testAttrib(element: xmlElement, attribName: "name" , expectedText: nameText)
		}
		catch let error as NSError {
			XCTFail("Specialty.asXML failed with error \(error), \(error.userInfo)")
		}
	}

	func testSpecialtyLoad()
	{
		let nameText = "Test Specialty name"
		let valueNum: Int16 = 3003, valueString = "3003"

		let xmlSpec = DDXMLElement(name: "specialty")
		xmlSpec.addAttribute(DDXMLNode.attribute(withName: "value", stringValue: valueString) as! DDXMLNode)
		xmlSpec.addAttribute(DDXMLNode.attribute(withName: "name" , stringValue: nameText   ) as! DDXMLNode)

		let skill = charSheet.addSkill()
		let specialty = skill.addSpecialty()
		do {
			try specialty.update(from: xmlSpec)
		} catch let error as NSError {
			XCTFail("specialty.update() failed with error \(error), \(error.userInfo)")
		}

		XCTAssertEqual(specialty.name , nameText, "Name didn't match XML attribute.")
		XCTAssertEqual(specialty.value, valueNum, "Value didnt match XML attribute.")
	}

	func testCharSheetSave()
	{
		XCTAssertNotNil(charSheet, "charSheet not created.")

		let ageNum:Int16 = 65, ageStr = "65", expNum:Int32 = 2500, expStr = "2500"
		let levelNum:Int16 = 33, levelStr = "33", woundsNum:Int16 = 23, /* woundsStr = "23",*/ subdualNum:Int16 = 32 /*, subdualStr = "32" */
		let gameText = "Game Text", genderText = "Gender Text", nameText = "Name Text", playerText = "Player Text"
		let dexNum:Int16 = 11, dexStr = "11", strNum:Int16 = 22, strStr = "22"
		let conNum:Int16 = 33, conStr = "33", spdNum:Int16 = 44, spdStr = "44"
		let intNum:Int16 = 55, intStr = "55", perNum:Int16 = 66, perStr = "66"
		let lckNum:Int16 = 77, lckStr = "77", chaNum:Int16 = 88, chaStr = "88"
		let notesText = "Here are some notes. \n" + "They span multiple lines \n" + "and can include < and > and & characters."

		charSheet.age = ageNum
		charSheet.level = levelNum
		charSheet.experience = expNum
		charSheet.woundsPhysical = woundsNum
		charSheet.woundsSubdual = subdualNum
		charSheet.game = gameText
		charSheet.gender = genderText
		charSheet.name = nameText
		charSheet.notes = notesText
		charSheet.player = playerText
		charSheet.dexterity = dexNum
		charSheet.strength = strNum
		charSheet.constitution = conNum
		charSheet.speed = spdNum
		charSheet.intelligence = intNum
		charSheet.perception = perNum
		charSheet.luck = lckNum
		charSheet.charisma = chaNum

		do {
			let xmlElement = try charSheet.asXML()
			XCTAssertEqual(xmlElement.name ?? notset, "charSheet", "Element name not charSheet")
			XCTAssertEqual(xmlElement.attributes?.count ?? 0, 15, "CharSheet element doesn't have 18 attributes.")

			testAttrib(element: xmlElement, attribName: "age"           , expectedText: ageStr)
			testAttrib(element: xmlElement, attribName: "level"         , expectedText: levelStr)
			testAttrib(element: xmlElement, attribName: "experience"    , expectedText: expStr)

			testAttrib(element: xmlElement, attribName: "game"  , expectedText: gameText)
			testAttrib(element: xmlElement, attribName: "gender", expectedText: genderText)
			testAttrib(element: xmlElement, attribName: "name"  , expectedText: nameText)
			testAttrib(element: xmlElement, attribName: "player", expectedText: playerText)

			testAttrib(element: xmlElement, attribName: "dexterity"   , expectedText: dexStr)
			testAttrib(element: xmlElement, attribName: "strength"    , expectedText: strStr)
			testAttrib(element: xmlElement, attribName: "constitution", expectedText: conStr)
			testAttrib(element: xmlElement, attribName: "speed"       , expectedText: spdStr)
			testAttrib(element: xmlElement, attribName: "intelligence", expectedText: intStr)
			testAttrib(element: xmlElement, attribName: "perception"  , expectedText: perStr)
			testAttrib(element: xmlElement, attribName: "luck"        , expectedText: lckStr)
			testAttrib(element: xmlElement, attribName: "charisma"    , expectedText: chaStr)

			// Not implemented yet.
			// testAttrib(element: xmlElement, attribName: "woundsPhysical", expectedText: woundsStr)
			// testAttrib(element: xmlElement, attribName: "woundsSubdual" , expectedText: subdualStr)

			// notes is a sub-element, not an attribute.
			var xmlNotesElement: DDXMLElement?
			for xmlChild in xmlElement.children ?? [] {
				if xmlChild.name == "notes" {
					xmlNotesElement = xmlChild as? DDXMLElement
				}
			}
			guard let xmlNotes = xmlNotesElement else {
				XCTFail("Element [notes] not found under CharSheet element.")
				fatalError()
			}
			XCTAssertEqual(xmlNotes.stringValue, notesText)
		}
		catch let error as NSError {
			XCTFail("CharSheet.asXML failed with error \(error), \(error.userInfo)")

		}
	}

	func testCharSheetLoad()
	{
		XCTAssertNotNil(charSheet, "charSheet not created.")

		let ageNum:Int16 = 45, ageStr = "45", expNum:Int32 = 2720, expStr = "2720"
		let levelNum:Int16 = 33, levelStr = "33"
		let gameText = "Game Text", genderText = "Gender Text", nameText = "Name Text", playerText = "Player Text"
		let dexNum:Int16 = 14, dexStr = "14", strNum:Int16 = 32, strStr = "32"
		let conNum:Int16 = 34, conStr = "34", spdNum:Int16 = 54, spdStr = "54"
		let intNum:Int16 = 54, intStr = "54", perNum:Int16 = 76, perStr = "76"
		let lckNum:Int16 = 74, lckStr = "74", chaNum:Int16 = 98, chaStr = "98"
		let notesText = "Here are some notes. \n" + "Spanning multiple lines \n" + "and including < and > and & characters."

		let xmlCharSheet = DDXMLElement(name: "charSheet")
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "age"       , stringValue: ageStr  ) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "level"     , stringValue: levelStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "experience", stringValue: expStr  ) as! DDXMLNode)

		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "game"   , stringValue: gameText  ) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "gender" , stringValue: genderText) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "name"   , stringValue: nameText  ) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "player" , stringValue: playerText) as! DDXMLNode)

		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "dexterity"   , stringValue: dexStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "strength"    , stringValue: strStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "constitution", stringValue: conStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "speed"       , stringValue: spdStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "intelligence", stringValue: intStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "perception"  , stringValue: perStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "charisma"    , stringValue: chaStr) as! DDXMLNode)
		xmlCharSheet.addAttribute(DDXMLNode.attribute(withName: "luck"        , stringValue: lckStr) as! DDXMLNode)

		let xmlNotes = DDXMLNode.element(withName: "notes", stringValue: notesText) as! DDXMLElement
		xmlCharSheet.addChild(xmlNotes)

		do {
			try charSheet.update(from: xmlCharSheet)
		}
		catch let error as NSError {
			XCTFail("charSheet.update() failed with error \(error), \(error.userInfo)")
		}

		XCTAssertEqual(charSheet.age       , ageNum)
		XCTAssertEqual(charSheet.level     , levelNum)
		XCTAssertEqual(charSheet.experience, expNum)

		XCTAssertEqual(charSheet.game  , gameText)
		XCTAssertEqual(charSheet.gender, genderText)
		XCTAssertEqual(charSheet.name  , nameText)
		XCTAssertEqual(charSheet.player, playerText)

		XCTAssertEqual(charSheet.dexterity   , dexNum)
		XCTAssertEqual(charSheet.strength    , strNum)
		XCTAssertEqual(charSheet.speed       , spdNum)
		XCTAssertEqual(charSheet.constitution, conNum)
		XCTAssertEqual(charSheet.intelligence, intNum)
		XCTAssertEqual(charSheet.charisma    , chaNum)
		XCTAssertEqual(charSheet.perception  , perNum)
		XCTAssertEqual(charSheet.luck        , lckNum)

		XCTAssertEqual(charSheet.notes, notesText)
	}

	// Load an XML file externally and ensure all the details match.
	// This is an actual file as-used in game.
	func testFullLoad()
	{
		let notesText = "Erich has a cave in Shangri-La as an office, and is working with the spider gods.\n" +
		"However, he has refused to allow the Spider Clan to install spider monitors in his house.\n"

		guard let xmlPath = Bundle(for: XMLTests.self).url(forResource: "TestCharacter", withExtension: "charSheet") else {
			XCTFail("File TestCharacter.charSheet not found in the bundle.")
			return
		}
		do {
			let charSheet = try model.importCharSheet(from: xmlPath)

			XCTAssertNotNil(charSheet, "Import returned null char sheet.")

			// Test the stats and attributes (i.e. everything that isn't a separate object).
			XCTAssertEqual(charSheet.age       , 0)  // age was not saved in the source file so defaults to 0.
			XCTAssertEqual(charSheet.level     , 5)
			XCTAssertEqual(charSheet.experience, 12600)

			XCTAssertEqual(charSheet.game  , "Shadowrun")
			XCTAssertEqual(charSheet.gender, "")
			XCTAssertEqual(charSheet.name  , "Erich Stinnes")
			XCTAssertEqual(charSheet.player, "Pat Wallace")

			XCTAssertEqual(charSheet.dexterity   , 8)
			XCTAssertEqual(charSheet.strength    , 7)
			XCTAssertEqual(charSheet.speed       , 10)
			XCTAssertEqual(charSheet.constitution, 8)
			XCTAssertEqual(charSheet.intelligence, 15)
			XCTAssertEqual(charSheet.charisma    , 17)
			XCTAssertEqual(charSheet.perception  , 28)
			XCTAssertEqual(charSheet.luck        , 12)

			XCTAssertEqual(charSheet.notes!, notesText)

			// Test the skills and one or two of the specialties.
			XCTAssertEqual(charSheet.skills.count, 27, "Skills count incorrect.")
			let martialArtsSkill: Skill! = charSheet.allSkills
				.filter { $0.name == "Martial Arts" }
				.first
			XCTAssertNotNil(martialArtsSkill)
			XCTAssertEqual(martialArtsSkill.name, "Martial Arts")
			XCTAssertEqual(martialArtsSkill.value, 1)
			XCTAssertEqual(martialArtsSkill.ticks, 2)

			XCTAssertEqual(martialArtsSkill.specialties.count, 1)
			let taiChiSpecialty = martialArtsSkill.specialties.array.first as! Specialty
			XCTAssertNotNil(taiChiSpecialty)
			XCTAssertEqual(taiChiSpecialty.name, "Tai-Chi")
			XCTAssertEqual(taiChiSpecialty.value, 1)

			let chicSkill: Skill! = charSheet.allSkills
				.filter { $0.name == "Chic" }
				.first
			XCTAssertEqual(chicSkill.name, "Chic")
			XCTAssertEqual(chicSkill.value, 2)
			XCTAssertEqual(chicSkill.ticks, 11)
			XCTAssertEqual(chicSkill.specialties.count, 0, "Chic should have no specialties.")

			// Test the XP gains.
			XCTAssertEqual(charSheet.allXPGains.count, 15)
			let pyroGain: XPGain! = charSheet.allXPGains
				.filter { $0.reason == "Adventure: Pyromancer" }
				.first
			XCTAssertNotNil(pyroGain)
			XCTAssertEqual(pyroGain.reason, "Adventure: Pyromancer")
			XCTAssertEqual(pyroGain.amount, 350)

			XCTAssertEqual(charSheet.allLogEntries.count, 104)
			// Get the newest and the oldest log entry and ensure they are correct.

			let dateFormatter = DateFormatter()
			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

			let allEntries = charSheet.allLogEntries.sorted { $0.dateTime < $1.dateTime }

			let firstEntry = allEntries.first!
			XCTAssertEqual(firstEntry.summary, "Per + ES: Urban")
			let dateFirst = dateFormatter.date(from: "2013-01-17 21:03:04")
			XCTAssertEqual(firstEntry.dateTime, dateFirst)

			let lastEntry = allEntries.last!
			XCTAssertEqual(lastEntry.summary, "Cha + ")
			let dateLast = dateFormatter.date(from: "2016-02-23 22:18:22")
			XCTAssertEqual(lastEntry.dateTime, dateLast)

		} catch let error as NSError {
			XCTFail("Failed to import char sheet from [\(xmlPath)] with error \(error), \(error.userInfo)")
		}
	}

//	func testFullSave()
//	{
//		XCTFail("Not implemented")
//	}
}
