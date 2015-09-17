//
//  PWEditXPGainViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 05/05/2013.
//
//

import UIKit

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
