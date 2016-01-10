//
//  PWEditNotesViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//
import CoreData
import UIKit

private let CELL_ID = "XPGainCell"

/// This controller manages a table of XP Gains, allowing the user to add, remove and modify the entries in it.
///
/// This class pops up a **EditXPGainViewController** to allow the user to specify details for the rows in the table.

class EditXPViewController : CharSheetViewController
{
    // MARK: Interface Builder

	/// The table view displayed in this view.
	@IBOutlet weak var tableView: UITableView!

	/// Action to dismiss this view and update the model with the changes.
    @IBAction func done(sender: AnyObject?)
	{
		// Ensure the values saved to the DB have the same order as in the set here.
		var i: Int16 = 0
		for xpGain in charSheet.xp.array.map({ $0 as! XPGain }) {
			xpGain.order = i++
		}
		NSNotificationCenter.defaultCenter().postNotificationName("SaveChanges", object: nil)
		presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }
    
    // MARK: Overrides

	override func setEditing(editing: Bool, animated: Bool)
	{
		super.setEditing(editing, animated: animated)
		tableView.setEditing(editing, animated: animated)
	}

    override func viewDidLoad()
	{
		super.viewDidLoad()
		// Add the table view's Edit button to the left hand side.
		var array = navigationItem.leftBarButtonItems ?? [UIBarButtonItem]()
		array.insert(editButtonItem(), atIndex: 0)
		navigationItem.leftBarButtonItems = array
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		// Reorder the set of XPGain objects to match the order stored in the DB.
		charSheet.xp.sortUsingComparator { (xp1, xp2) -> NSComparisonResult in
			if xp1.order > xp2.order { return .OrderedDescending }
			if xp2.order > xp1.order { return .OrderedAscending  }
			return .OrderedSame
		}
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
        let editXPGainViewController = segue.destinationViewController as! EditXPGainViewController
        editXPGainViewController.completionBlock = { self.tableView.reloadData() }
        
        switch segue.identifier! {
		case "AddNewXPGainView":
            let xpGain = charSheet.appendXPGain()
            editXPGainViewController.xpGain = xpGain

        case "EditExistingXPGainView":
            if let cell = sender as? UITableViewCell, selectedIndexPath = tableView.indexPathForCell(cell) {
				editXPGainViewController.xpGain = charSheet.xp[selectedIndexPath.row] as? XPGain
            }
            else {
                assert(false, "Cannot get the indexPath from sender: \(sender) is it a UITableViewCell?")
            }

		default:
            assert(false, "Segue \(segue) ID \(segue.identifier) is not known in EditXPViewController \(self)")
        }
    }
}
    // MARK: - Table View Data Source

extension EditXPViewController: UITableViewDataSource
{
    func tableView(           tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) ?? UITableViewCell()
        if let xpGain = charSheet.xp[indexPath.item] as? XPGain {
            cell.textLabel?.text = xpGain.reason
            cell.detailTextLabel?.text = xpGain.amount.description
        } else {
            assert(false, "No XP gain object at index \(indexPath)")
        }
        return cell
    }
    
    func tableView(         tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
		for xpGain in charSheet.xp.array.map({ $0 as! XPGain }) {
			assert(xpGain.reason != nil, "Ensure no faulting.")
		}
        return charSheet.xp.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
}
    // MARK: - Table View Delegate

extension EditXPViewController: UITableViewDelegate
{
    func tableView(       tableView: UITableView,
		willDisplayCell        cell: UITableViewCell,
		forRowAtIndexPath indexPath: NSIndexPath)
	{
		cell.textLabel?.font = cell.detailTextLabel?.font
    }

    func tableView(           tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        if editingStyle == .Delete {
            charSheet.removeXPGainAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(              tableView: UITableView,
		moveRowAtIndexPath sourceIndexPath: NSIndexPath,
		toIndexPath   destinationIndexPath: NSIndexPath)
	{
        // Table view has already moved the row, so we just need to update the model.
        charSheet.xp.moveObjectsAtIndexes(NSIndexSet(index: sourceIndexPath.row), toIndex: destinationIndexPath.row)
    }
}





