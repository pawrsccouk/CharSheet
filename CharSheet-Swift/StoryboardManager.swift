//
//  PWStoryboardManager.m
//  CharSheet
//
//  Created by Patrick Wallace on 26/01/2014.
//
//

import UIKit

var sharedPointer: StoryboardManager? = nil

class StoryboardManager {
    
    class func sharedInstance() -> StoryboardManager {
        if sharedPointer == nil {
            sharedPointer = StoryboardManager()
        }
        return sharedPointer!
    }
    
    private init() {
    }
    
    lazy var mainStoryboard: UIStoryboard = {
        return UIStoryboard(name:"MainUse", bundle: NSBundle.mainBundle())
    }()
    
    lazy var editStoryboard: UIStoryboard = {
        return UIStoryboard(name:"Edit", bundle:NSBundle.mainBundle())
    }()
    
}
