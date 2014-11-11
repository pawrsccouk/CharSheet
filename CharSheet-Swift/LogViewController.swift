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


    @IBAction func done(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }
    
//    // Trigger a popup showing the log entry LOGENTRY, appearing as though it had appeared from ORIGINATINGVIEW.
//    -(void) showLogEntry: (PWLogEntry*)logEntry originatingFrom: (UIView*)originatingView
//    {
//        if(! _logEntryController)
//            _logEntryController = [[PWLogEntryViewController alloc] init];
//        _logEntryController.logEntry = logEntry;
//    
//        if(! _logEntryPopover) {
//            _logEntryPopover = [[UIPopoverController alloc] initWithContentViewController:_logEntryController];
//            // Allow this view to be selected, so we can just update the text view inside the popover if the user clicks on a different row.
//            _logEntryPopover.passthroughViews = @[self.tableView];
//        }
//    
//        if(! _logEntryPopover.isPopoverVisible) {
//            [_logEntryPopover presentPopoverFromRect:originatingView.bounds
//                                             inView:originatingView
//                           permittedArrowDirections:UIPopoverArrowDirectionAny
//                                           animated:YES];
//        }
//    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == "LogEntryPopover" {
            // Find the selected log entry. SENDER is the object that triggered the segue (in this case, the table view cell that was clicked on).
            if let cell = sender as? UITableViewCell {
                let logEntryViewController = segue.destinationViewController as LogEntryViewController
                assert(cell.isKindOfClass(UITableViewCell), "Sender \(cell) must be a table view cell.")
                
                if let selectedRow = tableView.indexPathForCell(cell) {
                    let log = sortedLogs[selectedRow.row]
                    logEntryViewController.logEntry = log
                }
            } else {
                assert(false, "No sender provided")
            }
        }
    }
    
    // MARK: - Table view data source

    let dateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()

    let cellIdentifier = "LogViewCell"

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedLogs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        if var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell {
            let entry = sortedLogs[indexPath.row] as LogEntry
            cell.textLabel.text = dateFormatter.stringFromDate(entry.dateTime)
            cell.detailTextLabel?.text = entry.summary
            return cell
        }
        assert(false, "TableViewCell not found for identifier \(cellIdentifier)")
        return UITableViewCell()
    }
    
    
    //#pragma mark - Table view delegate
    //
    //- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
    //{
    //    [self showLogEntry:_sortedLogs[indexPath.row]
    //       originatingFrom:[self.tableView cellForRowAtIndexPath:indexPath]];
    //}




}

