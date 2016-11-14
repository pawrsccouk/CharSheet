//
//  PWEditSpecialtyViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2012.

import UIKit

/// View controller for editing a single specialty object.
///
/// The Specialty must be set before the view is displayed.
class EditSpecialtyViewController : UIViewController
{
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var nameField: UITextField!
	@IBOutlet var stepperAssistants: [StepperAssistant]!

	/// The specialty we are editing.
    var specialty: Specialty!

	/// Update the view with details gathered from *specialty*.
    fileprivate func configureView()
	{
        nameField.text    = specialty.name
		valueField.text   = specialty.value.description
		for s in stepperAssistants {
			s.updateStepperFromTextField()
		}
    }
    
	override func viewWillAppear(_ animated: Bool)
	{
        super.viewWillAppear(animated)
        configureView()
    }
    
    
    override func viewDidDisappear(_ animated: Bool)
	{
        let spec = specialty
        spec?.name = nameField.text
		if let s = valueField.text, let i = Int(s) {
        spec?.value = Int16(i)
		} else {
			spec?.value = 0
		}
        super.viewDidDisappear(animated)
    }
}

