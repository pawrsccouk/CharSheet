//
//  PWEditNotesViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import UIKit
import CoreData

class EditNotesViewController : UIViewController {
    
    @IBOutlet weak var notesTextView: UITextView!
    
    var charSheet: CharSheet! {
        didSet {
            if charSheet != oldValue {
                if let v = notesTextView {
                    v.text = charSheet.notes
                }
            }
        }
    }
    
    var managedObjectContext: NSManagedObjectContext!
    
    var dismissCallback: VoidCallback?
    
    // These are used for keyboard support.
    
    // View currently being edited (i.e. the one the user needs to see).
    private var activeView: UITextView?
    
    // Original frame for the view, so we can restore it once editing is complete.
    private var oldViewFrame = CGRectZero
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        if let c = charSheet {
            notesTextView.text = c.notes
        }
        registerForKeyboardNotifications()
    }
    

    
    @IBAction func editDone(sender: AnyObject?) {
    
        saveChanges()
        
        if let callback = dismissCallback {
            callback()
        }
        if let pc = presentingViewController {
            pc.dismissViewControllerAnimated(true, completion:nil)
        }
    }


    


    func saveChanges() {
        self.charSheet.notes = notesTextView.text;
    }
    
    
    
    // These  methods  are needed to support the text field scrolling into view when the keyboard is selected.
    // This requires the fields to be embedded in a scroll view.
    // MARK: - Keyboard support
    
    
    
	func keyboardWasShown(aNotification: NSNotification) {
		if let userInfo = aNotification.userInfo
			, keyboardStartFrame = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue {
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




    func keyboardWillBeHidden(aNotification: NSNotification) {
        if activeView == notesTextView {
            activeView!.frame = oldViewFrame
            oldViewFrame = CGRectZero
        }
    }
    
    
    
    
    func textViewDidBeginEditing(textView: UITextView) {
        activeView = textView
    }
    
    
    
    
    func textViewDidEndEditing(textView: UITextView) {
        activeView = nil
    }
    
    
    
    
    private func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWasShown:"    , name:UIKeyboardDidShowNotification , object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillBeHidden:", name:UIKeyboardWillHideNotification, object:nil)
        
    }
    
}

