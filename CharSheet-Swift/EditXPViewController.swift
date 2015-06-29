//
//  PWEditNotesViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//
import CoreData
import UIKit

class EditXPViewController : UITableViewController, UITableViewDataSource, UITableViewDelegate {

    var charSheet: CharSheet!
    var managedObjectContext: NSManagedObjectContext!

    // Called when the XP view controller is dismissed.
    var dismissCallback: VoidCallback?
    
    // MARK: - Interface Builder
    
    @IBAction func done(sender: AnyObject?) {
        if let callback = dismissCallback {
            callback()
        }
        if let pvc = presentingViewController {
            pvc.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    ////- (IBAction)addXPGain: (id)sender
    ////{
    ////    PWXPGain *xpGain = [self.charSheet appendXPGain];
    ////    int lastRow = self.charSheet.xp.count;
    ////    NSCAssert(lastRow > 0, @"XP object $@ not added to the XP list %@", xpGain, self.charSheet.xp);
    ////
    ////    NSIndexPath *tableEndIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
    ////    [self.tableView insertRowsAtIndexPaths:@[tableEndIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    ////
    ////    self.tableView.editing = YES;
    ////    editXPGainDetail(tableEndIndexPath, self.tableView, self.navigationController, self.charSheet);
    ////}
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the table view's Edit button to the left hand side.
        var array = navigationItem.leftBarButtonItems ?? [AnyObject]()
            array.insert(editButtonItem(), atIndex: 0)
        navigationItem.leftBarButtonItems = array
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let editXPGainViewController = segue.destinationViewController as! EditXPGainViewController
        editXPGainViewController.completionBlock = { self.tableView.reloadData() }
        
        if segue.identifier == "AddNewXPGainView" {
            let xpGain = charSheet.appendXPGain()
            editXPGainViewController.xpGain = xpGain
        }
        else if segue.identifier == "EditExistingXPGainView" {
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
        }
        else {
            assert(false, "Segue \(segue) ID \(segue.identifier) is not known in EditXPViewController \(self)")
        }
    }

    // MARK: - Table View Data Source
    
    private let CELL_ID = "XPGainCell"
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charSheet.xp.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - Table View Delegate
    
    override  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let detailTextLabel = cell.detailTextLabel {
            if let textLabel = cell.textLabel {
                textLabel.font = detailTextLabel.font
            }
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle ==  .Delete {
            charSheet.removeXPGainAtIndex(indexPath.row)
            // Update the table view to match the new model.
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // Table view has already moved the row, so we just need to update the model.
        charSheet.xp.moveObjectsAtIndexes(NSIndexSet(index: sourceIndexPath.row), toIndex: destinationIndexPath.row)
        //charSheet.moveXPGainFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }

////static void editXPGainDetail(NSIndexPath *indexPath,
////                             UITableView *tableView,
////                             UINavigationController *navigationController,
////                             PWCharSheet *charSheet)
////{
////    PWEditXPGainViewController *xpGainController = [[PWEditXPGainViewController alloc] init];
////    xpGainController.xpGain = [charSheet.xp objectAtIndex:indexPath.row];
////    xpGainController.completionBlock = ^{
////        [tableView reloadData];
////    };
////    [navigationController pushViewController:xpGainController animated:YES];
////}
////
////- (void)tableView: (UITableView *)tableView accessoryButtonTappedForRowWithIndexPath: (NSIndexPath *)indexPath
////{
////    editXPGainDetail(indexPath, tableView, self.navigationController, self.charSheet);
////}
////
////
////-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
////{
////    editXPGainDetail(indexPath, tableView, self.navigationController, self.charSheet);
////}


    
    
    
}





