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

/// This view controller is the main view controller for the 'viewing and using' part of the app.
///
/// This displays a collection of stats, skills and other attributes such as name and XP.
/// It includes a toolbar with general commands such as 'export via Email' and 'make a die roll'.
///
/// See also **CharSheetEditViewController**, which handles changing the stats and skills of the character.

final class CharSheetUseViewController : CharSheetViewController
{
    // MARK: IB Properties

	@IBOutlet var statButtons: [UseStatLabel]!
	@IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var skillsCollectionView: UICollectionView!
    @IBOutlet weak var playerLabel    : UILabel!
    @IBOutlet weak var gameLabel      : UILabel!
    @IBOutlet weak var levelLabel     : UILabel!
    @IBOutlet weak var experienceLabel: UILabel!
    @IBOutlet weak var meleeAddsLabel : UILabel!
    @IBOutlet weak var rangedAddsLabel: UILabel!
    @IBOutlet weak var setHealthBtn   : UIButton!

	// MARK: IB Actions

    @IBAction func backgroundSelected(_ sender: AnyObject?)
	{
        deselectEveryStat()
        deselectEverySkill()
    }
    
    
    @IBAction func editCharSheet(_ sender: AnyObject?)
	{
        // Load the edit view, edit view controller and navigation item all from the "Edit" storyboard file.
        let editStoryboard = StoryboardManager.sharedInstance().editStoryboard
        let editNavigationController = editStoryboard.instantiateInitialViewController() as! UINavigationController
        let charSheetEditViewController = editNavigationController.viewControllers[0] as! CharSheetEditViewController
        
        charSheetEditViewController.managedObjectContext = managedObjectContext
        charSheetEditViewController.charSheet = charSheet
		navigationController?.present(editNavigationController, animated:true, completion:nil)
    }


	@IBAction func exportEmail(_ sender: AnyObject?)
	{
		// Abort if there are no email accounts on this device.
		if !MFMailComposeViewController.canSendMail() {
			let alertView = UIAlertController(
				title         : "Export via email",
				message       :"This device is not set up to send email.",
				preferredStyle: .alert)
			alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			present(alertView, animated: true, completion: nil)
			return
		}

		do {
			try exportToEmail()
		}
		catch let error as NSError {
			let title = "Error converting \(charSheet.name ?? "NULL") to XML"
			let alertView = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
			alertView.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
			present(alertView, animated: true, completion: nil)
		}
	}


	@IBAction func setHealth(_ sender: AnyObject?)
	{
		NSLog("setHealth(\(String(describing: sender)))")	// TODO: In future this will be a segue.
	}


	@IBAction func statSelected(_ sender: AnyObject?)
	{
		assert(sender as? UseStatLabel != nil, "Sender \(String(describing: sender)) is nil or not a label.")
		if let statLabel = sender as? UseStatLabel {
			assert(statLabel.isKind(of: UseStatLabel.self), "Sender [\(statLabel)] is not of class UseStatLabel")
			deselectEveryStat()
			statLabel.isSelected = true
			statLabel.setNeedsDisplay()
		}
	}





    // MARK: Properties

	/// Character sheet to display.
	///
	/// - note: Table view callbacks will occur before this is set, so we will have to test for it.
	///         Otherwise a CharSheet object must be set before any methods are called.
    override var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                configureView()
				enableToolbarButtons(charSheet != nil)
                navigationItem.title = charSheet?.name ?? "No name"
            }
        }
    }

	/// Default character sheet to display if the user hasn't set one already.
	///
	/// Once the user assigns a value to charSheet then this has no effect.
	var defaultCharSheet: CharSheet? = nil

    // MARK: Private Methods

	/// Present a mail composer view with a default email message and the contents of the character exported as XML into an attachment.
	fileprivate func exportToEmail() throws
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
		let value = try charSheet.exportToXML()
		charSheet.name = charSheet.name ?? "Unknown"
		let bodyHTML = String(format: bodyHTMLFormat, charSheet.name!, charSheet.name!, Date() as CVarArg)

		// Present a mail compose view with the data as an attachment.
		let mailVC = MFMailComposeViewController()
		mailVC.mailComposeDelegate = self
		mailVC.setSubject("\(charSheet.name!) exported from CharSheet.")
		mailVC.setMessageBody(bodyHTML, isHTML:true)
		mailVC.addAttachmentData(value as Data,
			mimeType: "application/charsheet+xml",
			fileName: "\(charSheet.name!).charSheet")
		present(mailVC, animated:true, completion:nil)
	}

	/// Given an index path return the Skill object that corresponds to the index in the skills array.
	fileprivate func skillForIndexPath(_ indexPath: IndexPath) -> Skill
	{
		assert(indexPath.count == 2 && indexPath[0] == 0, "Invalid index path \(indexPath)")
		return charSheet.skills.object(at: indexPath[1]) as! Skill
	}



	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		func prepareDieRollView(_ dieRollViewController: DieRollViewController)
		{
			dieRollViewController.addTickToSkillCallback = { $0.addTick() }

			let selectedIndexPaths = skillsCollectionView.indexPathsForSelectedItems ?? [IndexPath]()
			let selectedSkills = selectedIndexPaths.map{ self.skillForIndexPath($0) }

			var statData: DieRoll.StatInfo? = nil
			if let selectedLabel = statButtons.filter({ $0.isSelected }).first {
				statData = (selectedLabel.name, selectedLabel.value)
			}
			dieRollViewController.setInitialStat(statData, skills:selectedSkills)
		}

		var newViewController: CharSheetViewController
		if segue.identifier == "SpellTargets" {		// SpellTargets is a popover with no nav controller.
			newViewController = segue.destination as! CharSheetViewController
		} else {									// All other controllers are embedded in a navigation controller.
			let navigationController = segue.destination as! UINavigationController
			newViewController = navigationController.children[0] as! CharSheetViewController
		}
			// Get the new controller and set some common properties.
		newViewController.charSheet = charSheet
		newViewController.managedObjectContext = managedObjectContext
		if segue.identifier == "DieRoll" {  // Extra prep for the die roll view.
			prepareDieRollView(newViewController as! DieRollViewController  )
		}
	}


    //MARK: Managing the detail item

	/// Update the user interface with data from the character sheet supplied.
    fileprivate func configureView()
	{
        if let sheet = charSheet {
			// Sort the skills so the set in memory matches the one in the DB.
			// I'll update the 'order' attribute when I edit the skills in the Edit View Controller.
			sheet.skills.sort(using: [NSSortDescriptor(key: "order", ascending: true)])

            navigationItem.title = sheet.name

			// Stat buttons. The name in the button should match the name of the stat, so use KVO to get it.
			for b in statButtons {
				let val = sheet.value(forKey: b.name.lowercased()) as AnyObject?
				b.value = Int16(val?.intValue ?? 0)
			}

            // Misc text labels.
            playerLabel.text = sheet.player
            gameLabel.text   = sheet.game
            levelLabel.text  = sheet.level.description
            experienceLabel.text = sheet.experience.description
            meleeAddsLabel.text  = sheet.meleeAdds.description
            rangedAddsLabel.text = sheet.rangedAdds.description
			setHealthBtn.setTitle(sheet.health, for: UIControl.State())
        }
		else {	// Disable the toolbar controls if there are no characters selected.

		}
        skillsCollectionView.allowsSelection = true
        skillsCollectionView.allowsMultipleSelection = true
        skillsCollectionView.reloadData()
    }

	/// Enable or disable the toolbar buttons.
	/// 
	/// - parameter enable: If true, enable the buttons, otherwise disable them.
	fileprivate func enableToolbarButtons(_ enable: Bool)
	{
		guard let items = toolbar.items else { return }
		for btn in items {
			btn.isEnabled = enable
		}
	}

    override func viewDidLoad()
	{
		super.viewDidLoad()
        skillsCollectionView.register(UseSkillCell.self, forCellWithReuseIdentifier:COLLECTION_CELL_ID)
    }


	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		// If we are about to display an empty char sheet, and we have a default then display the default instead.
		if let cs = defaultCharSheet, charSheet == nil {
			charSheet = cs
		}
		configureView()
		enableToolbarButtons(charSheet != nil)
	}

	fileprivate func deselectEveryStat()
	{
		for statLabel in statButtons.filter({ $0.isSelected }) {
			statLabel.isSelected = false
			statLabel.setNeedsDisplay()
		}
	}

	fileprivate func deselectEverySkill()
	{
		if let ips = skillsCollectionView.indexPathsForSelectedItems {
			for selectionPath in ips {
				skillsCollectionView.deselectItem(at: selectionPath, animated:true)
			}
		}
	}
}

    // MARK: - Collection View Data Source

extension CharSheetUseViewController: UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
			let cell = skillsCollectionView.dequeueReusableCell(
				withReuseIdentifier: COLLECTION_CELL_ID,
				for:indexPath) as! UseSkillCell
			cell.skill = skillForIndexPath(indexPath)
			return cell
	}

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
        return charSheet?.skills.count ?? 0
    }
    
}

    //MARK: - Mail Composer delegate

extension CharSheetUseViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
        controller.dismiss(animated: true, completion:nil)
        
        // If something went wrong, produce an alert to say what.
        if (result.rawValue == MFMailComposeResult.failed.rawValue) || (error != nil) {
            let localisedDescription = error?.localizedDescription ?? "No error given"
            let alertView = UIAlertController(
				title          : "Error sending email",
				message        : localisedDescription,
				preferredStyle : .alert)
            alertView.addAction(UIAlertAction(title: "Close", style: .default, handler:nil))
            present(alertView, animated:true, completion:nil)
        }
    }
}
