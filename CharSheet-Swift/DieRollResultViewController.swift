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

    @IBAction func done(sender: AnyObject?) {
        
        if addTickSwitch.on {
            if let callback = addTickAction {
                callback()
            }
        }
        
        // Log the roll.
        var entry = dieRoll.addLogEntry()
        if addTickSwitch.on {
            let c = entry.change ?? ""
            entry.change = "\(c)\nTick added."
        }
        
        if let callback = self.dismissCallback {
            callback()
        }
        
        if let pvc = presentingViewController {
            pvc.dismissViewControllerAnimated(true, completion:nil)
        }
    }


    // MARK: - Properties
    
    var dieRoll: DieRoll! {
        didSet {
            if dieRoll != oldValue {
                if let w = webView {
                    w.loadHTMLString(dieRoll.resultAsHTML, baseURL: nil)
                }
            }
        }
    }
    
    // Called when the user wants to add a tick to a skill.
    var addTickAction: VoidCallback? {
        didSet {
            // Always re-check the controls just in case (e.g. if the user explicitly passes in nil and it is nil already, we want to ensure the control is disabled).
            enableAddTickControl()
        }
    }
    
    // Called when the user dismisses the popup. Save stuff here.
    var dismissCallback: VoidCallback?
    


    //init(nibName: nibNameOrNil, bundle nibBundleOrNil:NSBundle) {
    //    super.init(nibName:"DieRollResultView", bundle:nibBundleOrNil)
    //        let bbiDone = UIBarButtonItem(barButtonSystemItem:.Done, target:self, action:"done")
    //        navigationItem.setRightBarButtonItem(bbiDone)
    //        addTickAction = nil
    //    }
    //    return self;
    //}


    // MARK: Methods
    
    func enableAddTickControl() {
        if let s = addTickSwitch {
            s.on       = addTickAction != nil     // Default to YES if allowed, NO if disabled.
            s.enabled  = addTickAction != nil
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let w = webView {
            w.loadHTMLString(dieRoll.resultAsHTML, baseURL:nil)
        }
        enableAddTickControl()
    }

}

