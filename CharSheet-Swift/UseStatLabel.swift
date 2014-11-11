//
//  PWUseStatLabel.m
//  CharSheet
//
//  Created by Patrick Wallace on 12/12/2012.
//
//

import UIKit

class UseStatLabel : UIControl {

    private var text = ""
    
    var stat: Stat! {
        didSet {
                let name = stat.name ?? "No name", value = stat.value
                text = "\(name): \(value)"
                setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        // Drawing code
        let bounds = self.bounds
        var ctx = UIGraphicsGetCurrentContext()
        
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
        text.drawInRect(insetBounds, withAttributes: [NSFontAttributeName : UIFont.systemFontOfSize(17)])
    }
    
    
    override var description: String {
        return "<\(super.description) stat=\(stat)>"
    }

}
