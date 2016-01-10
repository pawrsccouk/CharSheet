//
//  PWEditXPGainViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import UIKit

/// This controller manages a view which displays one gain of XP.  
/// This is typically displayed as a pop-up when the user adds some XP or clicks on a row in the XP Gain table.
/// 
/// XP Gain has two fields 'reason' and 'amount', e.g. 
///
///     'Saved the crew', 200 XP
///
/// This view allows users to edit those values.

class EditXPGainViewController: UIViewController
{
    // MARK: Interface Builder
	
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var reasonTextField: UITextField!

    // MARK: Public Properties

    var xpGain: XPGain!

    var completionBlock: VoidCallback?

	override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        configureView()
    }
    
    override func viewDidDisappear(animated:Bool)
	{
		configureData()
        if let block = completionBlock {
            block()
        }
        super.viewDidDisappear(animated)
    }
    
    private func configureView()
	{
		amountTextField.text = xpGain.amount.description
		reasonTextField.text = xpGain.reason
    }

	private func configureData()
	{
		if let amtStr = amountTextField.text, amt = Int(amtStr) {
			xpGain.amount = Int16(amt)
		} else {
			xpGain.amount = 0
		}
		xpGain.reason = reasonTextField.text
	}

}
