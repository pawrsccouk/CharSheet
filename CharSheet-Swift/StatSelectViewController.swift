//
//  PWStatSelectViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 26/01/2014.
//
//

import UIKit

private let noStatText = "None"

/// This controller handles a view with the names of the stats in a table.
/// The user can select one or more stats.
/// 
/// When the user changes the selection, a callback is triggered allowing the caller to update the model.

class StatSelectViewController : UITableViewController
{
    var selectedStat = noStatText
    
    typealias SelectionChangedCallback = (newStat: String?, oldStat: String) -> Void
    var selectionChangedCallback: SelectionChangedCallback?
    
}

// MARK: - Table view Data source

extension StatSelectViewController
{
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->UITableViewCell {
        // Mark the selected stat with a check.
        let cell = super.tableView(tableView, cellForRowAtIndexPath:indexPath)
        if let l = cell.textLabel {
            cell.accessoryType = l.text == self.selectedStat ? .Checkmark : .None
        }
        return cell
    }
}
    
// MARK: - Table view Delegate

extension StatSelectViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let oldStat = selectedStat
        if let selectedCell = tableView.cellForRowAtIndexPath(indexPath) {
            
            selectedStat = selectedCell.textLabel?.text ?? noStatText
            tableView.reloadData()
            
            // Tell the parent that something changed.  Return nil instead of "None" for ease of detection.
            if let callback = self.selectionChangedCallback {
                let newStat: String? = (selectedStat == noStatText) ? nil : selectedStat
                callback(newStat: newStat, oldStat: oldStat)
            }
        }
    }
    
}
