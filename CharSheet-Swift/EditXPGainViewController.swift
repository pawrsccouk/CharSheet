//
//  PWEditXPGainViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import UIKit

class EditXPGainViewController : UIViewController
{    
    // Removed the stepper as XP Gains are random large numbers, e.g. 1500 and too large to step through.
    
    // MARK: Interface Builder
    @IBOutlet weak var amountTextField: UITextField!
    // @IBOutlet weak var amountStepper: UIStepper!
    @IBOutlet weak var reasonTextField: UITextField!
    
    
    // These actions are used to link up the amount stepper and the amount text field so they stay in sync.

    //@IBAction func amountValueChanged(sender: AnyObject?) {
    //    // Ensure the value is an integer by converting to int and back (value is a double)
    //    if let v = (sender as? UITextField)?.text.toInt() {
    //        amountStepper.value = Double(v)
    //    }
    //}
    
    //@IBAction func amountStepperChanged(sender: AnyObject?) {
    //        if let v = (sender as? UIStepper)?.value {
    //        let n = NSNumber(int: Int32(v))
    //        amountTextField.text = n.stringValue
    //    }
    //}
    
    // MARK: Public Properties
    var xpGain: XPGain! {
        didSet {
            if xpGain != oldValue {
                configureView()
            }
        }
    }
    var completionBlock: VoidCallback?
    
    

    override init(nibName nibNameOrNil:String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName:"PWEditXPGainView", bundle:nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    override func viewDidLoad()
    {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidDisappear(animated:Bool) {
        xpGain.amount = Int16(amountTextField.text.toInt() ?? 0)
        xpGain.reason = reasonTextField.text
        if let block = completionBlock {
            block()
        }
        super.viewDidDisappear(animated)
    }
    
    private func configureView() {
        // amountStepper.value  = Double(xpGain.amount.integerValue)
        if let xp = xpGain {
            if let t = amountTextField { t.text = xp.amount.description }
            if let t = reasonTextField { t.text = xp.reason }
        }
    }
    
}
