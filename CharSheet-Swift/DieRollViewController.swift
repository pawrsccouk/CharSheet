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


class DieRollViewController : UIViewController, UITableViewDelegate {

    // MARK: - Interface Builder.
    
    @IBOutlet weak var statButton: UIButton!
    @IBOutlet weak var skillsTable: UITableView!
    @IBOutlet weak var addsTextField: UITextField!
    @IBOutlet weak var extraDiceTextField: UITextField!
    @IBOutlet weak var addsStepper: UIStepper!
    @IBOutlet weak var extraDiceStepper: UIStepper!

    
    @IBAction func cancel(sender: AnyObject?)
	{
		presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }

    @IBAction func stepperChanged(sender: AnyObject?)
	{
        assert(sender != nil, "stepperChanged: No sender")
        if let stepper = sender as? UIStepper {
            assert(stepper.isKindOfClass(UIStepper), "stepperChanged: Sender \(stepper) must be a UIStepper")
            assert(stepper == addsStepper || stepper == extraDiceStepper, "stepperChanged: Sender \(stepper) must be extra dice stepper \(extraDiceStepper) or adds stepper \(addsStepper)")
            if(stepper == addsStepper) {
                addsTextField.text = Int16(addsStepper.value).description
            }
            else if(stepper == extraDiceStepper) {
                extraDiceTextField.text = Int16(extraDiceStepper.value).description
            }
        }
    }
    
    @IBAction func textFieldChanged(sender: AnyObject?)
	{
        assert(sender != nil, "textFieldChanged: No sender")
        if let textField = sender as? UITextField {
            assert(textField.isKindOfClass(UITextField), "stepperChanged: Sender \(textField) must be a UITextField")
            assert(textField == addsTextField || textField == extraDiceTextField, "textFieldChanged: Sender %@ must be extra dice text field \(textField) or adds text field \(extraDiceTextField)")
            if (textField == addsTextField) {
                addsStepper.value = Double(textField.text?.toInt() ?? 0)
            }
            else if (textField == extraDiceTextField) {
                if (textField.text.toInt() < 0) {
                    textField.text = ""
                }
                extraDiceStepper.value = Double(extraDiceTextField.text?.toInt() ?? 0)
            }
        }
    }
  
    @IBAction func editSkillTable(sender: AnyObject?)
	{
        var newEditing = !skillsTable.editing
        skillsTable.editing = newEditing
    }
    
	@IBAction func addSkill(sender: AnyObject?)
	{
		var skillsToAdd = (charSheet!.skills.array)
			.map { $0 as! Skill }
			.filter{ !self.dieRoll.skills.contains($0) }

        // Quit early if there are no more skills we can add.
		if(skillsToAdd.count == 0) {
			let alert = UIAlertController(
				title         : "Add skill",
				message       : "There are no more skills to add.",
				preferredStyle: .Alert)
			alert.addAction(UIAlertAction(
				title  : "Close",
				style  : .Default,
				handler: nil))
			presentViewController(alert, animated: true, completion: nil)
			return
        }

		assert(skillSelectController == nil,
			"Skill select controller \(skillSelectController) should be nil when adding a skill")
		skillSelectController = SkillSelectController.skillSelectControllerFromNib()
		if let controller = skillSelectController {
			controller.skillsToPick  = MutableOrderedSet<Skill>(array: skillsToAdd)
			controller.selectedSkill = skillsToAdd[0] // Default to showing the first skill.
			controller.selectedSpecialty = nil
			navigationController!.pushViewController(controller, animated:true)
		}
	}


    // MARK: Properties

	// Context for KVO.
	private var myContext: Int = 0

	/// The die roll object actually makes the roll and records the results.
	///
	/// I set up it's properties here (selected stat, skills, specialties etc.) which are used for the roll.
	var dieRoll : DieRoll = DieRoll() {
		didSet {
			NSLog("Die roll \(dieRoll) set")
		}
	}

	deinit
	{
		dieRoll.removeObserver(self, forKeyPath: "adds")
		dieRoll.removeObserver(self, forKeyPath: "extraD4s")
	}

	 override func observeValueForKeyPath(keyPath: String,
		ofObject                           object: AnyObject,
		change                                   : [NSObject : AnyObject],
		context                                  : UnsafeMutablePointer<Void>)
	{
		if context != &myContext {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		NSLog("DieRoll keypath \(keyPath) changed.")
		if keyPath == "adds" {
			addsStepper.value = Double(dieRoll.adds)
			addsTextField.text = "\(dieRoll.adds)"
		}
		if keyPath == "extraD4s" {
			extraDiceStepper.value = Double(dieRoll.extraD4s)
			extraDiceTextField.text = "\(dieRoll.extraD4s)"
		}
	}

	/// The controller used to present a list of skills to the user.
	///
	/// I need to track this so that I can add the skill it provides to the die roll when it exits.
    var skillSelectController: SkillSelectController?

	/// The character sheet whose stats and skills we are using for this die roll.
    var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                dieRoll.charSheet = charSheet
                updateStatLabel()
                skillSelectController = nil
            }
        }
    }
    
	/// If the die roll dialog wants to add a tick to a skill, it will call this block passing in the skill to be updated.
    var dismissCallback: VoidCallback?
    
	/// Callback type for the callback to add a tick to the character sheet.
    typealias AddTickCallback = (skill: Skill) -> Void

	/// Callback block called once the dialog has been closed to add a tick to the skill that was used.
    var addTickToSkillCallback: AddTickCallback?

    func setInitialStat(statOrNil: DieRoll.StatInfo?, skills:[Skill])
	{
        assert(self.charSheet != nil, "DieRollViewController: No char sheet specified.")
        dieRoll.skills = MutableOrderedSet<Skill>(array: skills)
        
        if let stat = statOrNil {
            dieRoll.stat = stat
            updateStatLabel()
        }
    }
    

    override func viewDidLoad()
	{
        super.viewDidLoad()
		dieRoll.addObserver(self, forKeyPath: "adds",     options: (.Initial | .New), context: &myContext)
		dieRoll.addObserver(self, forKeyPath: "extraD4s", options: (.Initial | .New), context: &myContext)
        updateStatLabel()

        if let navc = navigationController {
            assert(navc.delegate == nil,
				"DieRollViewController: The navigation controller \(navc) has a delegate of \(navc.delegate). "
				+ "It should be nil")
            navc.delegate = self
        }
    }
    
    
    
    private func updateStatLabel()
	{
        if let button = statButton {
            var statButtonText = "None"
            if let stat = dieRoll.stat {
                statButtonText = "\(stat.name): \(stat.value)"
            }
            statButton.setTitle(statButtonText, forState: .Normal)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
        if segue.identifier == "ShowDieRollResult" {
            var dieRollResultViewController = segue.destinationViewController as! DieRollResultViewController
            rollTheDieAndShowResultsInViewController(dieRollResultViewController)
        }
        else if segue.identifier == "PushStatSelect" {
            var statSelectViewController = segue.destinationViewController as! StatSelectViewController
            statSelectViewController.selectedStat = dieRoll.stat?.name ?? "No name"
            statSelectViewController.selectionChangedCallback = { newStatName, oldStatName in
                self.statNameChanged(newStatName)
                self.updateStatLabel()
            }
        }
    }
    
	func statNameChanged(newStatName: String?)
	{
		var statInfo: DieRoll.StatInfo? = nil
		// Find the stat that name represents, and select it as dieRoll.stat.
		if let newName = newStatName,
			statValue = charSheet.statValueForName(newName) {
				statInfo = (newName, statValue)
		}
		dieRoll.stat = statInfo
	}

    func rollTheDieAndShowResultsInViewController(dieRollResultViewController: DieRollResultViewController)
	{
        dieRoll.adds = addsTextField.text.toInt() ?? 0
        dieRoll.extraD4s = Int16(extraDiceTextField.text.toInt() ?? 0)
        
        dieRoll.roll()
        dieRollResultViewController.dieRoll = dieRoll
        
        // Add the option to tick the skill if there is only one selected.
        assert(self.addTickToSkillCallback != nil)
        if dieRoll.skills.count == 1 {
            if let callback = addTickToSkillCallback {
                dieRollResultViewController.addTickAction = { callback(skill: self.dieRoll.skills[0]) }
            }
        }
        
        dieRollResultViewController.dismissCallback = self.dismissCallback
    }
}

    // MARK: - Navigation Controller Delegate

extension DieRollViewController: UINavigationControllerDelegate
{
	func navigationController(navigationController: UINavigationController,
		willShowViewController      viewController: UIViewController,
		animated                                  : Bool)
	{
		// If this controller is being shown because the select skill view controller has just been closed,
		// then add the skill it has found.
		if viewController == self {
			if let selectedSkill = skillSelectController?.selectedSkill {

				dieRoll.skills = dieRoll.skills + [selectedSkill]

				if let skillName = selectedSkill.name {
					dieRoll.specialties[skillName] = skillSelectController?.selectedSpecialty
				}
				skillsTable.reloadData()
			}
			// Then release the skill select controller. We will create a new one next time we want to edit a skill.
			skillSelectController = nil
		}
	}
}

    //MARK: - Table View

extension DieRollViewController: UITableViewDataSource
{

    func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
    
    
    
    func tableView(         tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return dieRoll.skills.count
    }
    
    

	func tableView(           tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath ) -> UITableViewCell
	{
		let CELL_ID = "PWDieRollView_Cell"

		let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) as? UITableViewCell
			?? UITableViewCell(style: .Value1, reuseIdentifier:CELL_ID)

		let skill = dieRoll.skills.objectAtIndex(indexPath.row)
		cell.textLabel?.text = skill.name
		if let
			skillName = skill.name,
			spec = dieRoll.specialties[skillName],
			l = cell.detailTextLabel {
				l.text = spec.name
		}
		return cell
	}


    func tableView(           tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        assert(tableView == skillsTable && editingStyle == .Delete)
        if(tableView == skillsTable && editingStyle == .Delete) {
            let skill = dieRoll.skills[indexPath.row]
            if let skillName = skill.name {
                dieRoll.specialties[skillName] = nil
            }
            dieRoll.skills.removeObjectAtIndex(indexPath.row)
            skillsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(             tableView: UITableView,
		didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
        assert(skillSelectController == nil,
			"Table View select. Skill select controller is \(skillSelectController), should be nil")
        skillSelectController = SkillSelectController.skillSelectControllerFromNib()
        
        let controller = skillSelectController!
        // Set the skill shown in the table as the currently-selected skill.
        controller.selectedSkill = dieRoll.skills[indexPath.row]
        controller.selectedSpecialty = dieRoll.specialties[controller.selectedSkill?.name ?? ""]
        
        // The list of skills to pick is all the skills not already picked, except for the one we are currently editing.
        // Otherwise the user can't go back without making changes.
        let skillsToPick: [Skill] = (charSheet!.skills.array)
			.map { $0 as! Skill }
			.filter { $0 == controller.selectedSkill || !self.dieRoll.skills.contains($0) }
        controller.skillsToPick  = MutableOrderedSet<Skill>(array: skillsToPick)
		navigationController?.pushViewController(controller, animated: true)
    }
}

