////
////  PWCharSheetEditViewController.m
////  CharSheet
////
////  Created by Patrick Wallace on 20/11/2012.
////
////

import UIKit
import CoreData

private let CELL_ID = "CharSheetEditSkill_Cell"

class CharSheetEditViewController : UIViewController {

    // MARK: - Interface Builder
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
    @IBOutlet weak var levelStepper         : UIStepper!
    
    
    @IBAction func editDone(sender: AnyObject?) {
        
        configureData()
        
        if let callback = dismissCallback {
            callback()
        }
        if let pvc = presentingViewController {
            pvc.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    @IBAction func addSkill(sender: AnyObject?) {
        charSheet.appendSkill()
        skillsTableView.reloadData()
    }
    
    
    @IBAction func stepperValueChanged(sender: AnyObject?) {
        if let stepper = sender as? UIStepper {
            if let textField = textFieldForStepper(stepper) {
                textField.text = Int(stepper.value).description
            }
        }
    }
    
    @IBAction func textFieldValueChanged(sender: AnyObject?) {
        if let textField = sender as? UITextField {
            if let stepper = stepperForTextField(textField) {
                stepper.value = Double(textField.text.toInt() ?? 0)
            }
        }
    }
    
    @IBAction func levelStepperValueChanged(sender: AnyObject?) {
        if let stepper = sender as? UIStepper {
            levelTextField.text = Int(stepper.value).description
        }
    }
    
    @IBAction func levelTextFieldValueChanged(sender: AnyObject?) {
        if let textField = sender as? UITextField {
            levelStepper.value = Double(textField.text.toInt() ?? 0)
        }
    }
    
   
    // MARK: - Public API
    
    var managedObjectContext: NSManagedObjectContext!
    
    var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                configureView()
            }
        }
    }
    
    var dismissCallback: VoidCallback?
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //configureView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //configureView()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSkillPopup" {
            
            // Connect the Edit Skill view controller to the skill it is editing.
            let asnc = segue.destinationViewController as! UINavigationController
            let esc = asnc.childViewControllers[0] as! EditSkillViewController
            esc.skill = charSheet.appendSkill()
            esc.completionCallback = { self.skillsTableView.reloadData() }
        }
    }
    
    // MARK: - Private helper functions
    
	/// Copies data in the model into the various UI controls.
    private func configureView()
	{
		// Set the value of the stat into the text field and into the numeric value of the associated stepper.
		func setValue(value: Int16, inTextField textField: UITextField?)
		{
			if let tf = textField, stepper = stepperForTextField(tf) {
				stepper.value = Double(value)
				tf.text = value.description
			}
		}

		let name = charSheet.name ?? ""
        navigationItem.title      = "Edit - \(name)"
        charNameTextField?.text   = charSheet.name
        gameTextField?.text       = charSheet.game
        playerTextField?.text     = charSheet.player
        levelTextField?.text      = charSheet.level.description
        levelStepper?.value       = Double(charSheet.level)
        experienceTextField?.text = charSheet.experience.description
        
        // Copy the stats values to the text fields.
        setValue(charSheet.strength    , inTextField:strengthTextField    )
        setValue(charSheet.dexterity   , inTextField:dexterityTextField   )
        setValue(charSheet.constitution, inTextField:constitutionTextField)
        setValue(charSheet.speed       , inTextField:speedTextField       )
        setValue(charSheet.charisma    , inTextField:charismaTextField    )
        setValue(charSheet.perception  , inTextField:perceptionTextField  )
        setValue(charSheet.intelligence, inTextField:intelligenceTextField)
        setValue(charSheet.luck        , inTextField:luckTextField        )
        
        // Skills are handled by the view delegate.
        if let tableView = skillsTableView {
            tableView.reloadData()
            tableView.setEditing(true, animated:false)
        }
    }

	/// Copies the data in the various UI controls back into the model.
    private func configureData()
	{
        charSheet.name   = charNameTextField.text
        charSheet.game   = gameTextField.text
        charSheet.player = playerTextField.text
        charSheet.experience = Int32(experienceTextField.text.toInt() ?? 0)
        charSheet.level      = Int16(levelTextField.text.toInt() ?? 0)
        
        charSheet.strength     = Int16(strengthTextField.text.toInt()     ?? 0)
        charSheet.dexterity    = Int16(dexterityTextField.text.toInt()    ?? 0)
        charSheet.constitution = Int16(constitutionTextField.text.toInt() ?? 0)
        charSheet.speed        = Int16(speedTextField.text.toInt()        ?? 0)
        charSheet.charisma     = Int16(charismaTextField.text.toInt()     ?? 0)
        charSheet.perception   = Int16(perceptionTextField.text.toInt()   ?? 0)
        charSheet.intelligence = Int16(intelligenceTextField.text.toInt() ?? 0)
        charSheet.luck         = Int16(luckTextField.text.toInt()         ?? 0)
    }
    
    
    
    private func textFieldForStepper(stepper: UIStepper) -> UITextField?
	{
        assert(stepper.tag < 10)
        return view.viewWithTag(stepper.tag + 10) as? UITextField
    }
    
    private func stepperForTextField(textField: UITextField) -> UIStepper?
	{
        assert(textField.tag > 10)
        return view.viewWithTag(textField.tag - 10) as? UIStepper
    }
}

    // MARK: - Table View Data Source
extension CharSheetEditViewController: UITableViewDataSource
{
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID, forIndexPath: indexPath) as! EditSkillCell
        let skill = charSheet.skills[indexPath.row] as! Skill
        cell.name = skill.name ?? "No name"
        cell.value = skill.value
        cell.specialties = skill.specialtiesAsString
        cell.editingAccessoryType = .DetailDisclosureButton
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return charSheet.skills.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
}
    
    // MARK: - Table View Delegate

extension CharSheetEditViewController: UITableViewDelegate
{
    func tableView(           tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        if editingStyle == .Delete {
            charSheet.removeSkillAtIndex(indexPath.row)
            skillsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(              tableView: UITableView,
		moveRowAtIndexPath sourceIndexPath: NSIndexPath,
		toIndexPath   destinationIndexPath: NSIndexPath)
	{
        // Table view has already moved the row, so we just need to update the model.
        charSheet.skills.moveObjectsAtIndexes(NSIndexSet(index: sourceIndexPath.row), toIndex:destinationIndexPath.row)
    }
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
	{
        let esb = UIStoryboard(name: "Edit", bundle: NSBundle.mainBundle())
		let navId = "EditSkillNavigationController"
        let esnc = esb.instantiateViewControllerWithIdentifier(navId) as! UINavigationController
        
        let editSkillViewController = esnc.childViewControllers[0] as! EditSkillViewController
        editSkillViewController.skill = charSheet.skills[indexPath.row] as! Skill
        editSkillViewController.completionCallback = { self.skillsTableView.reloadData() }
        esnc.modalPresentationStyle = .FormSheet
        esnc.modalTransitionStyle = .CrossDissolve
		navigationController?.presentViewController(esnc, animated: true, completion:nil)
    }
}
