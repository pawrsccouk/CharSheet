//
//  PWTicksView.m
//  CharSheet
//
//  Created by Patrick Wallace on 19/11/2012.
//
//

import UIKit

class TicksView : UIView {


    var skill: Skill! {
        didSet {
            if oldValue != self.skill {
                if let s = oldValue {
                    s.removeObserver(self, forKeyPath:"ticks")
                }
                if let s = self.skill {
                    s.addObserver(self, forKeyPath:"ticks", options:.New, context:nil)
                }
                setNeedsDisplay() // redraw the ticks.
            }
        }
    }

    required init(frame: CGRect, skill: Skill) {
        self.skill = skill
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change:[String: AnyObject]?, context:UnsafeMutablePointer<Void>) {
        if keyPath  == "ticks" {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        //    NSLog(@"TicksView:drawRect: Drawing %d ticks", [self numberOfTicks]);
        let bounds = self.bounds
        let fgCol = UIColor.darkTextColor()
        
        // 4 rows of 5 boxes.
        // 1 find which is smaller, width / 5, or height / 4
        let boxSize: CGFloat = min(bounds.size.width / 5, bounds.size.height / 4);
        
        let ctx = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(ctx, 1);
        fgCol.set()
        
        var ticksDrawn: Int16 = 0, numberOfTicks = skill.ticks
        for var iRow = 0; iRow < 4; iRow++ {
            for var iCol = 0; iCol < 5; iCol++ {
                let x = bounds.origin.x + CGFloat(iCol) * boxSize, y = bounds.origin.y + CGFloat(iRow) * boxSize
                var rectBox: CGRect = CGRectMake(x, y, boxSize, boxSize)
                CGContextStrokeRect(ctx, rectBox);  // Draw the box outline.
                
                if ticksDrawn < numberOfTicks {
                    rectBox = CGRectInset(rectBox, 2, 2);
                    CGContextFillRect(ctx, rectBox);
                    ticksDrawn++;
                }
            }
        }
    }

}
