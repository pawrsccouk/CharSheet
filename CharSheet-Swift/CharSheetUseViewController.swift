//
//  CharSheetUseViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 23/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

import CoreData
import UIKit
import MessageUI

class CharSheetUseViewController : UIViewController
{
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
    @IBOutlet weak var setHealthBtn   : UIButton!

    @IBAction func backgroundSelected(sender: AnyObject?)
	{
        deselectEveryStat()
        deselectEverySkill()
    }
    
    
    @IBAction func editCharSheet(sender: AnyObject?)
	{
        resetUI()
        
        // Load the edit view, edit view controller and navigation item all from the "Edit" storyboard file.
        let editStoryboard = StoryboardManager.sharedInstance().editStoryboard
        let editNavigationController = editStoryboard.instantiateInitialViewController() as! UINavigationController
        let charSheetEditViewController = editNavigationController.viewControllers[0] as! CharSheetEditViewController
        
        charSheetEditViewController.managedObjectContext   = self.managedObjectContext
        charSheetEditViewController.charSheet = self.charSheet
        charSheetEditViewController.dismissCallback = {     // Save data and refresh the view when the modal popup completes.
            self.configureView()
            if let callback = self.saveAllData {
                callback()
            }
        }
		navigationController?.presentViewController(editNavigationController, animated:true, completion:nil)
    }

	private func presentEmailControllerForData(xmlData: NSData) -> NilResult
	{
		charSheet.name = charSheet.name ?? "Unknown"
		let bodyHTML = String(format: bodyHTMLFormat, charSheet.name!, charSheet.name!, NSDate())

		// Present a mail compose view with the data as an attachment.
		let mailVC = MFMailComposeViewController()
		mailVC.mailComposeDelegate = self
		mailVC.setSubject("\(charSheet.name!) exported from CharSheet.")
		mailVC.setMessageBody(bodyHTML, isHTML:true)
		mailVC.addAttachmentData(
			xmlData,
			mimeType: "application/charsheet+xml",
			fileName: "\(charSheet.name!).charSheet")
		presentViewController(mailVC, animated:true, completion:nil)
		return success()
	}

	private func exportToEmail() -> NilResult
	{
		assert(MFMailComposeViewController.canSendMail(), "Device cannot send mail.")
		return charSheet.exportToXML()
			.andThen(presentEmailControllerForData)
	}

	@IBAction func exportEmail(sender: AnyObject?)
	{
		// Abort if there are no email accounts on this device.
		if !MFMailComposeViewController.canSendMail() {
			let alertView = UIAlertController(
				title         : "Export via email",
				message       :"This device is not set up to send email.",
				preferredStyle: .Alert)
			alertView.addAction(UIAlertAction(
				title  : "OK",
				style  : .Default,
				handler: nil))
			presentViewController(alertView, animated: true, completion: nil)
			return
		}

		switch exportToEmail() {
		case .Error(let error):
			let localisedDescription = error.localizedDescription ?? "Unknown error"
			let alertView = UIAlertController(
				title         : "Error converting \(charSheet.name) to XML",
				message       : localisedDescription,
				preferredStyle: .Alert)
			alertView.addAction(UIAlertAction(
				title  : "Close",
				style  : .Default,
				handler: nil))
			presentViewController(alertView, animated: true, completion: nil)
		case .Success:
			break
		}

	}

	@IBAction func setHealth(sender: AnyObject?)
	{
        // TODO: In future this will be a segue.
        NSLog("setHealth(\(sender))")
    }


	@IBAction func statSelected(sender: AnyObject?)
	{
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




    // MARK: - Properties

	/// Character sheet to display.
	///
	/// :note: Table view callbacks will occur before this is set, so will have to test for it.
	///        Otherwise it must be set before any methods are called.
    var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                configureView()
                navigationItem.title = charSheet?.name ?? "No name"
				masterPopoverController?.dismissPopoverAnimated(true)
            }
        }
    }

    var masterPopoverController: UIPopoverController?
    var managedObjectContext: NSManagedObjectContext!
    
	/// The currently selected stat label.
    private weak var selectedStatLabel: UseStatLabel?
    
	/// Toolbar item for the Export button.
    private var exportItem: UIBarButtonItem?
    
	/// Action sheet for where to export to.
    private var exportLocationSheet: UIActionSheet?
    
	/// Callback to update all data in the app (e.g. save all dirty records, add new ones and delete dead ones).
    var saveAllData: VoidCallback?

    // MARK: Private Methods
    
    
    
    
	/// Reset any ongoing interface windows (e.g. close any non-modal dialogs etc).
	///
	/// Used to clean up after one command when the user has started another one.
    private func resetUI()
	{
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



	private func skillForIndexPath(indexPath: NSIndexPath) -> Skill
	{
		assert(indexPath.length == 2 && indexPath.indexAtPosition(0) == 0, "Invalid index path \(indexPath)")
		return charSheet.skills.objectAtIndex(indexPath.indexAtPosition(1)) as! Skill
	}



	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		func prepareDieRollView(dieRollViewController: DieRollViewController)
		{
			dieRollViewController.charSheet = self.charSheet
			dieRollViewController.addTickToSkillCallback = { $0.addTick() }
			dieRollViewController.dismissCallback = {
				if let save = self.saveAllData {
					save()
				}
			}

			var selectedIndexPaths = skillsCollectionView.indexPathsForSelectedItems() as! [NSIndexPath]
			var selectedSkills = selectedIndexPaths.map{ self.skillForIndexPath($0) }

			var statData: DieRoll.StatInfo? = nil
			if let selectedLabel = selectedStatLabel {
				statData = (selectedLabel.name, selectedLabel.value)
			}
			dieRollViewController.setInitialStat(statData, skills:selectedSkills)
		}

		func prepareNotesView(editNotesViewController :EditNotesViewController)
		{
			editNotesViewController.managedObjectContext = managedObjectContext
			editNotesViewController.charSheet = charSheet
			editNotesViewController.dismissCallback = {     // Save and refresh the view when the modal popup completes.
				self.configureView()
				if let save = self.saveAllData {
					save()
				}
			}

		}

		func prepareXPView(editXPViewController: EditXPViewController)
		{
			editXPViewController.managedObjectContext = managedObjectContext
			editXPViewController.charSheet = charSheet
			editXPViewController.dismissCallback = {     // Save and refresh the view when the modal popup completes.
				self.configureView()
				if let save = self.saveAllData {
					save()
				}
			}
		}


		func prepareLogView(logViewController: LogViewController)
		{
			logViewController.charSheet = self.charSheet
		}



		var navigationController = segue.destinationViewController as! UINavigationController
		let newViewController: AnyObject = navigationController.childViewControllers[0]
		switch segue.identifier! {
		case "DieRoll":
			prepareDieRollView(newViewController as! DieRollViewController  )
		case "ShowLogView":
			prepareLogView(newViewController as! LogViewController      )
		case "ShowNotesView":
			prepareNotesView(newViewController as! EditNotesViewController)
		case "ShowXPView":
			prepareXPView(newViewController as! EditXPViewController   )
		default:
			assert(false, "Unknown segue \(segue) ID \(segue.identifier) passed to \(self)")
		}
	}


    //MARK: - Managing the detail item

    private func configureView()
	{
        // Update the user interface for the detail item.
        if let sheet = charSheet {
            navigationItem.title = sheet.name
            // Stat buttons
			strengthBtn.value     = sheet.strength
            dexterityBtn.value    = sheet.dexterity
            constitutionBtn.value = sheet.constitution
            speedBtn.value        = sheet.speed
            intelligenceBtn.value = sheet.intelligence
            perceptionBtn.value   = sheet.perception
            luckBtn.value         = sheet.luck
            charismaBtn.value     = sheet.charisma
            
            // Misc text labels.
            playerLabel.text = sheet.player
            gameLabel.text   = sheet.game
            levelLabel.text  = sheet.level.description
            experienceLabel.text = sheet.experience.description
            meleeAddsLabel.text  = sheet.meleeAdds.description
            rangedAddsLabel.text = sheet.rangedAdds.description
            setHealthBtn.setTitle(sheet.health, forState: .Normal)
        }
        skillsCollectionView.allowsSelection = true
        skillsCollectionView.allowsMultipleSelection = true
        skillsCollectionView.reloadData()
    }

    
    private let COLLECTION_CELL_ID = "SkillsCollection_Cell"
    
    override func viewDidLoad()
	{
        skillsCollectionView.registerClass(UseSkillCell.self, forCellWithReuseIdentifier:COLLECTION_CELL_ID)
        configureView()
    }


	private func deselectEveryStat()
	{
		let  allStatLabels = [
			strengthBtn, constitutionBtn, dexterityBtn, speedBtn,
			perceptionBtn, intelligenceBtn, charismaBtn , luckBtn
		]
		selectedStatLabel = nil
		for statLabel in (allStatLabels.filter { $0.selected }) {
			statLabel.selected = false
			statLabel.setNeedsDisplay()
		}
	}

	private func deselectEverySkill()
	{
		if let ips = skillsCollectionView.indexPathsForSelectedItems() as? [NSIndexPath] {
			for selectionPath in ips {
				skillsCollectionView.deselectItemAtIndexPath(selectionPath, animated:true)
			}
		}
	}
}

    //MARK: - Split view delegate

extension CharSheetUseViewController: UISplitViewControllerDelegate
{

    func splitViewController(  splitController: UISplitViewController,
		willHideViewController  viewController: UIViewController,
		withBarButtonItem        barButtonItem: UIBarButtonItem,
		forPopoverController popoverController: UIPopoverController)
	{
        barButtonItem.title = NSLocalizedString("Characters", comment: "Characters")
        navigationItem.setLeftBarButtonItem(barButtonItem, animated:true)
        masterPopoverController = popoverController
    }
    
    func splitViewController(   splitController: UISplitViewController,
		willShowViewController   viewController: UIViewController,
		invalidatingBarButtonItem barButtonItem: UIBarButtonItem)
	{
        // Called when the view is shown again in the split view, invalidating the button and popover controller.
        navigationItem.setLeftBarButtonItem(nil, animated:true)
        masterPopoverController = nil
    }
}

    // MARK: - Collection View Data Source
extension CharSheetUseViewController: UICollectionViewDataSource
{
	func collectionView(  collectionView: UICollectionView,
		cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
			let cell = skillsCollectionView.dequeueReusableCellWithReuseIdentifier(COLLECTION_CELL_ID,
				forIndexPath:indexPath) as! UseSkillCell
			cell.skill = skillForIndexPath(indexPath)
			return cell
	}

    func collectionView(collectionView: UICollectionView,
		numberOfItemsInSection section: Int) -> Int
	{
        return charSheet?.skills.count ?? 0
    }
    
}

    //MARK: - Mail Composer delegate
extension CharSheetUseViewController: MFMailComposeViewControllerDelegate
{

    func mailComposeController(controller: MFMailComposeViewController!,
		didFinishWithResult    result    : MFMailComposeResult,
		error                            : NSError!) {

        NSLog("Mail composer finished. Result: %d, error: %@", result.value, error ?? "nil")
        
        controller.dismissViewControllerAnimated(true, completion:nil)
        
        // If something went wrong, produce an alert to say what.
        if (result.value == MFMailComposeResultFailed.value) || (error != nil) {
            let localisedDescription = error?.localizedDescription ?? "No error given"
            let alertView = UIAlertController(
				title          : "Error sending email",
				message        : localisedDescription,
				preferredStyle : .Alert)
            alertView.addAction(UIAlertAction(title: "Close", style: .Default, handler:nil))
            presentViewController(alertView, animated:true, completion:nil)
        }
    }
}
