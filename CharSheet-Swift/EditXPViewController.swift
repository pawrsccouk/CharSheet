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
    @IBAction func done(_ sender: AnyObject?)
	{
		// Ensure the values saved to the DB have the same order as in the set here.
		var i: Int16 = 0
		for xpGain in charSheet.xp.array.map({ $0 as! XPGain }) {
			xpGain.order = i
			i += 1
		}
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
		presentingViewController?.dismiss(animated: true, completion:nil)
    }
    
    // MARK: Overrides

	override func setEditing(_ editing: Bool, animated: Bool)
	{
		super.setEditing(editing, animated: animated)
		tableView.setEditing(editing, animated: animated)
	}

    override func viewDidLoad()
	{
		super.viewDidLoad()
		// Add the table view's Edit button to the left hand side.
		var array = navigationItem.leftBarButtonItems ?? [UIBarButtonItem]()
		array.insert(editButtonItem, at: 0)
		navigationItem.leftBarButtonItems = array
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		// Reorder the set of XPGain objects to match the order stored in the DB.
		charSheet.xp.sort (comparator: { (xp1, xp2) -> ComparisonResult in
			if (xp1 as AnyObject).order > (xp2 as AnyObject).order { return .orderedDescending }
			if (xp2 as AnyObject).order > (xp1 as AnyObject).order { return .orderedAscending  }
			return .orderedSame
		})
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
        let editXPGainViewController = segue.destination as! EditXPGainViewController
        editXPGainViewController.completionBlock = { self.tableView.reloadData() }
        
        switch segue.identifier! {
		case "AddNewXPGainView":
            let xpGain = charSheet.appendXPGain()
            editXPGainViewController.xpGain = xpGain

        case "EditExistingXPGainView":
            if let cell = sender as? UITableViewCell, let selectedIndexPath = tableView.indexPath(for: cell) {
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
    func tableView(           _ tableView: UITableView,
		cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID) ?? UITableViewCell()
        if let xpGain = charSheet.xp[indexPath.item] as? XPGain {
            cell.textLabel?.text = xpGain.reason
            cell.detailTextLabel?.text = xpGain.amount.description
        } else {
            assert(false, "No XP gain object at index \(indexPath)")
        }
        return cell
    }
    
    func tableView(         _ tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
		for xpGain in charSheet.xp.array.map({ $0 as! XPGain }) {
			assert(xpGain.reason != nil, "Ensure no faulting.")
		}
        return charSheet.xp.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }
}
    // MARK: - Table View Delegate

extension EditXPViewController: UITableViewDelegate
{
    func tableView(       _ tableView: UITableView,
		willDisplay        cell: UITableViewCell,
		forRowAt indexPath: IndexPath)
	{
		cell.textLabel?.font = cell.detailTextLabel?.font
    }

    func tableView(           _ tableView: UITableView,
		commit editingStyle: UITableViewCellEditingStyle,
		forRowAt     indexPath: IndexPath)
	{
        if editingStyle == .delete {
            charSheet.removeXPGainAtIndex(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(              _ tableView: UITableView,
		moveRowAt sourceIndexPath: IndexPath,
		to   destinationIndexPath: IndexPath)
	{
        // Table view has already moved the row, so we just need to update the model.
        charSheet.xp.moveObjects(at: IndexSet(integer: sourceIndexPath.row), to: destinationIndexPath.row)
    }
}





