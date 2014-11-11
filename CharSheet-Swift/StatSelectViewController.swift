//
//  PWStatSelectViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 26/01/2014.
//
//

import UIKit

private let noStatText = "None"

class StatSelectViewController : UITableViewController, UITableViewDataSource, UITableViewDelegate
{
    var selectedStat = noStatText
    
    typealias SelectionChangedCallback = (newStat: String?, oldStat: String) -> Void
    var selectionChangedCallback: SelectionChangedCallback?
    
    // MARK: - Table view data source
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->UITableViewCell {
        // Mark the selected stat with a check.
        var cell = super.tableView(tableView, cellForRowAtIndexPath:indexPath)
        cell.accessoryType = cell.textLabel.text == self.selectedStat ? .Checkmark : .None
        return cell
    }
    
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let oldStat = selectedStat
        if let selectedCell = tableView.cellForRowAtIndexPath(indexPath) {
            
            selectedStat = selectedCell.textLabel.text ?? noStatText
            tableView.reloadData()
            
            // Tell the parent that something changed.  Return nil instead of "None" for ease of detection.
            if let callback = self.selectionChangedCallback {
                let newStat: String? = (selectedStat == noStatText) ? nil : selectedStat
                callback(newStat: newStat, oldStat: oldStat)
            }
        }
    }
    
}
