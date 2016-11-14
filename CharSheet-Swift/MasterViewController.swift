//
//  PWMasterViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 23/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

import UIKit
import CoreData


/// This controller manages a table view showing all the characters available in the database.
/// Selecting one updates the detail view (a **CharSheetUseViewController**) setting a new Character into it.
///
/// The user can also add and delete characters with the toolbar icons.

class MasterViewController : UITableViewController
{
    var detailViewController: CharSheetUseViewController!
    var managedObjectContext: NSManagedObjectContext!

	/// Triggers a Fetch in CoreData of all the CharSheet objects available to the system.
	func fetchAllCharacters() -> NSFetchedResultsController<NSFetchRequestResult>
	{
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
		fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CharSheet", in:self.managedObjectContext)
		fetchRequest.fetchBatchSize = 20    // Set the batch size to a suitable number.
		fetchRequest.sortDescriptors = [NSSortDescriptor(key:"name", ascending:false)]

		// nil for section name key path means "no sections".
		let fetchedResultsController = NSFetchedResultsController(
			fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "Characters")
		fetchedResultsController.delegate = self

		do {
			try fetchedResultsController.performFetch()
		} catch let error as NSError {
			// Replace this implementation with code to handle the error appropriately.
			NSLog("MasterViewController: Error performing fetch: %@, %@", error, error.userInfo);
			abort();
		}
		return fetchedResultsController
	}

	/// Stores the results of fetching all the characters available in Core Data.
	///
	/// Generates the fetched results controller for this request only if it is needed.
	lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = { self.fetchAllCharacters() }()

	/// Creates a CharSheet object and pulls all the data from the XML element provided to initialize it.
	///
	/// - parameter element: The root element holding all the sub-elements for this character sheet.
	/// - returns: A newly-created CharSheet object which has been added to Core Data.
	/// :note: This deletes the new char sheet if anything goes wrong during the loading process.

	fileprivate func createCharSheetFromElement(_ element: DDXMLElement) throws -> CharSheet
	{
		do {
			let newSheet = try newCharacter()
			do {
				try newSheet.updateFromXML(element)
				return newSheet
			}
			catch let error as NSError {
				deleteCharSheet(newSheet)
				throw error
			}
		}
		catch let error as NSError {
			fatalError("Error creating a new empty CharSheet object: \(error), \(error.localizedDescription)")
		}
	}

	/// Import a character sheet.
	///
	/// - parameter URL: A file URL pointing at the document to load.
	/// :todo: This should be in the model somewhere, not in a view controller.
	///        I need to create a class to represent "all the character sheets".
	/// :note: This decides whether the loaded data represents a new character or replaces an existing one.
    func importURL(_ url: URL) throws
	{
		func findElement(_ document: DDXMLDocument, nodeName: String) throws -> DDXMLElement
		{
			if let node = (document.rootElement.children as! [DDXMLElement]).filter({ $0.name == nodeName }).first {
				return node
			}
			throw XMLSupport.XMLError("XMLDocument has no node named \(nodeName)")
		}

        // Data will be a character sheet in XML format.  Import it and create a character for it.
        if !url.isFileURL {
            throw XMLSupport.XMLError("Error: URL: \(url) is not a file URL and isn't supported.")
        }

		let xmlData = try? Data(contentsOf: url)
		let document = try DDXMLDocument(data: xmlData!, options: 0)
		let rootNode = try findElement(document, nodeName: "charSheet")
		_ = try createCharSheetFromElement(rootNode)
	}

    override func viewDidLoad()
	{
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = false
        navigationItem.leftBarButtonItem = editButtonItem

		if let
			viewControllers = splitViewController?.viewControllers,
			let navController = viewControllers.last as? UINavigationController,
			let useViewController = navController.topViewController as? CharSheetUseViewController
		{
			useViewController.managedObjectContext = managedObjectContext
			detailViewController = useViewController
		} else {
			let detailView = splitViewController?.viewControllers.first
			fatalError("Failed to get detail view controller from split view array. Is \(detailView)")
		}

		// If we have a view with no character sheet set,
		// then find the sheet we were looking at last time and set it here by default.
		detailViewController.defaultCharSheet = lastViewedCharSheet()
    }


	/// Returns the last CharSheet the user was viewing before they exited the app.
	///
	/// This is stored in the UserDefaults and used to pre-set the character sheet on app startup.
	fileprivate func lastViewedCharSheet() -> CharSheet?
	{
		let allObjects = fetchedResultsController.sections?.flatMap({ (sectionInfo: AnyObject) in
			return (sectionInfo as! NSFetchedResultsSectionInfo).objects as! [CharSheet]
		})
		if let lastViewedSheetName = UserDefaults.standard.string(forKey: "LastSelectedCharacter")
		{
			return allObjects?.filter({ $0.name == lastViewedSheetName }).first
		}
		return nil
	}

	/// Find the most appropriate error text by searching the userInfo dicts of any nested errors.
	///
	/// The userInfo dict of the error can have an array of other error under the NSDetailedErrorsKey.
	/// If so, search that array and add to the text returned.
	///
	/// - parameter error: The error to search.
	/// - returns: Text formatted for a user to read describing the error.
	fileprivate func textFromError(_ error: NSError) -> String
	{
        var errorText = "Unknown error"
		if let fullInfo = error.userInfo[NSHelpAnchorErrorKey] as? String {
			errorText = fullInfo
		}
		// If there are multiple errors, then the userInfo of the error will have a value for NSDetailedErrors
		// and these errors show the actual problem.
		// Get the first one, and show it.
		if let
			errorDetail = error.userInfo[NSDetailedErrorsKey] as? [NSError],
			let fullInfo    = errorDetail.first?.userInfo[NSHelpAnchorErrorKey] as? String
		{
			errorText = fullInfo
			if errorDetail.count > 1 {
				errorText += "\nand \(errorDetail.count) more..."
			}
			// Log them all
			for e in errorDetail {
				NSLog("Core Data error \(e) userInfo \(e.userInfo)")
			}
		}
		return errorText
	}

	/// Present a view controller displaying the provided error.
	///
	/// - parameter error: The error to display.
	/// - parameter title:  The title displayed on the error window.
	func showAlertForError(_ error: NSError, title: String)
	{
		let errorText = textFromError(error)
		let alertController = UIAlertController(title: title, message: errorText, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Close",style: .default) { (action) in
			self.dismiss(animated: true, completion: nil)
			})
		present(alertController, animated: true, completion: nil)
   }

	/// Creates a new CharSheet entity in Core Data's managed object context and returns it.
	fileprivate func newCharacter() throws -> CharSheet
	{
		let context  = fetchedResultsController.managedObjectContext
		if let
			entCharacter = fetchedResultsController.fetchRequest.entity,
			let entName      = entCharacter.name,
			let newCharacter = NSEntityDescription.insertNewObject(forEntityName: entName,
				into:context) as? CharSheet
		{
			newCharacter.name = "New Character"
			return newCharacter
		}
		throw XMLSupport.XMLError("Error creating character sheet from Core Data")
	}

    @IBAction func insertNewCharSheet(_ sender: AnyObject?)
	{
		do {
			_ = try newCharacter()
		}
		catch let error as NSError {
			showAlertForError(error, title: "Error inserting new character sheet.")
		}
		// Save the character immediately.
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
    }
    
    fileprivate func deleteCharSheet(_ charSheet: CharSheet)
	{
        fetchedResultsController.managedObjectContext.delete(charSheet)
        // Blank the detail view if we were looking at this sheet when it was deleted.
        if let dcs = detailViewController.charSheet, dcs == charSheet {
            detailViewController.charSheet = nil
        }
    }
}


// MARK: - Table View Data Source

extension MasterViewController // : UITableViewDataSource
{
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView,  numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections {
            return sectionInfo[section].numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell
	{
		let CELL_ID = "MasterViewController_Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID) ?? UITableViewCell(style:.subtitle, reuseIdentifier:CELL_ID)
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
}

// MARK: - Table View Delegate

extension MasterViewController // : UITableViewDelegate
{
    override func tableView(  _ tableView: UITableView,
		canEditRowAt indexPath: IndexPath) -> Bool
	{
        return true    // All the rows are editable
    }
    
    override func tableView(  _ tableView: UITableView,
		commit editingStyle: UITableViewCellEditingStyle,
		forRowAt     indexPath: IndexPath)
	{
        if editingStyle == .delete, let sheet = fetchedResultsController.object(at: indexPath) as? CharSheet {
			deleteCharSheet(sheet)
			NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
        }
    }
    
    override func tableView(  _ tableView: UITableView,
		canMoveRowAt indexPath: IndexPath) -> Bool
	{
        return false    // The table view should not be re-orderable.
    }

    override func tableView(    _ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath)
	{
		if let sheet = fetchedResultsController.object(at: indexPath) as? CharSheet {
			detailViewController.charSheet = sheet

			// Store the last selection so I can automatically restore it when the app starts up.
			UserDefaults.standard.setValue(sheet.name ?? "", forKey: "LastSelectedCharacter")
		}
    }
}


    //MARK: - Fetched results controller
extension MasterViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
        tableView.beginUpdates()
    }
    
    func controller(      _ controller: NSFetchedResultsController<NSFetchRequestResult>,
		didChange sectionInfo: NSFetchedResultsSectionInfo,
		atSectionIndex         sectionIndex: Int,
		for     changeType: NSFetchedResultsChangeType)
	{
        switch(changeType) {
        case .insert:
            tableView.insertSections(IndexSet(integer:sectionIndex), with:.fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer:sectionIndex), with:.fade)
        default:
            break
        }
    }


	func controller(  _ controller: NSFetchedResultsController<NSFetchRequestResult>,
		didChange anObject: Any,
		at    indexPath: IndexPath?,
		for changeType: NSFetchedResultsChangeType,
		newIndexPath            : IndexPath?)
	{
		switch(changeType) {
		case .insert:
			if let newIP = newIndexPath {
				tableView.insertRows(at: [newIP], with: UITableViewRowAnimation.fade)
			}
		case .delete:
			if let ip = indexPath {
				tableView.deleteRows(at: [ip], with: UITableViewRowAnimation.fade)
			}
		case .update:
			if let ip = indexPath, let cell = tableView.cellForRow(at: ip) {
				configureCell(cell, atIndexPath:ip)

				// Store the new name so I can automatically restore it when the app starts up.
				// This assumes you only change the name of the character you're currently working on.
				if let sheet = fetchedResultsController.object(at: ip) as? CharSheet {
					UserDefaults.standard.setValue(sheet.name ?? "", forKey: "LastSelectedCharacter")
				}
			}
		case .move:
			if let ip = indexPath, let newIP = newIndexPath {
				tableView.deleteRows(at: [ip],   with: UITableViewRowAnimation.fade)
				tableView.insertRows(at: [newIP],with: UITableViewRowAnimation.fade)
			}
		}
	}


	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
		tableView.endUpdates()
	}



	fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath:IndexPath)
	{
		if let sheet = fetchedResultsController.object(at: indexPath) as? CharSheet {
			if let name = sheet.name, let l = cell.textLabel {
				l.text = name
			}
			if let label = cell.detailTextLabel, let game = sheet.game {
				label.text = game
			}
		}
	}

}
