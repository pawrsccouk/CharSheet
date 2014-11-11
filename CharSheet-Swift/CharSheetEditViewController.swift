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

class CharSheetEditViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

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
            
            let addSkillNavigationController = segue.destinationViewController as UINavigationController
            let editSkillViewController = addSkillNavigationController.childViewControllers[0] as EditSkillViewController
            
            let newSkill = charSheet.appendSkill()
            editSkillViewController.skill = newSkill
            editSkillViewController.completionCallback = { self.skillsTableView.reloadData() }
        }
    }
    
    // MARK: - Private helper functions
    
    // Set the value of the stat into the text field and into the numeric value of the associated stepper.
    private func setValue(value: Int16, inTextField textField: UITextField?) {
        if let tf = textField {
            if let stepper = stepperForTextField(tf) {
                stepper.value  = Double(value)
                tf.text = value.description
            }
        }
    }

    private func configureView() {
        let name = charSheet.name ?? ""
        navigationItem.title  = "Edit - \(name)"
        if let t = charNameTextField   { t.text   = charSheet.name   }
        if let t = gameTextField       { t.text   = charSheet.game   }
        if let t = playerTextField     { t.text   = charSheet.player }
        if let t = levelTextField      { t.text   = charSheet.level.description      }
        if let t = levelStepper        { t.value   = Double(charSheet.level)         }
        if let t = experienceTextField { t.text   = charSheet.experience.description }
        
        // Copy the stats values to the text fields.
        setValue(charSheet.strength.value    , inTextField:strengthTextField    )
        setValue(charSheet.dexterity.value   , inTextField:dexterityTextField   )
        setValue(charSheet.constitution.value, inTextField:constitutionTextField)
        setValue(charSheet.speed.value       , inTextField:speedTextField       )
        setValue(charSheet.charisma.value    , inTextField:charismaTextField    )
        setValue(charSheet.perception.value  , inTextField:perceptionTextField  )
        setValue(charSheet.intelligence.value, inTextField:intelligenceTextField)
        setValue(charSheet.luck.value        , inTextField:luckTextField        )
        
        // Skills are handled by the view delegate.
        if let tableView = skillsTableView {
            tableView.reloadData()
            tableView.setEditing(true, animated:false)
        }
    }

    private func saveStat(stat: Stat, inTextField textField: UITextField) {
        let val = Int16(textField.text.toInt() ?? 0)
        if val > 0 {
            stat.value = val
        }
    }
    
    private func configureData() {
        charSheet.name   = charNameTextField.text
        charSheet.game   = gameTextField.text
        charSheet.player = playerTextField.text
        charSheet.experience = Int32(experienceTextField.text.toInt() ?? 0)
        charSheet.level      = Int16(levelTextField.text.toInt() ?? 0)
        
        //charSheet.logStatsWithContext("Edit-ConfigureData-Before")
        saveStat(charSheet.strength    , inTextField: strengthTextField    )
        saveStat(charSheet.dexterity   , inTextField: dexterityTextField   )
        saveStat(charSheet.constitution, inTextField: constitutionTextField)
        saveStat(charSheet.speed       , inTextField: speedTextField       )
        saveStat(charSheet.charisma    , inTextField: charismaTextField    )
        saveStat(charSheet.perception  , inTextField: perceptionTextField  )
        saveStat(charSheet.intelligence, inTextField: intelligenceTextField)
        saveStat(charSheet.luck        , inTextField: luckTextField        )
        //charSheet.logStatsWithContext("Edit-ConfigureData-After")
    }
    
    
    
    private func textFieldForStepper(stepper: UIStepper) -> UITextField? {
        assert(stepper.tag < 10)
        return view.viewWithTag(stepper.tag + 10) as? UITextField
    }
    
    private func stepperForTextField(textField: UITextField) -> UIStepper? {
        assert(textField.tag > 10)
        return view.viewWithTag(textField.tag - 10) as? UIStepper
    }
    
    // MARK: - Table View Data Source
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID, forIndexPath: indexPath) as EditSkillCell
        //assert(cell != nil, "No cell for edit skill identifier \(CELL_ID).")   // Must always be valid as we've registered the class already.
        
        let skill = charSheet.skills[indexPath.row] as Skill
        cell.name = skill.name!
        cell.value = skill.value
        cell.specialties = skill.specialtiesAsString
        cell.editingAccessoryType = .DetailDisclosureButton
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charSheet.skills.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    // MARK: - Table View Delegate

    func tableView(tableView: UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            charSheet.removeSkillAtIndex(indexPath.row)
            // Update the table view to match the new model.
            skillsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // Table view has already moved the row, so we just need to update the model.
        charSheet.skills.moveObjectsAtIndexes(NSIndexSet(index: sourceIndexPath.row), toIndex:destinationIndexPath.row)
    }
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        let editStoryboard = UIStoryboard(name: "Edit", bundle: NSBundle.mainBundle())
        let editSkillNavigationController = editStoryboard.instantiateViewControllerWithIdentifier("EditSkillNavigationController") as UINavigationController
        
        //    NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"PWEditSkillView" owner:self options:nil];
        //    UINavigationController *editSkillNavigationController = nibObjects[0];
        let editSkillViewController = editSkillNavigationController.childViewControllers[0] as EditSkillViewController
        //wireUpEditSkillController:editSkillViewController withSkill:[self.charSheet.skills objectAtIndex:indexPath.row]];
        editSkillViewController.skill = charSheet.skills[indexPath.row] as Skill
        editSkillViewController.completionCallback = { self.skillsTableView.reloadData() }
        editSkillNavigationController.modalPresentationStyle = .FormSheet
        editSkillNavigationController.modalTransitionStyle = .CrossDissolve
        if let navc = navigationController {
            navc.presentViewController(editSkillNavigationController, animated: true, completion:nil)
        }
    }
    
}
