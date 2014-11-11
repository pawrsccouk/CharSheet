//
//  PWDetailViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 23/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

import CoreData
import UIKit
import MessageUI

class CharSheetUseViewController : UIViewController, UICollectionViewDataSource, MFMailComposeViewControllerDelegate, UISplitViewControllerDelegate {

    // MARK: - Interface Builder
    @IBOutlet weak var strengthBtn    : UseStatLabel!
    @IBOutlet weak var intelligenceBtn: UseStatLabel!
    @IBOutlet weak var dexterityBtn   : UseStatLabel!
    @IBOutlet weak var charismaBtn    : UseStatLabel!
    @IBOutlet weak var constitutionBtn: UseStatLabel!
    @IBOutlet weak var perceptionBtn  : UseStatLabel!
    @IBOutlet weak var speedBtn       : UseStatLabel!
    @IBOutlet weak var luckBtn        : UseStatLabel!
    @IBOutlet weak var skillsCollectionView: UICollectionView!
    @IBOutlet weak var playerLabel    : UILabel!
    @IBOutlet weak var gameLabel      : UILabel!
    @IBOutlet weak var levelLabel     : UILabel!
    @IBOutlet weak var experienceLabel: UILabel!
    @IBOutlet weak var meleeAddsLabel : UILabel!
    @IBOutlet weak var rangedAddsLabel: UILabel!

    
    
    @IBAction func backgroundSelected(sender: AnyObject?) {
        deselectEveryStat()
        deselectEverySkill()
    }
    
    
    @IBAction func editCharSheet(sender: AnyObject?) {
        resetUI()
        
        // Load the edit view, edit view controller and navigation item all from the "Edit" storyboard file.
        let editStoryboard = StoryboardManager.sharedInstance().editStoryboard
        let editNavigationController = editStoryboard.instantiateInitialViewController() as UINavigationController
        let charSheetEditViewController = editNavigationController.viewControllers[0] as CharSheetEditViewController
        
        charSheetEditViewController.managedObjectContext   = self.managedObjectContext
        charSheetEditViewController.charSheet = self.charSheet
        charSheetEditViewController.dismissCallback = {     // Save data and refresh the view when the modal popup completes.
            self.configureView()
            if let callback = self.saveAllData {
                callback() }
        }
        if let navc = navigationController {
            navc.presentViewController(editNavigationController, animated:true, completion:nil)
        }
    }
    
    @IBAction func exportEmail(sender: AnyObject?) {
        // Abort if there are no email accounts on this device.
        if !MFMailComposeViewController.canSendMail() {
            let alertView = UIAlertController(title: "Export via email", message:"This device is not set up to send email." , preferredStyle: .Alert)
            alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alertView, animated: true, completion: nil)
            return
        }
        
        // Get the character sheet as XML data in an NSData object.
        var error: NSError?
        if let xmlData = charSheet.exportToXML(&error) {
            if charSheet.name == nil { charSheet.name = "Unknown" }
            // Present a mail compose view with the data as an attachment.
            var mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setSubject("\(charSheet.name) exported from CharSheet.")
            mailVC.setMessageBody(String(format: bodyHTMLFormat, charSheet.name!, charSheet.name!, NSDate()), isHTML:true)
            mailVC.addAttachmentData(xmlData, mimeType: "application/charsheet+xml", fileName: "\(charSheet.name!).charSheet")
            presentViewController(mailVC,  animated:true, completion:nil)
        } else {
            let localisedDescription = error?.localizedDescription ?? "Unknown error"
            let alertView = UIAlertController(title: "Error converting \(charSheet.name) to XML", message:localisedDescription, preferredStyle: .Alert)
            alertView.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
            presentViewController(alertView, animated: true, completion: nil)
            return
        }
    }
    
    
    // MARK: - Properties
    
    // Character sheet.  Note table view callbacks will occur before this is set, so will have to test for it.
    // Otherwise it must be set before any methods are called.
    var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                configureView()
                navigationItem.title = charSheet?.name ?? "No name"
                if let mpc = masterPopoverController {
                    mpc.dismissPopoverAnimated(true)
                }
            }
        }
    }
    
    var masterPopoverController: UIPopoverController?
    var managedObjectContext: NSManagedObjectContext!
    
    // The currently selected stat label.
    private weak var selectedStatLabel: UseStatLabel?
    
    // Toolbar item for the Export button.
    private var exportItem: UIBarButtonItem?
    
    // Action sheet for where to export to.
    private var exportLocationSheet: UIActionSheet?
    
    // Call to update all data in the app (e.g. save all dirty records, add new ones and delete dead ones).
    var saveAllData: VoidCallback?

    // MARK: Private Methods
    
    
    
    
    // Reset any ongoing interface windows (e.g. close any non-modal dialogs etc).
    // Used to clean up after one command when the user has started another one.
    private func resetUI() {
        // If the export location dialog is visible then cancel it.
        if let sheet = exportLocationSheet {
            sheet.dismissWithClickedButtonIndex(sheet.cancelButtonIndex, animated:true)
            exportLocationSheet = nil
        }
    }
    
    private let bodyHTMLFormat =
    "<html>\n" +
        "<head/>     \n" +
        "<body>      \n" +
        "<H1>%@</H1> \n" +
        "<p>Here is %@ exported from CharSheet.<br/>\n" +
        "It was exported on %@                      \n" +
        "It has been formatted as an XML file. You can make changes to it and then mail it back to the iPad to import it into CharSheet again.\n" +
        "</p>        \n" +
        "</body>     \n" +
    "</html>"



    private func skillForIndexPath(indexPath: NSIndexPath) -> Skill {
        assert(indexPath.length == 2 && indexPath.indexAtPosition(0) == 0, "Invalid index path \(indexPath)")
        return charSheet.skills.objectAtIndex(indexPath.indexAtPosition(1)) as Skill
    }
    
//-(NSIndexPath*)indexPathForSkill:(PWSkill*)skill
//{
//    NSInteger pos = [self.charSheet.skills indexOfObject:skill];
//    assert(pos != NSNotFound);
//    const NSUInteger inds[2] = { 0, pos };
//    return [NSIndexPath indexPathWithIndexes:inds length:2];
//}
    
    
    
    private func prepareDieRollView(dieRollViewController: DieRollViewController) {
        
        dieRollViewController.charSheet = self.charSheet
        dieRollViewController.addTickToSkillCallback = { $0.addTick() }  // Called by the die roll controller if it decides to add a tick to a skill.
        
        dieRollViewController.dismissCallback = {    // Save the die roll result when the dialog completes.
            if let callback = self.saveAllData {
                callback()
            }
        }
        
        var selectedIndexPaths = skillsCollectionView.indexPathsForSelectedItems() as [NSIndexPath]
        var selectedSkills = selectedIndexPaths.map{ self.skillForIndexPath($0) }
        dieRollViewController.setInitialStat(selectedStatLabel?.stat, skills:selectedSkills)
    }
    
    
    
    private func prepareNotesView(editNotesViewController :EditNotesViewController) {
        editNotesViewController.managedObjectContext = managedObjectContext
        editNotesViewController.charSheet = charSheet
        editNotesViewController.dismissCallback = {     // Save and refresh the view when the modal popup completes.
            self.configureView()
            if let callback = self.saveAllData {
                callback()
            }
        }
        
    }
    
    
    
    private func prepareXPView(editXPViewController: EditXPViewController) {
        editXPViewController.managedObjectContext   = managedObjectContext
        editXPViewController.charSheet = charSheet
        editXPViewController.dismissCallback = {     // Save and refresh the view when the modal popup completes.
            self.configureView()
            if let callback = self.saveAllData {
                callback()
            }
        }
    }
    
    
    private func prepareLogView(logViewController: LogViewController) {
        logViewController.charSheet = self.charSheet
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var navigationController = segue.destinationViewController as UINavigationController
        
        if      segue.identifier == "DieRoll"       { prepareDieRollView(navigationController.childViewControllers[0] as DieRollViewController  ) }
        else if segue.identifier == "ShowLogView"   { prepareLogView(    navigationController.childViewControllers[0] as LogViewController      ) }
        else if segue.identifier == "ShowNotesView" { prepareNotesView(  navigationController.childViewControllers[0] as EditNotesViewController) }
        else if segue.identifier == "ShowXPView"    { prepareXPView(     navigationController.childViewControllers[0] as EditXPViewController   ) }
        else {
            assert(false, "Unknown segue \(segue) ID \(segue.identifier) passed to PWCharSheetUseViewController \(self)")
        }
    }
    
    
    //MARK: - Managing the detail item
    
    private func configureView() {
        // Update the user interface for the detail item.
        
        if let sheet = charSheet {
            navigationItem.title = sheet.name
            // Stat buttons
            strengthBtn.stat     = sheet.strength
            dexterityBtn.stat    = sheet.dexterity
            constitutionBtn.stat = sheet.constitution
            speedBtn.stat        = sheet.speed
            intelligenceBtn.stat = sheet.intelligence
            perceptionBtn.stat   = sheet.perception
            luckBtn.stat         = sheet.luck
            charismaBtn.stat     = sheet.charisma
            
            // Misc text labels.
            playerLabel.text = sheet.player
            gameLabel.text   = sheet.game
            levelLabel.text  = sheet.level.description
            experienceLabel.text = sheet.experience.description
            meleeAddsLabel.text  = sheet.meleeAdds.description
            rangedAddsLabel.text = sheet.rangedAdds.description
        }
        
        // Trigger a call to statsSelected: when the user touches one of these labels.
        for lbl in allStatLabels {
            lbl.addTarget(self, action:"statSelected:", forControlEvents: .TouchUpInside)
        }
        
        skillsCollectionView.allowsSelection = true
        skillsCollectionView.allowsMultipleSelection = true
        skillsCollectionView.reloadData()
    }
    
    
    
    
    private let COLLECTION_CELL_ID = "SkillsCollection_Cell"
    
    override func viewDidLoad() {
        // Set up the collection view cell.
        skillsCollectionView.registerClass(UseSkillCell.self, forCellWithReuseIdentifier:COLLECTION_CELL_ID)
        
        // Initial view configuration.  Will be overridden when setCharSheet is called.
        configureView()
    }




    private var allStatLabels: [UseStatLabel] {
        return [strengthBtn, constitutionBtn, dexterityBtn, speedBtn, perceptionBtn, intelligenceBtn, charismaBtn , luckBtn]
    }
    
    
    
    
    private func deselectEveryStat() {
        selectedStatLabel = nil
        for statLabel in allStatLabels {
            if statLabel.selected {
                statLabel.selected = false
                statLabel.setNeedsDisplay()
            }
        }    
    }
    
    private func deselectEverySkill() {
        for selectionPath in skillsCollectionView.indexPathsForSelectedItems() as [NSIndexPath] {
            skillsCollectionView.deselectItemAtIndexPath(selectionPath, animated:true)
        }
    }
    
    // Cannot be private as private methods can not be accessed by Objective-C selectors.
    func statSelected(sender: AnyObject?) {
        if let statLabel = sender as? UseStatLabel {
            assert(statLabel.isKindOfClass(UseStatLabel), "Sender [\(statLabel)] is not of class UseStatLabel")
            
            let selectSender = (selectedStatLabel != statLabel)
            deselectEveryStat()
            if selectSender {
                statLabel.selected = true
                selectedStatLabel = statLabel
                statLabel.setNeedsDisplay()
            }
        }
        else { assert(false, "Sender is nil") }
    }

    
    //MARK: - Split view delegate

    func splitViewController(splitController: UISplitViewController, willHideViewController viewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController popoverController:UIPopoverController) {
        barButtonItem.title = NSLocalizedString("Characters", comment: "Characters")
        navigationItem.setLeftBarButtonItem(barButtonItem, animated:true)
        masterPopoverController = popoverController
    }
    
    func splitViewController(splitController: UISplitViewController, willShowViewController viewController: UIViewController, invalidatingBarButtonItem barButtonItem: UIBarButtonItem) {
        // Called when the view is shown again in the split view, invalidating the button and popover controller.
        navigationItem.setLeftBarButtonItem(nil, animated:true)
        masterPopoverController = nil
    }


    // MARK: - Collection View Data Source
    
    func collectionView(cv: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = skillsCollectionView.dequeueReusableCellWithReuseIdentifier(COLLECTION_CELL_ID, forIndexPath:indexPath) as UseSkillCell
        cell.skill = skillForIndexPath(indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return charSheet?.skills.count ?? 0
    }
    
    
    
    //MARK: - Mail Composer delegate

    private func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSErrorPointer) {
        NSLog("Mail composer finished. Result: %d, error: %@", result.value, error.memory ?? "nil")
        
        controller.dismissViewControllerAnimated(true, completion:nil)
        
        // If something went wrong, produce an alert to say what.
        if (result.value == MFMailComposeResultFailed.value) || (error.memory != nil) {
            let localisedDescription = error.memory?.localizedDescription ?? "No error given"
            let alertView = UIAlertController(title:"Error sending email", message: localisedDescription, preferredStyle: .Alert)
            alertView.addAction(UIAlertAction(title: "Close", style: .Default, handler:nil))
            presentViewController(alertView, animated:true, completion:nil)
        }
    }
    
}
