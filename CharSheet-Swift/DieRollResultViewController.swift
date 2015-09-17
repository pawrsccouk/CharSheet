//
//  PWDieRollResultViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 25/11/2012.
//
//

import UIKit
import CoreData

class DieRollResultViewController : UIViewController {

    // MARK: Interface Builder
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var addTickSwitch: UISwitch!

    @IBAction func done(sender: AnyObject?)
	{
        if addTickSwitch.on {
            if let callback = addTickAction {
                callback()
            }
        }
        
        // Log the roll.
        let entry = dieRoll.addLogEntry()
        if addTickSwitch.on {
            let c = entry.change ?? ""
            entry.change = "\(c)\nTick added."
        }

		NSNotificationCenter.defaultCenter().postNotificationName("SaveChanges", object: nil)
		presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }


    // MARK: - Properties
    
    var dieRoll: DieRoll!

    // Called when the user wants to add a tick to a skill.
    var addTickAction: VoidCallback? {
        didSet {
            // Always re-check the controls just in case
			// (If the user explicitly passes in nil and it is nil already, we want to ensure the control is disabled).
            enableAddTickControl()
        }
    }

    // MARK: Methods
    
    func enableAddTickControl()
	{
        if let s = addTickSwitch {
            s.on       = addTickAction != nil     // Default to YES if allowed, NO if disabled.
            s.enabled  = addTickAction != nil
        }
    }
    
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		webView.loadHTMLString(dieRoll.resultAsHTML, baseURL: nil)
		enableAddTickControl()
	}
}

