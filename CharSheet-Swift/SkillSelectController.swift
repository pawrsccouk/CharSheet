//
//  PWListSelectController.m
//  CharSheet
//
//  Created by Patrick Wallace on 25/11/2012.
//
//

import UIKit
import CoreData

class SkillSelectController : UIViewController
{
    // MARK: Interface Builder
    
    @IBOutlet weak var skillPicker: UIPickerView!
    @IBOutlet weak var specialtyPicker: UIPickerView!
    
    // MARK: Properties

	/// The currently selected skill
    var selectedSkill: Skill?

	/// The currently selected specialty
    var selectedSpecialty: Specialty?
    
	/// Set of the possible skills we can pick.
    var skillsToPick = MutableOrderedSet<Skill>()

	/// Type of a callback function which passes in the selected skill and specialty.
    typealias SelectionChanged = (selectedSkill: Skill, selectedSpecialty: Specialty) -> Void

	/// Callback if the selection changes.
    var  selectionChangedBlock: SelectionChanged?


	// MARK: Factory Functions

	/// Factory function to get a new skill select controller from the Nib file.
	/// Use in place of an initializer.
	///
	/// :returns: A new SkillSelectController.
    class func skillSelectControllerFromNib() -> SkillSelectController
	{
        let allObjects = NSBundle.mainBundle().loadNibNamed("SkillSelectView", owner: self, options: nil)
        return allObjects[0] as! SkillSelectController
    }


	// MARK: Overrides

    override func viewWillAppear(animated: Bool)
	{
        super.viewWillAppear(animated)
        
        // If we have been given a selected skill or specialty, then set the pickers to show those values by default.
		// Note that both picker rows are off by 1 due to having the "None" as the first entry.
        if let skill = selectedSkill {
            var indexOfObject = skillsToPick.indexOfObject(skill)
            assert(indexOfObject != NSNotFound, "Skill \(skill) is not in the list of skills to pick \(skillsToPick)")
            skillPicker.selectRow(indexOfObject + 1, inComponent: 0, animated: false)
        
            if let spec = selectedSpecialty {
                let indexOfObject = skill.specialties.indexOfObject(spec)
                assert(indexOfObject != NSNotFound,
					"Specialty \(spec) is not in the list of specialties \(skill.specialties) for skill \(skill)")
				specialtyPicker.selectRow(indexOfObject + 1, inComponent: 0, animated: false)
            }
            else {
                specialtyPicker.selectRow(0, inComponent: 0, animated: false)   // The "None" row for specialties.
            }
		} else {
			skillPicker.selectRow(0, inComponent: 0, animated: false) // The "None" row for skills.
		}
    }
}

//MARK: - Picker View Data Source

extension SkillSelectController: UIPickerViewDataSource
{
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
	{
        return 1
    }

    func pickerView(           pickerView: UIPickerView,
		numberOfRowsInComponent component: NSInteger) -> Int
    {
        assert(pickerView == skillPicker || pickerView == specialtyPicker, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
		// Both pickers have an extra row "None" in their list.
		switch pickerView {
		case skillPicker:     return skillsToPick.count + 1
		case specialtyPicker: return (selectedSkill?.specialties?.count ?? 0) + 1
		default: return 0
		}
    }
}

//MARK: - Picker View Delegate

extension SkillSelectController: UIPickerViewDelegate
{
    func pickerView(pickerView: UIPickerView,
		titleForRow        row: Int,
		forComponent component: Int) -> String
	{
        assert(component == 0, "Component ID \(component) is not 0")

		var text = ""
		switch pickerView {

		case skillPicker:
            // First row should always be "None" and other rows follow in order after that.
			return (row == 0) ? "None" : (self.skillsToPick[row - 1].name ?? "No name")

		case specialtyPicker:
            // First row should always be "None" and other rows follow in order after that.
            if row == 0 { return "None" }
            if let specialty = selectedSkill?.specialties[row - 1] as? Specialty {
                text = specialty.name ?? "No name"
            }

		default:
			assert(false, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
		}
		return text
	}

    
    func pickerView(pickerView: UIPickerView,
		didSelectRow       row: Int,
		inComponent  component: Int)
	{
        assert(component == 0, "Component ID \(component) is not 0")
		switch pickerView {
		case skillPicker:
			selectedSkill = (row == 0) ? nil : self.skillsToPick[row - 1]
            self.selectedSpecialty = nil
            specialtyPicker.reloadAllComponents()   // Reload the specialty picker now the skill has changed.

		case specialtyPicker:     // First row "None" equates to a nil selected specialty.
            selectedSpecialty = (row == 0) ? nil : self.selectedSkill?.specialties[row - 1] as? Specialty

		default:
			assert(false, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
		}
    }
}

