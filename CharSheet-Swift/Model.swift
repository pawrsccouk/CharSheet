//
//  Model.swift
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2016.
//  Copyright © 2016 Patrick Wallace. All rights reserved.
//

import CoreData

/// I represent the model as a whole. I maintain the list of char sheets and handle creation of new sheets.
class Model
{
	let coreDataController: CoreDataController

	init(coreDataController: CoreDataController)
	{
		self.coreDataController = coreDataController
	}

	/// Import a character sheet.
	///
	/// - parameter url: A file URL pointing at the document to load.
	/// - note: This decides whether the loaded data represents a new character or replaces an existing one.
	func importCharSheet(from url: URL) throws -> CharSheet
	{
		// Data will be a character sheet in XML format.  Import it and create a character for it.
		if !url.isFileURL {
			throw XMLSupport.XMLError("Error: URL: \(url) is not a file URL and isn't supported.")
		}

		let xmlData  = try Data(contentsOf: url)
		let document = try DDXMLDocument(data: xmlData, options: 0)
		guard let rootElement = document.rootElement() else {
			throw XMLSupport.XMLError("XMLDocument has no document node")
		}
		guard let node = rootElement.childElements.filter({ $0.name == "charSheet" }).first else {
			throw XMLSupport.XMLError("XMLDocument has no node named charSheet")
		}
		return try createCharSheetFromElement(node)
	}


	/// Creates a new CharSheet entity in Core Data's managed object context and returns it.
	func newCharacter() throws -> CharSheet
	{
		let context = coreDataController.managedObjectContext
		if let newCharacter = NSEntityDescription.insertNewObject(forEntityName: "CharSheet", into:context) as? CharSheet {
			newCharacter.name = "New Character"
			return newCharacter
		}
		throw XMLSupport.XMLError("Error creating character sheet from Core Data")
	}


	/// Creates a CharSheet object and pulls all the data from the XML element provided to initialize it.
	///
	/// - parameter element: The root element holding all the sub-elements for this character sheet.
	/// - returns: A newly-created CharSheet object which has been added to Core Data.
	/// - note: This deletes the new char sheet if anything goes wrong during the loading process.

	func createCharSheetFromElement(_ element: DDXMLElement) throws -> CharSheet
	{
		do {
			let newSheet = try newCharacter()
			do {
				try newSheet.update(from: element)
				return newSheet
			}
			catch let error as NSError {
				newSheet.delete()
				throw error
			}
		}
		catch let error as NSError {
			fatalError("Error creating a new empty CharSheet object: \(error), \(error.localizedDescription)")
		}
	}

	/// Triggers a Fetch in CoreData of all the CharSheet objects available to the system.
	func fetchAllCharacters() -> NSFetchedResultsController<NSFetchRequestResult>
	{
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
		fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CharSheet", in: coreDataController.managedObjectContext)
		fetchRequest.fetchBatchSize = 20    // Set the batch size to a suitable number.
		fetchRequest.sortDescriptors = [NSSortDescriptor(key:"name", ascending:false)]

		// nil for section name key path means "no sections".
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
		                                                          managedObjectContext: coreDataController.managedObjectContext,
		                                                          sectionNameKeyPath: nil,
		                                                          cacheName: nil)
		do {
			try fetchedResultsController.performFetch()
		} catch let error as NSError {
			// Replace this implementation with code to handle the error appropriately.
			NSLog("MasterViewController: Error performing fetch: %@, %@", error, error.userInfo);
			abort();
		}
		return fetchedResultsController
	}

}
