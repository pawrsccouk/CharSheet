//
//  PWTicksView.m
//  CharSheet
//
//  Created by Patrick Wallace on 19/11/2012.
//
//

import UIKit

/// Custom view which takes a Skill object and draws a grid of 20 squares with some of them 'ticked' (i.e. filled in).
/// The number filled in is the number of ticks this skill has.
///
/// This object sets itself as an Observer of the Skill object's 'ticks' parameter using KVO, so it is automatically updated
/// when the number of ticks changes.
class TicksView : UIView
{
	// MARK: Properties

	/// The skill to display. We use the 'ticks' property to get how many ticks to display.
    var skill: Skill! {
        didSet {
            if oldValue != self.skill {
                if let s = oldValue {
                    s.removeObserver(self, forKeyPath:"ticks")
                }
                if let s = self.skill {
                    s.addObserver(self, forKeyPath:"ticks", options:.new, context:nil)
                }
                setNeedsDisplay() // redraw the ticks.
            }
        }
    }

	// MARK: Construction.

    required init(frame: CGRect, skill: Skill)
	{
        self.skill = skill
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder)
	{
        super.init(coder: coder)
    }

	// MARK: Overrides

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change:[NSKeyValueChangeKey: Any]?, context:UnsafeMutableRawPointer?)
	{
        if keyPath  == "ticks" {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect)
	{
        let bounds = self.bounds
        let fgCol = UIColor.darkText
        
        // 4 rows of 5 boxes.
        // 1 find which is smaller, width / 5, or height / 4
        let boxSize: CGFloat = min(bounds.size.width / 5, bounds.size.height / 4);
        
        let ctx = UIGraphicsGetCurrentContext();
        ctx?.setLineWidth(1);
        fgCol.set()
        
        var ticksDrawn: Int16 = 0, numberOfTicks = skill.ticks

//      for var iRow = 0; iRow < 4; iRow++
		for iRow in 0..<4 {
//          for var iCol = 0; iCol < 5; iCol++
			for iCol in 0..<4 {
                let x = bounds.origin.x + CGFloat(iCol) * boxSize, y = bounds.origin.y + CGFloat(iRow) * boxSize
                var rectBox: CGRect = CGRect(x: x, y: y, width: boxSize, height: boxSize)
                ctx?.stroke(rectBox);  // Draw the box outline.
                
                if ticksDrawn < numberOfTicks {
                    rectBox = rectBox.insetBy(dx: 2, dy: 2)
                    ctx?.fill(rectBox)
                    ticksDrawn += 1
                }
            }
        }
    }
}
