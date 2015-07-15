//
//  PWMasterViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 23/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

import UIKit
import CoreData



class MasterViewController : UITableViewController {

    var detailViewController: CharSheetUseViewController!
    var managedObjectContext: NSManagedObjectContext!

	/// Triggers a Fetch in CoreData of all the CharSheet objects available to the system.
	private func fetchAllCharacters() -> NSFetchedResultsController
	{
		var fetchRequest = NSFetchRequest()
		fetchRequest.entity = NSEntityDescription.entityForName("CharSheet", inManagedObjectContext:self.managedObjectContext)
		fetchRequest.fetchBatchSize = 20    // Set the batch size to a suitable number.
		fetchRequest.sortDescriptors = [NSSortDescriptor(key:"name", ascending:false)]

		// nil for section name key path means "no sections".
		let fetchedResultsController = NSFetchedResultsController(
			fetchRequest        : fetchRequest,
			managedObjectContext: self.managedObjectContext,
			sectionNameKeyPath  : nil,
			cacheName           : "Characters")
		fetchedResultsController.delegate = self

		var error: NSError? //Pointer()
		if !fetchedResultsController.performFetch(&error) {
			// Replace this implementation with code to handle the error appropriately.
			if let err = error {
				NSLog("MasterViewController: Error performing fetch: %@, %@", err, err.userInfo ?? "[]");
			} else {
				NSLog("MasterViewController: Unknown error performing fetch.")
			}
			abort();
		}
		return fetchedResultsController
	}

	/// Stores the results of fetching all the characters available in Core Data.
	///
	/// Generates the fetched results controller for this request only if it is needed.
	lazy var fetchedResultsController: NSFetchedResultsController = { self.fetchAllCharacters() }()

	/// Creates a CharSheet object and pulls all the data from the XML element provided to initialize it.
	///
	/// :param: element The root element holding all the sub-elements for this character sheet.
	/// :returns: A newly-created CharSheet object which has been added to Core Data.
	/// :note: This deletes the new char sheet if anything goes wrong during the loading process.

	private func createCharSheetFromElement(element: DDXMLElement) -> Result<CharSheet>
	{
		return newCharacter()
		.andThen { charSheet in
			switch charSheet.updateFromXML(element) {
			case .Error(let error):
				self.deleteCharSheet(charSheet)
				return failure(error)
			case .Success:
				return success(charSheet)
			}
		}
	}

	/// Import a character sheet.
	///
	/// :param: URL A file URL pointing at the document to load.
	/// :todo: This should be in the model somewhere, not in a view controller.
	///        I need to create a class to represent "all the character sheets".
	/// :note: This decides whether the loaded data represents a new character or replaces an existing one.
    func importURL(url: NSURL) -> NilResult
	{
		func findElement(document: DDXMLDocument, nodeName: String) -> Result<DDXMLElement>
		{
			if let node = (document.rootElement.children as! [DDXMLElement]).filter({ $0.name == nodeName }).first {
				return success(node)
			}
			return failure(XMLSupport.XMLError("XMLDocument has no node named \(nodeName)"))
		}

        // Data will be a character sheet in XML format.  Import it and create a character for it.
        if !url.fileURL {
            return XMLSupport.XMLFailure("Error: URL: \(url) is not a file URL and isn't supported.")
        }

		let xmlData = NSData(contentsOfURL:url)
		return DDXMLDocument.documentWithData(xmlData!, options: 0)
			.andThen { findElement($0, "charSheet") }
			.andThen { self.createCharSheetFromElement($0).nilResult() }
	}

    override func viewDidLoad()
	{
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = false
        navigationItem.leftBarButtonItem = editButtonItem()
        
        detailViewController = splitViewController?.viewControllers.last?.topViewController as! CharSheetUseViewController
        detailViewController.managedObjectContext = managedObjectContext

		// If we have a view with no character sheet set,
		// then find the sheet we were looking at last time and set it here by default.
		detailViewController.defaultCharSheet = lastViewedCharSheet()
    }


	/// Returns the last CharSheet the user was viewing before they exited the app.
	///
	/// This is stored in the UserDefaults and used to pre-set the character sheet on app startup.
	private func lastViewedCharSheet() -> CharSheet?
	{
		let allObjects = fetchedResultsController.sections?.flatMap({ (sectionInfo: AnyObject) in
			return (sectionInfo as! NSFetchedResultsSectionInfo).objects as! [CharSheet]
		})
		if let lastViewedSheetName = NSUserDefaults.standardUserDefaults().stringForKey("LastSelectedCharacter")
		{
			return allObjects?.filter({ $0.name == lastViewedSheetName }).first
		}
		return nil
	}

	/// Extract the error object from a Result, and present a view controller displaying the error.
	///
	/// Does nothing if result is successful.
	///
	/// :param: result The result to display.
	/// :param: title  The title displayed on the error window.
	func showAlertForResult<T>(result: Result<T>, title: String)
	{
		// Show nothing if this isn't an error result.
		if result.error == nil {
			return
		}
		let error = result.error!

        var errorText = "Unknown error"
        if let userInfo = error.userInfo {
            if let fullInfo = userInfo[NSHelpAnchorErrorKey] as? String {
                errorText = fullInfo
            }
            // If there are multiple errors, then the userInfo of the error will have a value for NSDetailedErrors
            // and these errors show the actual problem.
            // Get the first one, and show it.
			if let errorDetail = userInfo[NSDetailedErrorsKey] as? [NSError] {
				if !errorDetail.isEmpty, let fullInfo = errorDetail[0].userInfo?[NSHelpAnchorErrorKey] as? String {
					errorText = fullInfo
					if errorDetail.count > 1 {
						errorText += "\nand \(errorDetail.count) more..."
					}
				}
                // Log them all
                for e in errorDetail {
                    NSLog("Core Data error \(e) userInfo \(e.userInfo)")
                }
            }
        }
		let alertController = UIAlertController(title: title, message: errorText, preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "Close",style: .Default) { (action) in
			self.dismissViewControllerAnimated(true, completion: nil)
		})
		presentViewController(alertController, animated: true, completion: nil)
   }

	/// Creates a new CharSheet entity in Core Data's managed object context and returns it.
	private func newCharacter() -> Result<CharSheet>
	{
		let context  = fetchedResultsController.managedObjectContext
		if let
			entCharacter = fetchedResultsController.fetchRequest.entity,
			entName      = entCharacter.name,
			newCharacter = NSEntityDescription.insertNewObjectForEntityForName(
				entName, inManagedObjectContext:context) as? CharSheet
		{
			newCharacter.name = "New Character"
			return success(newCharacter)
		}
		return failure(XMLSupport.XMLError("Error creating character sheet from Core Data"))
	}

    @IBAction func insertNewCharSheet(sender: AnyObject?)
	{
        newCharacter()
		// Save the character immediately.
        NSNotificationCenter.defaultCenter().postNotificationName("SaveChanges", object: nil)
    }
    
    private func deleteCharSheet(charSheet: CharSheet)
	{
        fetchedResultsController.managedObjectContext.deleteObject(charSheet)
        // Blank the detail view if we were looking at this sheet when it was deleted.
        if let dcs = detailViewController.charSheet where dcs == charSheet {
            detailViewController.charSheet = nil
        }
    }
}


// MARK: - Table View Data Source

extension MasterViewController: UITableViewDataSource
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView,  numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections {
            return sectionInfo[section].numberOfObjects
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell
	{
		let CELL_ID = "MasterViewController_Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) as? UITableViewCell
			?? UITableViewCell(style:.Subtitle, reuseIdentifier:CELL_ID)
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
}

// MARK: - Table View Delegate

extension MasterViewController: UITableViewDelegate
{
    override func tableView(  tableView: UITableView,
		canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
	{
        return true    // All the rows are editable
    }
    
    override func tableView(  tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        if editingStyle == .Delete, let sheet = fetchedResultsController.objectAtIndexPath(indexPath) as? CharSheet {
			deleteCharSheet(sheet)
			NSNotificationCenter.defaultCenter().postNotificationName("SaveChanges", object: nil)
        }
    }
    
    override func tableView(  tableView: UITableView,
		canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
	{
        return false    // The table view should not be re-orderable.
    }

    override func tableView(    tableView: UITableView,
		didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if let sheet = fetchedResultsController.objectAtIndexPath(indexPath) as? CharSheet {
			detailViewController.charSheet = sheet

			// Store the last selection so I can automatically restore it when the app starts up.
			NSUserDefaults.standardUserDefaults().setValue(sheet.name ?? "", forKey: "LastSelectedCharacter")
		}
    }
}


    //MARK: - Fetched results controller
extension MasterViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(controller: NSFetchedResultsController)
	{
        tableView.beginUpdates()
    }
    
    func controller(      controller: NSFetchedResultsController,
		didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
		atIndex         sectionIndex: Int,
		forChangeType     changeType: NSFetchedResultsChangeType)
	{
        switch(changeType) {
        case .Insert:
            tableView.insertSections(NSIndexSet(index:sectionIndex), withRowAnimation:.Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index:sectionIndex), withRowAnimation:.Fade)
        default:
            break
        }
    }
    
	func controller(  controller: NSFetchedResultsController,
		didChangeObject anObject: AnyObject,
		atIndexPath    indexPath: NSIndexPath?,
		forChangeType changeType: NSFetchedResultsChangeType,
		newIndexPath            : NSIndexPath?)
	{
		switch(changeType) {
		case .Insert:
			if let newIP = newIndexPath {
				tableView.insertRowsAtIndexPaths([newIP], withRowAnimation: UITableViewRowAnimation.Fade)
			}
		case .Delete:
			if let ip = indexPath {
				tableView.deleteRowsAtIndexPaths([ip], withRowAnimation: UITableViewRowAnimation.Fade)
			}
		case .Update:
			if let ip = indexPath, cell = tableView.cellForRowAtIndexPath(ip) {
				configureCell(cell, atIndexPath:ip)

				// Store the new name so I can automatically restore it when the app starts up.
				// This assumes you only change the name of the character you're currently working on.
				if let sheet = fetchedResultsController.objectAtIndexPath(ip) as? CharSheet {
					NSUserDefaults.standardUserDefaults().setValue(sheet.name ?? "", forKey: "LastSelectedCharacter")
				}
			}
		case .Move:
			if let ip = indexPath, newIP = newIndexPath {
				tableView.deleteRowsAtIndexPaths([ip],   withRowAnimation: UITableViewRowAnimation.Fade)
				tableView.insertRowsAtIndexPaths([newIP],withRowAnimation: UITableViewRowAnimation.Fade)
			}
		}
	}


	func controllerDidChangeContent(controller: NSFetchedResultsController)
	{
		tableView.endUpdates()
	}



	private func configureCell(cell: UITableViewCell, atIndexPath indexPath:NSIndexPath)
	{
		if let sheet = fetchedResultsController.objectAtIndexPath(indexPath) as? CharSheet {
			if let name = sheet.name, l = cell.textLabel {
				l.text = name
			}
			if let label = cell.detailTextLabel, game = sheet.game {
				label.text = game
			}
		}
	}

}
