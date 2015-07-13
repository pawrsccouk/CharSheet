//
//  StepperViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 12/07/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import UIKit

/// This handles the integration of a UIStepperView and a UITextField
/// 
/// Create one in Interface Builder and connect up the outlets and actions.
/// I usually create an array of them (if I have more than one stepper/textfield per page)
/// with code like:
///    @IBOutlet var stepperAssistants: [StepperAssistant]!
/// This will appear in Interface Builder and I can add the assistants in there.
/// 
/// You'll need this as you need to set the starting value for the stepper to match the text field, e.g.
/// with:
///    for s in stepperAssistants { s.updateStepperFromTextField() }
///
class StepperAssistant: NSObject
{
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var textField: UITextField!

	/// Called when the stepper's value has changed. Update the text field to match.
	@IBAction func stepperValueChanged(sender: UIStepper?)
	{
		assert(sender == stepper, "Unknown sender \(sender) for stepperValueChanged")
		updateTextFieldFromStepper()
	}

	/// Called when the text field's value has changed. Update the stepper to match.
	@IBAction func textFieldValueChanged(sender: UITextField?)
	{
		assert(sender == textField, "Unknown sender \(sender) for textFieldValueChanged.")
		updateStepperFromTextField()
	}

	/// Set the value of stepper to the value of textField.text
	/// or to stepper.minimumValue if textField.text is not parseable.
	func updateStepperFromTextField()
	{
		if let txt = textField.text, val = txt.toInt() {
			stepper.value = Double(val)
		} else {
			stepper.value = stepper.minimumValue
		}
	}

	/// Set the value of textField.text to a string representation of stepper's value.
	func updateTextFieldFromStepper()
	{
		textField.text = "\(Int(stepper.value))"
	}
}
