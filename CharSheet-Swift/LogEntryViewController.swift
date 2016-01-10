//
//  PWLogEntryViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 04/01/2013.
//
//

import UIKit

/// This controller manages a view which displays one LogEntry object.
/// This view is read-only. Log entries can't be edited.
///
/// It is typically presented as a popover when the user selects a row from the log table.

class LogEntryViewController : UIViewController
{
    @IBOutlet weak var textView: UITextView!
    
    var logEntry: LogEntry? {
        didSet {
            if logEntry != oldValue {
                if let t = textView {
                    let c = logEntry?.change ?? ""
                    t.text = c
                }
            }
        }
    }
    
    
    override func viewDidLoad()
	{
        super.viewDidLoad()
        if let l = logEntry {
            textView.text = l.change ?? ""
        }
    }
}
