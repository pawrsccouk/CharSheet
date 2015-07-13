//
//  PWEditSpecialtyViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2012.

import UIKit

/// View controller for editing a single specialty object, which must be set before the view is displayed.
class EditSpecialtyViewController : UIViewController
{
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var nameField: UITextField!
	@IBOutlet var stepperAssistants: [StepperAssistant]!

	/// The specialty we are editing.
    var specialty: Specialty!

	/// Update the view with details gathered from *specialty*.
    private func configureView()
	{
        nameField.text    = specialty.name
		valueField.text   = specialty.value.description
		for s in stepperAssistants {
			s.updateStepperFromTextField()
		}
    }
    
	override func viewWillAppear(animated: Bool)
	{
        super.viewWillAppear(animated)
        configureView()
    }
    
    
    override func viewDidDisappear(animated: Bool)
	{
        var spec = specialty
        spec.name = nameField.text
        spec.value = Int16(valueField.text.toInt() ?? 0)
        super.viewDidDisappear(animated)
    }
}

