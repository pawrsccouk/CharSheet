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
    
    typealias SelectionChangedCallback = (_ newStat: String?, _ oldStat: String) -> Void
    var selectionChangedCallback: SelectionChangedCallback?
    
}

// MARK: - Table view Data source

extension StatSelectViewController
{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->UITableViewCell {
        // Mark the selected stat with a check.
        let cell = super.tableView(tableView, cellForRowAt:indexPath)
        if let l = cell.textLabel {
            cell.accessoryType = l.text == self.selectedStat ? .checkmark : .none
        }
        return cell
    }
}
    
// MARK: - Table view Delegate

extension StatSelectViewController
{
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        let oldStat = selectedStat
        if let selectedCell = tableView.cellForRow(at: indexPath) {
            
            selectedStat = selectedCell.textLabel?.text ?? noStatText
            tableView.reloadData()
            
            // Tell the parent that something changed.  Return nil instead of "None" for ease of detection.
            if let callback = self.selectionChangedCallback {
                let newStat: String? = (selectedStat == noStatText) ? nil : selectedStat
                callback(newStat, oldStat)
            }
        }
    }
    
}
