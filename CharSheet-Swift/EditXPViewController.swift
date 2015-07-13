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

class EditXPViewController : CharSheetViewController
{
    // MARK: Interface Builder

	@IBOutlet weak var tableView: UITableView!

    @IBAction func done(sender: AnyObject?)
	{
        if let callback = dismissCallback {
            callback()
        }
        if let pvc = presentingViewController {
            pvc.dismissViewControllerAnimated(true, completion:nil)
        }
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
        var array = navigationItem.leftBarButtonItems ?? [AnyObject]()
            array.insert(editButtonItem(), atIndex: 0)
        navigationItem.leftBarButtonItems = array
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
            if let cell = sender as? UITableViewCell {
                if let selectedIndexPath = tableView.indexPathForCell(cell) {
                    editXPGainViewController.xpGain = charSheet.xp[selectedIndexPath.row] as? XPGain
                }
                else {
                    assert(false, "Cell \(cell) not found in CharSheet.xp. ")
                }
            }
            else {
                assert(false, "Sender \(sender) is not a UITableViewCell, or is missing.")
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
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) as? UITableViewCell ?? UITableViewCell()
        
        if let xpGain = charSheet.xp[indexPath.item] as? XPGain {
            if let l = cell.textLabel {
                l.text = xpGain.reason
            }
            if let l = cell.detailTextLabel {
                l.text = xpGain.amount.description
            }
        } else {
            assert(false, "No XP gain object at index \(indexPath)")
        }
        
        return cell
    }
    
    func tableView(         tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
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
        if let detailTextLabel = cell.detailTextLabel, textLabel = cell.textLabel {
			textLabel.font = detailTextLabel.font
        }
    }
    
    func tableView(           tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        if editingStyle ==  .Delete {
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





