//
//  PWMasterViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 23/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

import UIKit
import CoreData



class MasterViewController : UITableViewController, UITableViewDataSource, UITableViewDelegate, UIApplicationDelegate, NSFetchedResultsControllerDelegate {

    var detailViewController: CharSheetUseViewController!
    var managedObjectContext: NSManagedObjectContext!
    
    // Call this to import a character sheet.
    // URL will be a filename, load this and decide whether it is a new character or replaces an existing one.
    func importURL(url: NSURL) -> Bool {
        
        // Data will be a character sheet in XML format.  Import it and create a character for it.
        if !url.fileURL {
            NSLog("Error: URL: \(url) is not a file URL and isn't supported.")
            return false
        }
        var error: NSError?
        var xmlData = NSData(contentsOfURL:url)
        var document = DDXMLDocument(data:xmlData, options:0, error:&error)
        if document == nil {
            showAlertWithError(error, title: "Error importing character")
            return false
        }
        
        error = nil
        for sheetNode in document.rootElement.children as [DDXMLElement] {
            if sheetNode.name == "charSheet" {
                if var newSheet = newCharacter(fetchedResultsController) {
                    if !newSheet.updateFromXML(sheetNode, error: &error) {
                        showAlertWithError(error, title: "Error importing character")
                        deleteCharSheet(newSheet)    // Remove the half-complete sheet from the data store.
                    }
                    newSheet.renameIfNecessary()
                } else {
                    XMLSupport.setError(&error, text: "CoreData failed to create a new CharSheet object.")
                    showAlertWithError(error, title: "Error importing character")
                }
            }
            else {
                XMLSupport.setError(&error, text: "Import document: Unexpected XML node \(sheetNode.name), should be charSheet")
                showAlertWithError(error, title: "Error importing character")
                return false
            }
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = false
        navigationItem.leftBarButtonItem = editButtonItem()
        
        detailViewController = splitViewController?.viewControllers.last?.topViewController as CharSheetUseViewController
        detailViewController.managedObjectContext = managedObjectContext
    }
 
    // Depracated in iOS8. Default should support all orientations.
    //    override func shouldAutorotateToInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> Bool {
    //        return true
    //    }
    
    func showAlertWithError(error: NSError?, title: String) {
        
        // Show an error alert for a given string.
        func showAlertForString(text: String) {
            let alertController = UIAlertController(title: title, message:text, preferredStyle: .Alert)
            let closeAction: UIAlertAction = UIAlertAction(title: "Close", style: .Default, handler: { (action: UIAlertAction?) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            alertController.addAction(closeAction)
            presentViewController(alertController, animated: true, completion: nil)
        }
        
        // If no error, just show the text "Unknown error" and stop.
        if error == nil {
            showAlertForString("Unknown error")
            return
        }
        
        var errorText = "Unknown error"
        if let userInfo = error!.userInfo {
            
            if let fullInfo = userInfo[NSHelpAnchorErrorKey] as? String {
                errorText = fullInfo
            }
            
            // If there are multiple errors, then the userInfo of the error will have a value for NSDetailedErrors
            // and these errors show the actual problem.
            // Get the first one, and show it.
            if let errorDetail = userInfo[NSDetailedErrorsKey] as? [NSError] {
                if !errorDetail.isEmpty {
                    if let fullInfo = errorDetail[0].userInfo?[NSHelpAnchorErrorKey] as? String {
                        errorText = fullInfo
                        if errorDetail.count > 1 {
                            errorText += "\nand \(errorDetail.count) more..."
                        }
                    }
                }
                
                // Log them all
                for e in errorDetail {
                    NSLog("Core Data error \(e) userInfo \(e.userInfo)")
                }
            }
        }
        
        showAlertForString(errorText)
        
    }


    // Saves the data and handles any errors that occurred.
    func saveData() {
        let c = fetchedResultsController.managedObjectContext
        if c.hasChanges {
            var error: NSError?
            if !c.save(&error) {
                showAlertWithError(error!, title: "Error saving character");
                NSLog("Unresolved error \(error!), \(error!.userInfo)")
            }
        }
    }
    
    func newCharacter(fetchedResultsController: NSFetchedResultsController) -> CharSheet? {
        let context  = fetchedResultsController.managedObjectContext
        let entCharacter = fetchedResultsController.fetchRequest.entity
        var newCharacter = NSEntityDescription.insertNewObjectForEntityForName(entCharacter!.name!, inManagedObjectContext:context) as CharSheet
        newCharacter.name = "New Character"
        return newCharacter
    }
    
    @IBAction func insertNewCharSheet(sender: AnyObject?) {
        newCharacter(fetchedResultsController)
        saveData()     // Save the character immediately.
    }
    
    func deleteCharSheet(charSheet: CharSheet) {
        fetchedResultsController.managedObjectContext.deleteObject(charSheet)
        // Blank the detail view if we were looking at this sheet when it was deleted.
        if(detailViewController.charSheet == charSheet) {
            detailViewController.charSheet = nil
        }
    }
    

    //MARK: - Table View
    
    private let CELL_ID = "MasterViewController_Cell"
    
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) as? UITableViewCell ?? UITableViewCell(style:.Subtitle, reuseIdentifier:CELL_ID)
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true    // All the rows are editable
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if (editingStyle == .Delete) {
            deleteCharSheet(fetchedResultsController.objectAtIndexPath(indexPath) as CharSheet)
            saveData()
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return false    // The table view should not be re-orderable.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        var charSheet = fetchedResultsController.objectAtIndexPath(indexPath) as CharSheet
        detailViewController.charSheet = charSheet
    }
    
    //MARK: - Fetched results controller

    private var _fetchedResultController: NSFetchedResultsController? = nil
    // Generate the fetched results controller for this request only if it is needed, i.e. as a lazy variable.
    var fetchedResultsController: NSFetchedResultsController {
        
        if _fetchedResultController == nil {
            
            var fetchRequest = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entityForName("CharSheet", inManagedObjectContext:self.managedObjectContext)
            fetchRequest.fetchBatchSize = 20    // Set the batch size to a suitable number.
            fetchRequest.sortDescriptors = [NSSortDescriptor(key:"name", ascending:false)]
            
            // nil for section name key path means "no sections".
            var aFetchedResultsController = NSFetchedResultsController(fetchRequest:fetchRequest, managedObjectContext:self.managedObjectContext, sectionNameKeyPath:nil, cacheName:"Characters")
            aFetchedResultsController.delegate = self
            
            var error = NSErrorPointer()
            if !aFetchedResultsController.performFetch(error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                if let err = error.memory {
                    NSLog("MasterViewController: Error performing fetch: %@, %@", err, err.userInfo ?? "[]");
                } else {
                    NSLog("MasterViewController: Unknown error performing fetch.")
                }
                abort();
            }
            
            _fetchedResultController = aFetchedResultsController
        }
        return _fetchedResultController!
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex:Int, forChangeType type:NSFetchedResultsChangeType) {
        switch(type) {
        case .Insert:
            tableView.insertSections(NSIndexSet(index:sectionIndex), withRowAnimation:.Fade)
            
        case .Delete:
            tableView.deleteSections(NSIndexSet(index:sectionIndex), withRowAnimation:.Fade)
            
        default:
            break // Ignore all the other values.
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath) {
        
        switch(type) {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                configureCell(cell, atIndexPath:indexPath)
            }
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath],   withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath],withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    //
    //    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    //        // In the simplest, most efficient, case, reload the table view.
    //        tableView.reloadData()
    //    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath:NSIndexPath) {
        let sheet = fetchedResultsController.objectAtIndexPath(indexPath) as CharSheet
        if let name = sheet.name {
            cell.textLabel.text = name
        }
        if let label = cell.detailTextLabel {
            if let game = sheet.game {
                label.text = game
            }
        }
    }
    
}
