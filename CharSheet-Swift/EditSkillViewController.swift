//
//  PWEditSkillViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2012.

import CoreData
import UIKit

/// This controller manages a view which displays the Skill object in a series of text fields and allows the user to update them.
///
/// This view is usually displayed as a pop-up when you select 'new skill' or edit a skill in the skills table.

class EditSkillViewController : UIViewController
{
    // MARK: Interface Builder
	
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var ticksTextField: UITextField!
    @IBOutlet weak var specialtiesTableView: UITableView!
	@IBOutlet var stepperAssistants: [StepperAssistant]!

    @IBAction func done(sender: AnyObject?)
	{
		// Update the 'order' field in the specialties to match the order given in the set.
		var i: Int16 = 0
		for s in skill.specialties.array.map({ $0 as! Specialty }) {
			s.order = i
			i += 1
		}
		presentingViewController?.dismissViewControllerAnimated(true, completion: completionCallback)
    }
    
    // MARK: Public API

	/// The skill to edit. Must be set before the view is displayed.
    var skill: Skill!

	/// Callback triggered once the view controller has been dismissed with the *done* action.
    var completionCallback: VoidCallback?

	// MARK: Overrides
    
    override func viewWillAppear(animated: Bool)
	{
        super.viewWillAppear(animated)
        specialtiesTableView.editing = true
        configureView()
    }
    
    override func viewDidDisappear(animated: Bool)
	{
        if let s = skill {
            s.name = nameTextField.text;
            s.value = Int16(Int(valueTextField.text ?? "") ?? 0)
            s.ticks = Int16(Int(ticksTextField.text ?? "") ?? 0)
        }
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool)
	{
        super.viewDidAppear(animated)
        // Called when the specialties view is removed, so update the data with any new values in there.
        specialtiesTableView.reloadData()
    }

	// MARK: Private methods

	/// Update the controls in the view from the values in *skill*.
    private func configureView()
	{
        navigationItem.title = skill.name ?? "New skill"
        nameTextField.text   = skill.name ?? ""
        valueTextField.text  = "\(skill.value)"
        ticksTextField.text  = "\(skill.ticks)"
		for s in stepperAssistants {
			s.updateStepperFromTextField()
		}
        specialtiesTableView.reloadData()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
        if segue.identifier == "PushEditSpecialty" {
            let newSpecialty = skill.appendSpecialty()
            let editSpecialtyViewController = segue.destinationViewController as! EditSpecialtyViewController
            editSpecialtyViewController.specialty = newSpecialty
        }
    }
}
    
// MARK: - Table View Data

extension EditSkillViewController: UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
        return 1
    }
    
    func tableView(         tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return self.skill.specialties.count
    }
    
    func tableView(           tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let CELL_ID = "PWEditSkillViewController_Cell"

        let cell = specialtiesTableView.dequeueReusableCellWithIdentifier(CELL_ID)
			?? UITableViewCell(style: .Value1, reuseIdentifier: CELL_ID)
        let spec = skill.specialties.objectAtIndex(indexPath.row) as! Specialty
        if let l = cell.textLabel {
            l.text = spec.name
        }
        if let label = cell.detailTextLabel {
            label.text = spec.value.description
        }
        cell.editingAccessoryType = .DetailDisclosureButton
        return cell
    }
}

// MARK: - Table View Delegate

extension EditSkillViewController: UITableViewDelegate
{
    func tableView(           tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath     indexPath: NSIndexPath)
	{
        if editingStyle == .Delete {
            skill.removeSpecialtyAtIndex(indexPath.row)
            specialtiesTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(              tableView: UITableView,
		moveRowAtIndexPath sourceIndexPath: NSIndexPath,
		toIndexPath   destinationIndexPath: NSIndexPath)
	{
        skill.moveSpecialtyFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    
    func tableView(                              tableView: UITableView,
		accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
	{
        let editStoryboard = UIStoryboard(name: "Edit", bundle: NSBundle.mainBundle())
		let cntrId = "EditSpecialtyViewController"
        let esvc = editStoryboard.instantiateViewControllerWithIdentifier(cntrId) as! EditSpecialtyViewController
        esvc.specialty = skill.specialties[indexPath.row] as! Specialty
		navigationController?.pushViewController(esvc, animated: true)
    }
}


