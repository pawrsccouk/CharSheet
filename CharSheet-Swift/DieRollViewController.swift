//
//  PWDieRollViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 25/11/2012.
//
//

    // Controllers
import UIKit
import CoreData

/// This object allows the user to specify the stat, skill(s), extra d4s and static adds for a given die roll.
/// We then trigger a method on the model to roll the dice and push a **DieRollResultViewController** on the stack to display the result.

class DieRollViewController: CharSheetViewController
{
    // MARK: IB Properties
    
    @IBOutlet weak var statButton: UIButton!
    @IBOutlet weak var skillsTable: UITableView!
    @IBOutlet weak var addsTextField: UITextField!
    @IBOutlet weak var extraDiceTextField: UITextField!
	@IBOutlet var stepperAssistants: [StepperAssistant]!

	// MARK: IB Actions
    
    @IBAction func cancel(_ sender: AnyObject?)
	{
		presentingViewController?.dismiss(animated: true, completion:nil)
    }

    @IBAction func editSkillTable(_ sender: AnyObject?)
	{
        let newEditing = !skillsTable.isEditing
        skillsTable.isEditing = newEditing
    }
    
	@IBAction func addSkill(_ sender: AnyObject?)
	{
		let skillsToAdd = (charSheet!.skills.array)
			.map { $0 as! Skill }
			.filter { !self.dieRoll.skills.contains($0) }

        // Quit early if there are no more skills we can add.
		if(skillsToAdd.count == 0) {
			let alert = UIAlertController(
				title         : "Add skill",
				message       : "There are no more skills to add.",
				preferredStyle: .alert)
			alert.addAction(UIAlertAction(
				title  : "Close",
				style  : .default,
				handler: nil))
			present(alert, animated: true, completion: nil)
			return
        }

		assert(skillSelectController == nil,
			"Skill select controller \(String(describing: skillSelectController)) should be nil when adding a skill")
		skillSelectController = SkillSelectController.skillSelectControllerFromNib()
		assert(skillSelectController != nil, "No SkillSelectController object in Nib")
		if let controller = skillSelectController {
			controller.skillsToPick  = MutableOrderedSet<Skill>(array: skillsToAdd)
			controller.selectedSkill = skillsToAdd.first // Default skill to show
			controller.selectedSpecialty = nil
			editingSkill = nil
			navigationController?.pushViewController(controller, animated:true)
		}
	}


    // MARK: Properties

	/// If we are editing an existing skill, this is the skill we are changing.
	/// If we are adding a new skill, this is nil.
	fileprivate var editingSkill: Skill? = nil

	// Context for KVO.
	fileprivate var myContext: Int = 0

	/// The die roll object actually makes the roll and records the results.
	///
	/// I set up it's properties here (selected stat, skills, specialties etc.) which are used for the roll.
	@objc var dieRoll : DieRoll = DieRoll()

	/// The controller used to present a list of skills to the user.
	///
	/// I need to track this so that I can add the skill it provides to the die roll when it exits.
	var skillSelectController: SkillSelectController?

	/// Callback type for the callback to add a tick to the character sheet.
	typealias AddTickCallback = (_ skill: Skill) -> Void

	/// Callback block called once the dialog has been closed to add a tick to the skill that was used.
	var addTickToSkillCallback: AddTickCallback?


	// MARK: Overrides

	/// The character sheet whose stats and skills we are using for this die roll.
	override var charSheet: CharSheet! {
		didSet {
			dieRoll.charSheet = charSheet
		}
	}


	deinit
	{
		dieRoll.removeObserver(self, forKeyPath: "adds")
		dieRoll.removeObserver(self, forKeyPath: "extraD4s")
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
	{
		if let key = keyPath {
			switch key {
			case "adds" where context == /*&myContext*/ nil:
				addsTextField.text = "\(dieRoll.adds)"
				for s in stepperAssistants {
					s.updateStepperFromTextField()
				}
				return

			case "extraD4s" where context == /*&myContext*/ nil:
				extraDiceTextField.text = "\(dieRoll.extraD4s)"
				for s in stepperAssistants {
					s.updateStepperFromTextField()
				}
				return

			default:
				break
			}
		}
		super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
	}


	override func viewDidLoad()
	{
		super.viewDidLoad()
		dieRoll.addObserver(self, forKeyPath: #keyPath(DieRoll.adds),     options: ([.initial, .new]), context: nil)
		dieRoll.addObserver(self, forKeyPath: #keyPath(DieRoll.extraD4s), options: ([.initial, .new]), context: nil)
		updateStatLabel()

		if let navc = navigationController {
			assert(navc.delegate == nil, "DieRollViewController: The navigation controller \(navc) has a delegate of \(String(describing: navc.delegate)). It should be nil")
			navc.delegate = self
		}
	}


	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		switch segue.identifier! {
		case "ShowDieRollResult":
			let dieRollResultViewController = segue.destination as! DieRollResultViewController
			rollTheDieAndShowResultsInViewController(dieRollResultViewController)

		case "PushStatSelect":
			let statSelectViewController = segue.destination as! StatSelectViewController
			statSelectViewController.selectedStat = dieRoll.stat?.name ?? "No name"
			statSelectViewController.selectionChangedCallback = { newName, _ in
				self.statNameChanged(newName)
				self.updateStatLabel()
			}

		default:
			assert(false, "Unexpected segue identifier \(segue.identifier!)")
		}
	}

	// MARK: Public API

	/// Start the die roll view displaying a skill and/or a stat by default.
	///
	/// This allows the user to select the stat and/or skill from the main page and have them defaulted here.
	/// The user can add or remove the stat or skills later if they want.
    func setInitialStat(_ statOrNil: DieRoll.StatInfo?, skills:[Skill])
	{
        assert(self.charSheet != nil, "DieRollViewController: No char sheet specified.")
        dieRoll.skills = MutableOrderedSet<Skill>(array: skills)
        
        if let stat = statOrNil {
            dieRoll.stat = stat
            updateStatLabel()
        }
    }

	// MARK: Private Methods

	/// Update the label specifying which stat to use from the specified StatInfo object.
    fileprivate func updateStatLabel()
	{
        if let button = statButton {
            var statButtonText = "None"
            if let stat = dieRoll.stat {
                statButtonText = "\(stat.name): \(stat.value)"
            }
			button.setTitle(statButtonText, for: UIControl.State())
        }
    }

	/// Callback func called when the name of the stat has changed.
	/// Look up the value for the given name and assign a StatInfo pair to the die roll.
	fileprivate func statNameChanged(_ newStatName: String?)
	{
		var statInfo: DieRoll.StatInfo? = nil
		// Find the stat that name represents, and select it as dieRoll.stat.
		if  let newName = newStatName,
			let statObj = charSheet.value(forKey: newName.lowercased()) as? NSNumber?,
			let statValue = statObj?.intValue {
				statInfo = (newName, Int16(statValue))
		}
		dieRoll.stat = statInfo
	}

	/// Callback. Trigger a die roll with the settings in DieRoll, and present a view controller to show the results.
	///
	/// - parameter dieRollResultViewController: The controller to push to display the die roll result.
    fileprivate func rollTheDieAndShowResultsInViewController(_ dieRollResultViewController: DieRollResultViewController)
	{
		if let s = addsTextField.text, let adds = Int(s) {
			dieRoll.adds = adds
		} else {
			dieRoll.adds = 0
		}
		if let s = extraDiceTextField.text, let d4s = Int(s) {
			dieRoll.extraD4s = Int16(d4s)
		}
		else {
			dieRoll.extraD4s = 0
		}

		dieRoll.roll()
		dieRollResultViewController.dieRoll = dieRoll

		// Add the option to tick the skill if there is only one selected.
		assert(self.addTickToSkillCallback != nil)
		if dieRoll.skills.count == 1 {
			if let callback = addTickToSkillCallback {
				dieRollResultViewController.addTickAction = { callback(self.dieRoll.skills[0]) }
			}
		}
	}
}

    // MARK: - Navigation Controller Delegate

extension DieRollViewController: UINavigationControllerDelegate
{
	func navigationController(_ navigationController: UINavigationController,
		willShow      viewController: UIViewController,
		animated                                  : Bool)
	{
		// If this controller is being shown because the select skill view controller has just been closed,
		// then add the skill it has found.
		if viewController == self {
			if let oldSkill = editingSkill {
				// We are replacing one skill with another.
				if let selectedSkill = skillSelectController?.selectedSkill {
					// We have a skill to replace. Perform the replacement.
					if selectedSkill != oldSkill {
						let index = dieRoll.skills.indexOfObject(oldSkill)
						assert(index != NSNotFound, "Index of skill \(oldSkill).name = \(oldSkill.name ?? "NULL") not in die roll skill set.")
						if index != NSNotFound {
							dieRoll.skills.replaceObjectAtIndex(index, withObject:selectedSkill)
						}
					}
				} else {
					// We have no skill, remove the existing skill from the list to display.
					dieRoll.skills.remove(oldSkill)
				}
			} else {
				// We are adding a new skill, so just append to the list.
				if let selectedSkill = skillSelectController?.selectedSkill {
					dieRoll.skills = dieRoll.skills + [selectedSkill]
				}
			}

			if let selectedSkill = skillSelectController?.selectedSkill, let skillName = selectedSkill.name {
				dieRoll.specialties[skillName] = skillSelectController?.selectedSpecialty
			}
			skillsTable.reloadData()

			// Then release the skill select controller. We will create a new one next time we want to edit a skill.
			skillSelectController = nil
			editingSkill = nil
		}
	}
}

    //MARK: - Table View Data Source

extension DieRollViewController: UITableViewDataSource
{

    func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }
    
    
    
    func tableView(         _ tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return dieRoll.skills.count
    }
    
    

	func tableView(           _ tableView: UITableView,
		cellForRowAt indexPath: IndexPath ) -> UITableViewCell
	{
		let CELL_ID = "PWDieRollView_Cell"

		let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID)
			?? UITableViewCell(style: .value1, reuseIdentifier:CELL_ID)

		let skill = dieRoll.skills.objectAtIndex(indexPath.row)
		cell.textLabel?.text = skill.name
		if let detailLabel = cell.detailTextLabel {
			detailLabel.text = "No specialty"
			if let
				skillName = skill.name,
				let spec = dieRoll.specialties[skillName] {
					detailLabel.text = spec.name
			}
		}
		return cell
	}
}

// MARK: - Table View Delegate

extension DieRollViewController: UITableViewDelegate
{
    func tableView(           _ tableView: UITableView,
							  commit editingStyle: UITableViewCell.EditingStyle,
		forRowAt     indexPath: IndexPath)
	{
        assert(tableView == skillsTable && editingStyle == .delete)
        if(tableView == skillsTable && editingStyle == .delete) {
            let skill = dieRoll.skills[indexPath.row]
            if let skillName = skill.name {
                dieRoll.specialties[skillName] = nil
            }
            dieRoll.skills.removeObjectAtIndex(indexPath.row)
            skillsTable.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(             _ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath)
	{
        assert(skillSelectController == nil,
			"Table View select. Skill select controller is \(String(describing: skillSelectController)), should be nil")
        skillSelectController = SkillSelectController.skillSelectControllerFromNib()
        assert(skillSelectController != nil, "Failed to load SkillSelectController from Nib file.")
        let controller = skillSelectController!
        // Set the skill shown in the table as the currently-selected skill.
        controller.selectedSkill = dieRoll.skills[indexPath.row]
		editingSkill = controller.selectedSkill
        controller.selectedSpecialty = dieRoll.specialties[controller.selectedSkill?.name ?? ""]
        
        // The list of skills to pick is all the skills not already picked
		// except for the one we are currently editing.
        // Otherwise the user can't go back without making changes.
        let skillsToPick: [Skill] = (charSheet!.skills.array)
			.map { $0 as! Skill }
			.filter { $0 == controller.selectedSkill || !self.dieRoll.skills.contains($0) }
        controller.skillsToPick  = MutableOrderedSet<Skill>(array: skillsToPick)
		navigationController?.pushViewController(controller, animated: true)
    }
}

