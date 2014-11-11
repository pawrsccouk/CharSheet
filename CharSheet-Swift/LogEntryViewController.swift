//
//  PWLogEntryViewController.m
//  CharSheet
//
//  Created by Patrick Wallace on 04/01/2013.
//
//

import UIKit


class LogEntryViewController : UIViewController {
        
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let l = logEntry {
            let c = l.change ?? ""
            textView.text = c
        }
    }
}
