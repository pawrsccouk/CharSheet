//
//  CharSheetEditViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 20/11/2012.
//
import UIKit
import CoreData

private let CELL_ID = "CharSheetEditSkill_Cell"

/// This is the main controller for editing the values on a character sheet.
/// 
/// It provides the stats and skills as editable text fields with steppers where necessary.
/// It also provides a table for the skills which allows users to add new skills or remove existing ones.
///
/// - note: See also **CharSheetUseViewController** which is used when the character sheet has been edited successfully
///         and the user just wants to roll dice and view logs etc.

class CharSheetEditViewController : CharSheetViewController
{
    // MARK: IB Properties
    @IBOutlet weak var strengthTextField    : UITextField!
    @IBOutlet weak var constitutionTextField: UITextField!
    @IBOutlet weak var dexterityTextField   : UITextField!
    @IBOutlet weak var speedTextField       : UITextField!
    @IBOutlet weak var charismaTextField    : UITextField!
    @IBOutlet weak var intelligenceTextField: UITextField!
    @IBOutlet weak var perceptionTextField  : UITextField!
    @IBOutlet weak var luckTextField        : UITextField!

    @IBOutlet weak var skillsTableView      : UITableView!
    @IBOutlet weak var charNameTextField    : UITextField!
    @IBOutlet weak var gameTextField        : UITextField!
    @IBOutlet weak var levelTextField       : UITextField!
    @IBOutlet weak var playerTextField      : UITextField!
    @IBOutlet weak var experienceTextField  : UITextField!

	/// A collection of stepper controllers used to link each stepper to a corresponding text field.
	@IBOutlet var stepperControllers: [StepperAssistant]!

	// MARK: IB Actions

    @IBAction func editDone(_ sender: AnyObject?)
	{
        configureData()
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
		presentingViewController?.dismiss(animated: true, completion:nil)
    }
    
    @IBAction func addSkill(_ sender: AnyObject?)
	{
        let _ = charSheet.appendSkill()
        skillsTableView.reloadData()
    }

    // MARK: Overrides
    
    override func viewWillAppear(_ animated: Bool)
	{
        super.viewWillAppear(animated)
        configureView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
        if segue.identifier == "AddSkillPopup" {
            // Connect the Edit Skill view controller to the skill it is editing.
            let asnc = segue.destination as! UINavigationController
            let esc = asnc.childViewControllers[0] as! EditSkillViewController
            esc.skill = charSheet.appendSkill()
            esc.completionCallback = { self.skillsTableView.reloadData() }
        }
    }
    
    // MARK: Private helper functions
    
	/// Copies data in the model into the various UI controls.
    fileprivate func configureView()
	{
		let name = charSheet.name ?? ""
        navigationItem.title      = "Edit - \(name)"
        charNameTextField.text   = charSheet.name
        gameTextField.text       = charSheet.game
        playerTextField.text     = charSheet.player
        levelTextField.text      = "\(charSheet.level)"
        experienceTextField.text = charSheet.experience.description
        
        // Copy the stats values to the text fields.
        strengthTextField.text     = "\(charSheet.strength)"
        dexterityTextField.text    = "\(charSheet.dexterity)"
        constitutionTextField.text = "\(charSheet.constitution)"
        speedTextField.text        = "\(charSheet.speed)"
        charismaTextField.text     = "\(charSheet.charisma)"
        perceptionTextField.text   = "\(charSheet.perception)"
        intelligenceTextField.text = "\(charSheet.intelligence)"
        luckTextField.text         = "\(charSheet.luck)"

		for s in stepperControllers {
			s.updateStepperFromTextField()
		}

        // Skills are handled by the view delegate.
		skillsTableView.reloadData()
		skillsTableView.setEditing(true, animated:false)
    }

	/// Copies the data in the various UI controls back into the model.
    fileprivate func configureData()
	{
        charSheet.name   = charNameTextField.text
        charSheet.game   = gameTextField.text
        charSheet.player = playerTextField.text
        charSheet.experience   = Int32(Int(experienceTextField.text   ?? "") ?? 0)
        charSheet.level        = Int16(Int(levelTextField.text        ?? "") ?? 0)
        
        charSheet.strength     = Int16(Int(strengthTextField.text     ?? "") ?? 0)
        charSheet.dexterity    = Int16(Int(dexterityTextField.text    ?? "") ?? 0)
        charSheet.constitution = Int16(Int(constitutionTextField.text ?? "") ?? 0)
        charSheet.speed        = Int16(Int(speedTextField.text        ?? "") ?? 0)
        charSheet.charisma     = Int16(Int(charismaTextField.text     ?? "") ?? 0)
        charSheet.perception   = Int16(Int(perceptionTextField.text   ?? "") ?? 0)
        charSheet.intelligence = Int16(Int(intelligenceTextField.text ?? "") ?? 0)
        charSheet.luck         = Int16(Int(luckTextField.text         ?? "") ?? 0)

		// Update the 'order' attribute in the skills to match the order in the set.
		var i: Int16 = 0
		for sk in charSheet.skills.array.map({ $0 as! Skill }) {
			sk.order = i
			i += 1
		}
    }
}

    // MARK: - Table View Data Source


extension CharSheetEditViewController: UITableViewDataSource
{
    func tableView(           _ tableView: UITableView,
		cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! EditSkillCell
        let skill = charSheet.skills[indexPath.row] as! Skill
        cell.name = skill.name ?? "No name"
        cell.value = skill.value
        cell.specialties = skill.specialtiesAsString
        cell.editingAccessoryType = .detailDisclosureButton
        return cell
    }

    func tableView(         _ tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return charSheet.skills.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }
}
    
    // MARK: - Table View Delegate

extension CharSheetEditViewController: UITableViewDelegate
{
    func tableView(           _ tableView: UITableView,
		commit editingStyle: UITableViewCellEditingStyle,
		forRowAt     indexPath: IndexPath)
	{
        if editingStyle == .delete {
            charSheet.removeSkillAtIndex(indexPath.row)
            skillsTableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(              _ tableView: UITableView,
		moveRowAt sourceIndexPath: IndexPath,
		to   destinationIndexPath: IndexPath)
	{
        // Table view has already moved the row, so we just need to update the model.
        charSheet.skills.moveObjects(at: IndexSet(integer: sourceIndexPath.row), to:destinationIndexPath.row)
    }
    
    
    func tableView(                              _ tableView: UITableView,
		accessoryButtonTappedForRowWith indexPath: IndexPath)
	{
        let esb = StoryboardManager.sharedInstance().editStoryboard
		let navId = "EditSkillNavigationController"
        let esnc = esb.instantiateViewController(withIdentifier: navId) as! UINavigationController
        
        let editSkillViewController = esnc.childViewControllers[0] as! EditSkillViewController
        editSkillViewController.skill = charSheet.skills[indexPath.row] as! Skill
        editSkillViewController.completionCallback = { self.skillsTableView.reloadData() }
        esnc.modalPresentationStyle = .formSheet
        esnc.modalTransitionStyle = .crossDissolve
		navigationController?.present(esnc, animated: true, completion:nil)
    }
}
