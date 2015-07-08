//
//  PWUseStatLabel.m
//  CharSheet
//
//  Created by Patrick Wallace on 12/12/2012.
//
//

import UIKit

class UseStatLabel : UIControl {

	var name: String = "" {
		didSet {
			setNeedsDisplay()
		}
	}

	var value: Int16 = 0 {
		didSet {
			setNeedsDisplay()
		}
	}

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
