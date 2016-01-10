//
//  PWCharSheetUseControl.m
//  CharSheet
//
//  Created by Patrick Wallace on 16/01/2013.
//
//

import UIKit

/// This is the main view for the character sheet.
///
/// It contains the stats and skills as subviews and draws global decorations such as dividing lines
/// between stats and skills and so on.
///
/// It is a control so that we can trap touch events for the subviews (I think).

class CharSheetUseControl : UIControl {
    
	/// Tags for sub-controls we are interested in.
	/// 
	/// Must be kept in sync with Interface Builder.
    enum SubviewTags : Int {
        case Stats  = 100,
        Skills = 101
    }

	/// Cached label to display the stats (to avoid repeatedly searching the view for the subview).
    var  statsLabel: UIView?

	/// Cached label to display the skills (to avoid repeatedly searching the view for the subview).
	var skillsLabel: UIView?

    override func drawRect(rect: CGRect)
	{
		/// Given a sub-view, add a line drawn underneath it to the bezier path provided.
		///
		/// - parameter path: The bezier path to add drawing code to.
		///                   This should be created to draw on to the main view, otherwise the coordinate system will not be the same.
		/// - parameter viewOrNil: Optionally the view to underline. If this is nil, then the method does nothing.
		///                        We accept nil values here as it makes the calling code simpler.
		func underlineView(path: UIBezierPath, viewOrNil: UIView?)
		{
			if let view = viewOrNil {
				let newFrame = CGRectOffset(view.frame, 0, view.frame.size.height);
				path.moveToPoint(newFrame.origin)
				path.addLineToPoint(CGPoint(x: newFrame.origin.x + newFrame.size.width, y: newFrame.origin.y))
			}
		}


		/// Finds the label associated with the enum passed in as parameter.
		/// The label returned will always be a child of the receiver and should never be nil.
		///
		/// - parameter whichLabel: The Stats or Skills label to return.
		/// - returns: The label associated with the WHICHLABEL parameter.

		func findLabel(whichLabel: SubviewTags)  -> UIView
		{
			// Return the label from the cache if present, otherwise search for it, add it to the cache and return it.
			// If we get any more labels needed, put the caches in a dictionary and make this method generic.
			if whichLabel == .Skills {
				if skillsLabel == nil {
					skillsLabel =  viewWithTag(whichLabel.rawValue)
					assert(skillsLabel != nil, "CharSheetUseView.xib doesn't have a tag with value \(whichLabel)")
				}
				return skillsLabel!
			}
			else if whichLabel == .Stats {
				if statsLabel == nil {
					statsLabel = viewWithTag(whichLabel.rawValue)
					assert(statsLabel != nil, "CharSheetUseView XIB doesn't have a tag with value \(whichLabel)")
				}
				return statsLabel!
			}
			fatalError("Undefined SubviewTags value \(whichLabel) passed to findLabel:")
		}

		// Drawing code
        super.drawRect(rect)

        UIColor.blackColor().set()

        // Find the subviews corresponding to the stats block and skills blocks, and draw decoration around them.
        let path = UIBezierPath()
        underlineView(path, viewOrNil: findLabel(.Stats))
        underlineView(path, viewOrNil: findLabel(.Skills))
        path.stroke()
    }
    
}
