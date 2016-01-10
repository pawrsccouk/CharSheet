//
//  PWLogViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 04/01/2013.
//
//

import UIKit

class LogViewController: CharSheetViewController
{
    override var charSheet: CharSheet! {
        didSet {
            sortedLogs = charSheet.sortedLogs
        }
    }


	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		// Scroll to show the last row if there is one.
		if sortedLogs.count > 0 {
			let lastRowPath = NSIndexPath(forRow: sortedLogs.count - 1, inSection: 0)
			tableView.scrollToRowAtIndexPath(lastRowPath, atScrollPosition: .Bottom, animated: false)
		}
	}


    // Sorted array of logs to display. Taken from the char sheet.
    private var sortedLogs: [LogEntry] = []

	@IBOutlet weak var tableView: UITableView!

    @IBAction func done(sender: AnyObject)
	{
        presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }

	/// Loads a Log Entry View Controller from the storyboard, populates it and presents it as a popover.
	///
	/// - parameter tableView: The table view to overlay with the popover. 
	/// - parameter indexPath: Index to the table-view row which triggered the popup.
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

		//Get the cell that presents the popover and use the cell frame to calculate the popover's origin.
		if let cell = tableView.cellForRowAtIndexPath(indexPath) {

			// Presenting the popover creates a popoverPresentationController which we can then configure.
			logEntryController.modalPresentationStyle = .Popover
			presentViewController(logEntryController, animated: true, completion: nil)
			guard let popoverPresentationController = logEntryController.popoverPresentationController else {
				fatalError("No popover presentation controller.")
			}
			popoverPresentationController.sourceView = tableView
			popoverPresentationController.sourceRect = cell.frame
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
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
    
    func tableView(         tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return sortedLogs.count
    }
    
    func tableView(           tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ?? UITableViewCell()
		let entry = sortedLogs[indexPath.row] as LogEntry
		cell.textLabel?.text = dateFormatter.stringFromDate(entry.dateTime)
		cell.detailTextLabel?.text = entry.summary
		return cell
	}
}

// MARK: - Table View Delegate
extension LogViewController: UITableViewDelegate
{
	func tableView(             tableView: UITableView,
		didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		openCustomPopoverForTableView(tableView, cellIndexPath:indexPath)
	}
}

