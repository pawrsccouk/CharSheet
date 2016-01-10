//
//  PWEditNotesViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import UIKit
import CoreData

/// This view controller takes a CharSheet object and displays the 'notes' text in a big text field.
///
/// This also has support for resizing the view to fit the keyboard as this should be a full-screen text field.
class EditNotesViewController : CharSheetViewController
{
	// MARK: Interface Builder

    @IBOutlet weak var notesTextView: UITextView!
    
	@IBAction func editDone(sender: AnyObject?)
	{
        saveChanges()
		presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }

	// MARK: Overrides

    override func viewDidLoad()
	{
        super.viewDidLoad()
		registerForKeyboardNotifications()
    }
    
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		notesTextView.text = charSheet?.notes ?? ""
	}

	deinit
	{
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	// MARK: Methods

	/// Write the contents of the text field back into the model's 'text' property.
	/// This overwrites anything that was previously there.
	///
	/// This also posts a 'SaveChanges' notification.
    func saveChanges()
	{
        self.charSheet.notes = notesTextView.text;
		NSNotificationCenter.defaultCenter().postNotificationName("SaveChanges", object: nil)
    }
    

    // MARK: - Keyboard support

    // These  methods  are needed to support the text field scrolling into view when the keyboard is selected.
    // This requires the fields to be embedded in a scroll view.

	/// View currently being edited (i.e. the one the user needs to see).
    private var activeView: UITextView?
    
	/// Original frame for the view, so we can restore it once editing is complete.
    private var oldViewFrame = CGRectZero
   
    
	func keyboardWasShown(aNotification: NSNotification)
	{
		if let
			userInfo = aNotification.userInfo,
			keyboardStartFrame = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue
		{
			let kbSize = view.convertRect(keyboardStartFrame.CGRectValue(), fromView:nil).size

			// If active text view is hidden by keyboard, move it so it is visible
			if let superView = view.superview {
				var mainRect = superView.frame, fieldRect = mainRect
				fieldRect.size.height -= kbSize.height

				// Move the active text view above the keyboard, and change the height so it fills the screen space above it.
				// Take a copy so we can restore it when the keyboard disappears.
				if activeView == notesTextView, let av = activeView {
					oldViewFrame = av.frame
					av.frame = fieldRect
				}
			}
		}
	}




    func keyboardWillBeHidden(aNotification: NSNotification)
	{
        if activeView == notesTextView {
            activeView!.frame = oldViewFrame
            oldViewFrame = CGRectZero
        }
	}
    
    func textViewDidBeginEditing(textView: UITextView)
	{
        activeView = textView
    }

    
    func textViewDidEndEditing(textView: UITextView)
	{
        activeView = nil
    }

    
    private func registerForKeyboardNotifications()
	{
        NSNotificationCenter.defaultCenter()
			.addObserver(self,
				selector: "keyboardWasShown:"    ,
				name    : UIKeyboardDidShowNotification ,
				object  : nil)
		NSNotificationCenter.defaultCenter()
			.addObserver(self,
				selector: "keyboardWillBeHidden:",
				name    : UIKeyboardWillHideNotification,
				object  : nil)
    }
    
}

