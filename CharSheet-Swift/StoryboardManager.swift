//
//  PWStoryboardManager.m
//  CharSheet
//
//  Created by Patrick Wallace on 26/01/2014.
//
//

import UIKit

var sharedPointer: StoryboardManager? = nil

/// This class holds a singleton object which caches and coordinates the various Storyboard files we have.
/// It gives me a single place to load storyboards instead of having the loading data scattered across the view controllers.

class StoryboardManager
{
	/// Return a pointer to a storyboard manager which is shared across the application.
    class func sharedInstance() -> StoryboardManager {
        if sharedPointer == nil {
            sharedPointer = StoryboardManager()
        }
        return sharedPointer!
    }

	/// Initializer is private, use the **sharedInstance** constructor instead.
    private init() {
    }

	/// The main storyboard, used when playing the game.
    lazy var mainStoryboard: UIStoryboard = {
        return UIStoryboard(name:"MainUse", bundle: NSBundle.mainBundle())
    }()

	/// The 'Edit' storyboard, used when editing a character.
    lazy var editStoryboard: UIStoryboard = {
        return UIStoryboard(name:"Edit", bundle:NSBundle.mainBundle())
    }()
}
