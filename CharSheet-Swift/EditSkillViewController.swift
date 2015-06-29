//
//  PWEditSkillViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2012.
//
//

import CoreData
import UIKit

class EditSkillViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Interface Builder
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var ticksTextField: UITextField!
    @IBOutlet weak var valueStepper: UIStepper!
    @IBOutlet weak var ticksStepper: UIStepper!
    @IBOutlet weak var specialtiesTableView: UITableView!
    
    
    @IBAction func stepperChanged(sender: AnyObject?) {
        if let s = sender as? NSObject {
            if      s == valueStepper { valueTextField.text = Int(valueStepper.value).description }
            else if s == ticksStepper { ticksTextField.text = Int(ticksStepper.value).description }
        } else {
            assert(false, "EditSkillViewController.stepperChanged: No sender")
        }
    }
    
    @IBAction func numericValueChanged(sender: AnyObject?) {
        if let s = sender as? NSObject {
            if      s == valueTextField { valueStepper.value = Double(valueTextField.text.toInt() ?? 0) }
            else if s == ticksTextField { ticksStepper.value = Double(ticksTextField.text.toInt() ?? 0) }
        }
        else {
            assert(false, "EditSkillViewController.numericValueChanged: No sender")
        }
    }
    
    @IBAction func done(sender: AnyObject?) {
        if let pvc = presentingViewController {
            pvc.dismissViewControllerAnimated(true, completion: completionCallback)
        }
    }
    
    // Public API
    
    var skill: Skill! {
        didSet {
            configureView()
        }
    }
    
    var completionCallback: VoidCallback?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        specialtiesTableView.editing = true
        configureView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let s = skill {
            s.name = nameTextField.text;
            s.value = Int16(valueTextField.text.toInt() ?? 0)
            s.ticks = Int16(ticksTextField.text.toInt() ?? 0)
        }
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Called when the specialties view is removed, so update the data with any new values in there.
        specialtiesTableView.reloadData()
    }
    
    private func configureView() {
        // Ensure this is not called until the Interface Builder items have been set.
        if nameTextField == nil { return }
        
        navigationItem.title = skill.name as? String ?? "New skill"
        nameTextField.text   = skill.name as? String ?? ""
        valueTextField.text  = skill.value.description
        ticksTextField.text  = skill.ticks.description
        valueStepper.value   = Double(skill.value)
        ticksStepper.value   = Double(skill.ticks)
        specialtiesTableView.reloadData()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "PushEditSpecialty" {
            let newSpecialty = self.skill.appendSpecialty()
            let editSpecialtyViewController = segue.destinationViewController as! EditSpecialtyViewController
            editSpecialtyViewController.specialty = newSpecialty
        }
    }
    
    
    
    // MARK: - Table View Data
    
    private let CELL_ID = "PWEditSkillViewController_Cell"

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.skill.specialties.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        let cell = specialtiesTableView.dequeueReusableCellWithIdentifier(CELL_ID) as? UITableViewCell ?? UITableViewCell(style: .Value1, reuseIdentifier: CELL_ID)
        let spec = skill.specialties.objectAtIndex(indexPath.row) as! Specialty
        if let l = cell.textLabel {
            l.text = spec.name as? String
        }
        if let label = cell.detailTextLabel {
            label.text = spec.value.description
        }
        cell.editingAccessoryType = .DetailDisclosureButton
        return cell
    }

// MARK: - Table View Delegate


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            skill.removeSpecialtyAtIndex(indexPath.row)
            specialtiesTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        skill.moveSpecialtyFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        let editStoryboard = UIStoryboard(name: "Edit", bundle: NSBundle.mainBundle())
		let cntrId = "EditSpecialtyViewController"
        let esvc = editStoryboard.instantiateViewControllerWithIdentifier(cntrId) as! EditSpecialtyViewController
        esvc.specialty = skill.specialties[indexPath.row] as! Specialty
        if let navc = navigationController {
            navc.pushViewController(esvc, animated: true)
        }
    }



}


