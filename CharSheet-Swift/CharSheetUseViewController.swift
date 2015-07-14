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

private let COLLECTION_CELL_ID = "SkillsCollection_Cell"

final class CharSheetUseViewController : CharSheetViewController
{
    // MARK: IB Properties

	@IBOutlet var statButtons: [UseStatLabel]!
    @IBOutlet weak var skillsCollectionView: UICollectionView!
    @IBOutlet weak var playerLabel    : UILabel!
    @IBOutlet weak var gameLabel      : UILabel!
    @IBOutlet weak var levelLabel     : UILabel!
    @IBOutlet weak var experienceLabel: UILabel!
    @IBOutlet weak var meleeAddsLabel : UILabel!
    @IBOutlet weak var rangedAddsLabel: UILabel!
    @IBOutlet weak var setHealthBtn   : UIButton!

	// MARK: IB Actions

    @IBAction func backgroundSelected(sender: AnyObject?)
	{
        deselectEveryStat()
        deselectEverySkill()
    }
    
    
    @IBAction func editCharSheet(sender: AnyObject?)
	{
        // Load the edit view, edit view controller and navigation item all from the "Edit" storyboard file.
        let editStoryboard = StoryboardManager.sharedInstance().editStoryboard
        let editNavigationController = editStoryboard.instantiateInitialViewController() as! UINavigationController
        let charSheetEditViewController = editNavigationController.viewControllers[0] as! CharSheetEditViewController
        
        charSheetEditViewController.managedObjectContext = managedObjectContext
        charSheetEditViewController.charSheet = charSheet
		navigationController?.presentViewController(editNavigationController, animated:true, completion:nil)
    }


	@IBAction func exportEmail(sender: AnyObject?)
	{
		// Abort if there are no email accounts on this device.
		if !MFMailComposeViewController.canSendMail() {
			let alertView = UIAlertController(
				title         : "Export via email",
				message       :"This device is not set up to send email.",
				preferredStyle: .Alert)
			alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
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
			alertView.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
			presentViewController(alertView, animated: true, completion: nil)
		case .Success:
			break
		}
	}


	@IBAction func setHealth(sender: AnyObject?)
	{
		NSLog("setHealth(\(sender))")	// TODO: In future this will be a segue.
	}


	@IBAction func statSelected(sender: AnyObject?)
	{
		assert(sender as? UseStatLabel != nil, "Sender \(sender) is nil or not a label.")
		if let statLabel = sender as? UseStatLabel {
			assert(statLabel.isKindOfClass(UseStatLabel), "Sender [\(statLabel)] is not of class UseStatLabel")
			deselectEveryStat()
			statLabel.selected = true
			statLabel.setNeedsDisplay()
		}
	}





    // MARK: Properties

	/// Character sheet to display.
	///
	/// :note: Table view callbacks will occur before this is set, so will have to test for it.
	///        Otherwise it must be set before any methods are called.
    override var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                configureView()
                navigationItem.title = charSheet?.name ?? "No name"
            }
        }
    }

	/// Default character sheet to display if the user hasn't set one already.
	///
	/// Once the user assigns a value to charSheet then this has no effect.
	var defaultCharSheet: CharSheet? = nil

    // MARK: Private Methods
    
	private func exportToEmail() -> NilResult
	{
		let bodyHTMLFormat =
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

		assert(MFMailComposeViewController.canSendMail(), "Device cannot send mail.")
		switch charSheet.exportToXML() {
		case .Error(let error): return failure(error)
		case .Success(let value):
			charSheet.name = charSheet.name ?? "Unknown"
			let bodyHTML = String(format: bodyHTMLFormat, charSheet.name!, charSheet.name!, NSDate())

			// Present a mail compose view with the data as an attachment.
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.setSubject("\(charSheet.name!) exported from CharSheet.")
			mailVC.setMessageBody(bodyHTML, isHTML:true)
			mailVC.addAttachmentData(
				value.unwrap,
				mimeType: "application/charsheet+xml",
				fileName: "\(charSheet.name!).charSheet")
			presentViewController(mailVC, animated:true, completion:nil)
			return success()
		}
	}

	private func skillForIndexPath(indexPath: NSIndexPath) -> Skill
	{
		assert(indexPath.length == 2 && indexPath.indexAtPosition(0) == 0, "Invalid index path \(indexPath)")
		return charSheet.skills.objectAtIndex(indexPath.indexAtPosition(1)) as! Skill
	}



	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		func prepareDieRollView(dieRollViewController: DieRollViewController)
		{
			dieRollViewController.addTickToSkillCallback = { $0.addTick() }

			var selectedIndexPaths = skillsCollectionView.indexPathsForSelectedItems() as! [NSIndexPath]
			var selectedSkills = selectedIndexPaths.map{ self.skillForIndexPath($0) }

			var statData: DieRoll.StatInfo? = nil
			if let selectedLabel = statButtons.filter({ $0.selected }).first {
				statData = (selectedLabel.name, selectedLabel.value)
			}
			dieRollViewController.setInitialStat(statData, skills:selectedSkills)
		}

		// Get the new controller and set some common properties.
		var navigationController = segue.destinationViewController as! UINavigationController
		let newViewController = navigationController.childViewControllers[0] as! CharSheetViewController
		newViewController.charSheet = charSheet
		newViewController.managedObjectContext = managedObjectContext
		if segue.identifier == "DieRoll" {  // Extra prep for the die roll view.
			prepareDieRollView(newViewController as! DieRollViewController  )
		}
	}


    //MARK: Managing the detail item

	/// Update the user interface with data from the character sheet supplied.
    private func configureView()
	{
        if let sheet = charSheet {
			// Sort the skills so the set in memory matches the one in the DB.
			// I'll update the 'order' attribute when I edit the skills in the Edit View Controller.
			sheet.skills.sortUsingDescriptors([NSSortDescriptor(key: "order", ascending: true)])

            navigationItem.title = sheet.name

			// Stat buttons. The name in the button should match the name of the stat, so use KVO to get it.
			for b in statButtons {
				b.value = Int16(sheet.valueForKey(b.name.lowercaseString)!.integerValue)
			}

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

    override func viewDidLoad()
	{
		super.viewDidLoad()
        skillsCollectionView.registerClass(UseSkillCell.self, forCellWithReuseIdentifier:COLLECTION_CELL_ID)
    }


	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		// If we are about to display an empty char sheet, and we have a default then display the default instead.
		if let cs = defaultCharSheet where charSheet == nil {
			charSheet = cs
		}
		configureView()
	}

	private func deselectEveryStat()
	{
		for statLabel in statButtons.filter({ $0.selected }) {
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

    // MARK: - Collection View Data Source
extension CharSheetUseViewController: UICollectionViewDataSource
{
	func collectionView(  collectionView: UICollectionView,
		cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
			let cell = skillsCollectionView.dequeueReusableCellWithReuseIdentifier(
				COLLECTION_CELL_ID,
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
