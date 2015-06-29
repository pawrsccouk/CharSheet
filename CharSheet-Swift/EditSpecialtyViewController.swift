//
//  PWEditSpecialtyViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 21/11/2012.
//
//

import UIKit

//
class EditSpecialtyViewController : UIViewController {
    
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var stepperView: UIStepper!

    var specialty: Specialty! {
        didSet {
            if specialty != oldValue {
                configureView()
            }
        }
    }
    
    private func configureView() {
        if nameField == nil { return } // Don't populate the items until they have been wired up by the view controller.
        nameField.text    = specialty.name as! String
        valueField.text   = specialty.value.description
        stepperView.value = Double(specialty.value.description.toInt() ?? 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        var spec = specialty
        spec.name = nameField.text
        spec.value = Int16(valueField.text.toInt() ?? 0)
        super.viewDidDisappear(animated)
    }
    
    
    
    @IBAction func stepperValueChanged(sender: AnyObject?) {
        valueField.text = NSNumber(integer:Int(stepperView.value)).stringValue
    }


}

