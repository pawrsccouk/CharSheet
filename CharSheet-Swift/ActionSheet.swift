//
//  PWActionSheet.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

import UIKit

typealias Block = () -> Void
typealias BlockDict = Dictionary<String, Block>

class ActionSheet : NSObject, UIActionSheetDelegate
{
    var buttonTitlesAndBlocks: BlockDict
    var cancelButtonTitle: String?
    var destructiveButtonTitle: String?
    var actionSheet: UIActionSheet!
    
    private class func copyDict(dict: BlockDict) -> BlockDict {
        var resDict = BlockDict()
        for k in dict.keys { resDict[k] = dict[k] }
        return resDict
    }
    
    init(title                                 : String,
		buttonTitlesAndBlocks  titlesAndBlocks : BlockDict,
		cancelButtonTitle      cancelTitle     : String?,
		destructiveButtonTitle destructiveTitle: String?) {

        buttonTitlesAndBlocks  = ActionSheet.copyDict(titlesAndBlocks)
        destructiveButtonTitle = destructiveTitle
        cancelButtonTitle      = cancelTitle
        
        var otherButtons = ActionSheet.copyDict(buttonTitlesAndBlocks)
        if let cancelTitle = cancelButtonTitle {
            otherButtons.removeValueForKey(cancelTitle)
        }
        if let destructiveTitle = destructiveButtonTitle {
            otherButtons.removeValueForKey(destructiveTitle)
        }
        
        super.init()
        actionSheet = UIActionSheet(title:title, delegate:self, cancelButtonTitle:nil, destructiveButtonTitle:nil)
        
        // Add the destructive button first (if any) and the cancel button last.
        // Note that the iPad action sheet will always hide the cancel button as you are supposed to click outside
        // the sheet to cancel it. This will generate a call to the delegate with the index of the cancel button automatically.
        if let title = destructiveButtonTitle {
            actionSheet.destructiveButtonIndex = actionSheet.addButtonWithTitle(title)
        }
        for title in otherButtons.keys {
            actionSheet.addButtonWithTitle(title)
        }
        if let title = cancelButtonTitle {
            actionSheet.cancelButtonIndex = actionSheet.addButtonWithTitle(title)
        }
    }
    
    convenience init(title: String,
		confirmButtonTitle: String,
		confirmBlock      : Block,
		cancelButtonTitle : String,
		cancelBlock       : Block) {

        self.init(title           : title,
			buttonTitlesAndBlocks : [confirmButtonTitle: confirmBlock, cancelButtonTitle: cancelBlock],   cancelButtonTitle : cancelButtonTitle,
			destructiveButtonTitle: nil)
    }
    

    convenience init(title    : String,
		destructiveButtonTitle: String,
		destructiveBlock      : Block,
		cancelButtonTitle     : String,
		cancelBlock           : Block) {

        self.init(title           : title,
			buttonTitlesAndBlocks : [destructiveButtonTitle: destructiveBlock, cancelButtonTitle: cancelBlock],
			cancelButtonTitle     : cancelButtonTitle,
			destructiveButtonTitle: destructiveButtonTitle)
    }
    
    func showFromBarButtonItem(barButtonItem: UIBarButtonItem, animated: Bool) {
        actionSheet.showFromBarButtonItem(barButtonItem, animated:animated)
    }
    
    // MARK: - Action Sheet delegate
    
    func actionSheet(sheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        // If the user didn't specify a cancel handler, the system can trigger a cancel anyway under some conditions
        // e.g. user clicks outside the popover on an iPad. In that case the system should return the cancel index, but it
        // actually returns -1. Handle both these conditions.
        if( (buttonIndex == -1)
			|| ( (cancelButtonTitle == nil) && (buttonIndex == actionSheet.cancelButtonIndex)) ) {
            return
        }
        
        // Otherwise the user clicked a button. Get the action for that button and execute it.
		guard let
			buttonTitle = sheet.buttonTitleAtIndex(buttonIndex),
			action      = buttonTitlesAndBlocks[buttonTitle]
		else {
			fatalError("No action found for button at index \(buttonIndex)")
		}
		action()
    }
}
