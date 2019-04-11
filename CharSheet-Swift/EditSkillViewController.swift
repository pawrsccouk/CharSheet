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

    @IBAction func done(_ sender: AnyObject?)
	{
		// Update the 'order' field in the specialties to match the order given in the set.
		var i: Int16 = 0
		for s in skill.specialties.array.map({ $0 as! Specialty }) {
			s.order = i
			i += 1
		}
		presentingViewController?.dismiss(animated: true, completion: completionCallback)
    }
    
    // MARK: Public API

	/// The skill to edit. Must be set before the view is displayed.
    var skill: Skill!

	/// Callback triggered once the view controller has been dismissed with the *done* action.
    var completionCallback: (() -> Void)?

	// MARK: Overrides
    
    override func viewWillAppear(_ animated: Bool)
	{
        super.viewWillAppear(animated)
        specialtiesTableView.isEditing = true
        configureView()
    }
    
    override func viewDidDisappear(_ animated: Bool)
	{
        if let s = skill {
            s.name = nameTextField.text;
            s.value = Int16(Int(valueTextField.text ?? "") ?? 0)
            s.ticks = Int16(Int(ticksTextField.text ?? "") ?? 0)
        }
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool)
	{
        super.viewDidAppear(animated)
        // Called when the specialties view is removed, so update the data with any new values in there.
        specialtiesTableView.reloadData()
    }

	// MARK: Private methods

	/// Update the controls in the view from the values in *skill*.
    fileprivate func configureView()
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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
        if segue.identifier == "PushEditSpecialty" {
            let newSpecialty = skill.addSpecialty()
            let editSpecialtyViewController = segue.destination as! EditSpecialtyViewController
            editSpecialtyViewController.specialty = newSpecialty
        }
    }
}
    
// MARK: - Table View Data

extension EditSkillViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }
    
    func tableView(         _ tableView: UITableView,
		numberOfRowsInSection section: Int) -> Int
	{
        return self.skill.specialties.count
    }
    
    func tableView(           _ tableView: UITableView,
		cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let CELL_ID = "PWEditSkillViewController_Cell"

        let cell = specialtiesTableView.dequeueReusableCell(withIdentifier: CELL_ID)
			?? UITableViewCell(style: .value1, reuseIdentifier: CELL_ID)
        let spec = skill.specialties.object(at: indexPath.row) as! Specialty
        if let l = cell.textLabel {
            l.text = spec.name
        }
        if let label = cell.detailTextLabel {
            label.text = spec.value.description
        }
        cell.editingAccessoryType = .detailDisclosureButton
        return cell
    }
}

// MARK: - Table View Delegate

extension EditSkillViewController: UITableViewDelegate
{
    func tableView(           _ tableView: UITableView,
							  commit editingStyle: UITableViewCell.EditingStyle,
		forRowAt     indexPath: IndexPath)
	{
        if editingStyle == .delete {
            skill.removeSpecialtyAtIndex(indexPath.row)
            specialtiesTableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView,
		moveRowAt sourceIndexPath: IndexPath,
		to   destinationIndexPath: IndexPath)
	{
        skill.moveSpecialtyFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    
    func tableView(_ tableView: UITableView,
		accessoryButtonTappedForRowWith indexPath: IndexPath)
	{
        let editStoryboard = UIStoryboard(name: "Edit", bundle: Bundle.main)
		let cntrId = "EditSpecialtyViewController"
        let esvc = editStoryboard.instantiateViewController(withIdentifier: cntrId) as! EditSpecialtyViewController
		esvc.specialty = (skill.specialties[indexPath.row] as! Specialty)
		navigationController?.pushViewController(esvc, animated: true)
    }
}


