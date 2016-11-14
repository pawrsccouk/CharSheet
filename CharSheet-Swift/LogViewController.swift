//
//  PWLogViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 04/01/2013.
//
//

import UIKit

/// This manages a view which contains a table showing all the entries in the log for the given character.
/// 
/// The user can then click on a row in that table and launch a **LogEntryViewController** to see that row in detail.
///
/// Logs are not user-editable so this view controller is read-only.

class LogViewController: CharSheetViewController
{
    override var charSheet: CharSheet! {
        didSet {
            sortedLogs = charSheet.sortedLogs
        }
    }

	// MARK: Interface Builder

	@IBOutlet weak var tableView: UITableView!

    @IBAction func done(_ sender: AnyObject)
	{
        presentingViewController?.dismiss(animated: true, completion:nil)
    }

	// MARK: Overrides

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		// Scroll to show the last row if there is one.
		if sortedLogs.count > 0 {
			let lastRowPath = IndexPath(row: sortedLogs.count - 1, section: 0)
			tableView.scrollToRow(at: lastRowPath, at: .bottom, animated: false)
		}
	}

	// MARK: Private

	/// Sorted array of logs to display. Taken from the char sheet.
    fileprivate var sortedLogs: [LogEntry] = []


	/// Loads a Log Entry View Controller from the storyboard, populates it and presents it as a popover.
	///
	/// - parameter tableView: The table view to overlay with the popover. 
	/// - parameter indexPath: Index to the table-view row which triggered the popup.
	///                        The popover will display the LogEntry associated with this row.
	///
	/// We use a custom popover instead of a Storyboard Segue as the segue points the popover
	/// at the bottom of the table view and not the row that was selected.
	///
	/// - note: This assumes the LogEntryViewController object is in the same storyboard as this controller is.

	fileprivate func openCustomPopoverForTableView(_ tableView: UITableView, cellIndexPath indexPath: IndexPath)
	{
		let logEntryController = storyboard!.instantiateViewController(withIdentifier: "Log Entry View Controller")
			as! LogEntryViewController
		logEntryController.logEntry = sortedLogs[indexPath.row]

		//Get the cell that presents the popover and use the cell frame to calculate the popover's origin.
		if let cell = tableView.cellForRow(at: indexPath) {

			// Presenting the popover creates a popoverPresentationController which we can then configure.
			logEntryController.modalPresentationStyle = .popover
			present(logEntryController, animated: true, completion: nil)
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
    lazy fileprivate var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    fileprivate let cellIdentifier = "LogViewCell"
}

// MARK: - Table View Data Source
extension LogViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }
    
    func tableView(         _ tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return sortedLogs.count
    }
    
    func tableView(           _ tableView: UITableView,
		cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell()
		let entry = sortedLogs[indexPath.row] as LogEntry
		cell.textLabel?.text = dateFormatter.string(from: entry.dateTime as Date)
		cell.detailTextLabel?.text = entry.summary
		return cell
	}
}

// MARK: - Table View Delegate
extension LogViewController: UITableViewDelegate
{
	func tableView(             _ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath)
	{
		openCustomPopoverForTableView(tableView, cellIndexPath:indexPath)
	}
}

