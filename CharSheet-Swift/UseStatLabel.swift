//
//  PWUseStatLabel.m
//  CharSheet
//
//  Created by Patrick Wallace on 12/12/2012.
//
//

import UIKit

/// Control showing the text for a given pair of (name, value), used for showing stats.
///
/// Displays <NAME> = <VALUE> in a given font (currently hard codes as System-17).  E.g. "Stealth = 7".
/// If clicked, draws itself highlighted.

class UseStatLabel : UIControl
{
	// MARK: Properties

	/// The name of the stat to display.  Example "strength"
	var name: String = "" {
		didSet {
			setNeedsDisplay()
		}
	}

	/// The value of the stat.
	var value: Int16 = 0 {
		didSet {
			setNeedsDisplay()
		}
	}

	// MARK: Overrides

    override func drawRect(rect: CGRect)
	{
        let bounds = self.bounds
        let ctx = UIGraphicsGetCurrentContext()

        let foreColour = UIColor.blackColor(), backColour = UIColor(red:0.25, green:0.25, blue:0.75, alpha:0.25)
        CGContextSetStrokeColorWithColor(ctx, foreColour.CGColor)
        
        if selected {
            CGContextSaveGState(ctx)
            CGContextSetFillColorWithColor(ctx, backColour.CGColor)
            CGContextFillRect(ctx, bounds)
            CGContextStrokeRect(ctx, bounds)
            CGContextRestoreGState(ctx)
        }
        
        let insetBounds = CGRectInset(bounds, 1, 1)
		let text = "\(name): \(value)"
        text.drawInRect(insetBounds, withAttributes: [NSFontAttributeName : UIFont.systemFontOfSize(17)])
    }
    
    
    override var description: String {
        return "<\(super.description) name=\(name), value =\(value)>"
    }
}
