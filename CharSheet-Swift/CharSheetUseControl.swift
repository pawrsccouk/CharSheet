//
//  PWCharSheetUseControl.m
//  CharSheet
//
//  Created by Patrick Wallace on 16/01/2013.
//
//

import UIKit


class CharSheetUseControl : UIControl {
    
    // Tags for controls we are interested in. Must be kept in sync with Interface Builder.
    enum SubviewTags : Int {
        case Stats  = 100,
        Skills = 101
    }
    
    var  statsLabel: UIView?, skillsLabel: UIView?
    
    func findLabel(whichLabel: SubviewTags)  -> UIView? {
        // If we get any more labels needed, put the caches in a dictionary and make this method generic.
        if whichLabel == .Skills {
            if skillsLabel == nil {
                skillsLabel =  viewWithTag(whichLabel.rawValue)
                assert(skillsLabel != nil, "CharSheetUseView.xib doesn't have a tag with value \(whichLabel)")
            }
            return skillsLabel
        }
        else if whichLabel == .Stats {
            if statsLabel == nil {
                statsLabel = viewWithTag(whichLabel.rawValue)
                assert(statsLabel != nil, "CharSheetUseView XIB doesn't have a tag with value \(whichLabel)")
            }
            return statsLabel
        }
        assert(false, "Undefined SubviewTags value \(whichLabel) passed to findLabel:")
        return nil
    }

    func underlineView(path: UIBezierPath, viewOrNil: UIView?) {
        if let view = viewOrNil {
            var viewFrame = view.frame;
            viewFrame = CGRectOffset(viewFrame, 0, viewFrame.size.height);
			path.moveToPoint(viewFrame.origin)
            path.addLineToPoint(CGPoint(x: viewFrame.origin.x + viewFrame.size.width, y: viewFrame.origin.y))
        }
    }
    
    override func drawRect(rect: CGRect) {
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
