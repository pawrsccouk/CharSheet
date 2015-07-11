//
//  PWLogViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 04/01/2013.
//
//

import UIKit

class LogViewController : UITableViewController, UITableViewDataSource {

    var charSheet: CharSheet! {
        didSet {
            sortedLogs = charSheet.sortedLogs
        }
    }
    
    // Sorted array of logs to display. Taken from the char sheet.
    private var sortedLogs: [LogEntry] = []


    @IBAction func done(sender: AnyObject)
	{
        presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }

	/// Loads a Log Entry View Controller from the storyboard, populates it and presents it as a popover.
	///
	/// :param: tableView The table view to overlay with the popover. 
	/// :param: indexPath Index to the table-view row which triggered the popup.
	///                   The popover will display the LogEntry associated with this row.
	/// We use a custom popover instead of a Storyboard Segue as the segue points the popover
	/// at the bottom of the table view and not the row that was selected.
	///
	/// **NB** This assumes the LogEntryViewController object is in the same storyboard as this controller is.

	func openCustomPopoverForTableView(tableView: UITableView, cellIndexPath indexPath: NSIndexPath)
	{
		let logEntryController = storyboard!.instantiateViewControllerWithIdentifier("Log Entry View Controller")
			as! LogEntryViewController
		logEntryController.logEntry = sortedLogs[indexPath.row]

		let popOver = UIPopoverController(contentViewController:logEntryController)

		//Get the cell that presents the popover and use the cell frame to calculate the popover's origin.
		if let cell = tableView.cellForRowAtIndexPath(indexPath) {
			let displayFrom = CGRectMake(
				cell.frame.origin.x + (cell.frame.size.width / 3),
				cell.center.y + tableView.frame.origin.y - tableView.contentOffset.y - cell.frame.size.height,
				1, 1)
			popOver.presentPopoverFromRect(displayFrom, inView:view, permittedArrowDirections:.Left, animated:true)
		} else {
			assert(false, "Table view \(tableView) failed to get a cell for index path \(indexPath)")
		}
	}

	/// Used internally to format dates for display in the log summary table cells.
    lazy private var dateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()

    private let cellIdentifier = "LogViewCell"
}

// MARK: - Table View Data Source
extension LogViewController: UITableViewDataSource
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
    
    override func tableView(tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return sortedLogs.count
    }
    
    override func tableView(  tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
        
        if var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell {
            let entry = sortedLogs[indexPath.row] as LogEntry
            if let l = cell.textLabel {
                l.text = dateFormatter.stringFromDate(entry.dateTime)
            }
            if let l = cell.detailTextLabel {
                l.text = entry.summary
            }
            return cell
        }
        assert(false, "TableViewCell not found for identifier \(cellIdentifier)")
        return UITableViewCell()
    }
}

// MARK: - Table View Delegate
extension LogViewController: UITableViewDelegate
{
	override func tableView(    tableView: UITableView,
		didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		openCustomPopoverForTableView(tableView, cellIndexPath:indexPath)
	}
}

