//
//  PWSkillCell.m
//  CharSheet
//
//  Created by Patrick Wallace on 19/11/2012.
//
//

import UIKit

class UseSkillCell : UICollectionViewCell {

    enum CellTags : Int {
        case Name = 1, Value, Specialties, Ticks
    }
    
    weak var _contentView: UIView?
    
    // Add observers to the skill when we set it, so that we can update the display when it changes.
    // Default to a dummy skill, until one is properly set.
    
    var skill: Skill! {
        didSet {
            if skill != oldValue {
                if let s = oldValue {
                    s.removeObserver(self, forKeyPath:"name"       )
                    s.removeObserver(self, forKeyPath:"value"      )
                    s.removeObserver(self, forKeyPath:"specialties")
                }
                
                if let s = skill {
                    s.addObserver(self, forKeyPath:"name"       , options:.New, context:nil)
                    s.addObserver(self, forKeyPath:"value"      , options:.New, context:nil)
                    s.addObserver(self, forKeyPath:"specialties", options:.New, context:nil)
                    
                    setLabelViaTag(.Name       , value: s.name ?? "")
                    setLabelViaTag(.Value      , value: s.value.description)
                    setLabelViaTag(.Specialties, value: s.specialtiesAsString)
                    
					assert(self.viewWithTag(CellTags.Ticks.rawValue)?.isKindOfClass(TicksView) ?? false,
						"View \(self.viewWithTag(CellTags.Ticks.rawValue)) is not a TicksView object")
                    if let tv = self.viewWithTag(CellTags.Ticks.rawValue) as? TicksView {
                        tv.skill = s
                    }
                    else {
                        assert(false, "TicksView not found")
                    }
                }
                setNeedsDisplay()
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        var arrayOfViews = NSBundle.mainBundle().loadNibNamed("UseSkillCellView", owner:self, options:nil)
        
        if arrayOfViews.count >= 1 {
            
			if let content = arrayOfViews[0] as? UIView {
				self.contentView.addSubview(content)
			}
            self.selectedBackgroundView = UIView(frame:frame)
            self.selectedBackgroundView.backgroundColor = UIColor(red:0.25, green:0.25, blue:0.75, alpha:0.25)
        }
        
    }
   
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setLabelViaTag(tag: CellTags, value: String) {
        let view = viewWithTag(tag.rawValue)
        assert(view != nil)
        if let v = view {
            if v.isKindOfClass(UILabel) { (v as! UILabel).text = value }
            else if v.isKindOfClass(UITextView) { (v as! UITextView).text = value }
            else {
                assert(false, "View \(v) found, should be text view or label.")
            }
        }
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object:AnyObject, change:[NSObject: AnyObject], context:UnsafeMutablePointer<Void>) {
        if      keyPath == "name"        { setLabelViaTag(.Name       , value: skill.name ?? "") }
        else if keyPath == "value"       { setLabelViaTag(.Value      , value: skill.value.description) }
        else if keyPath == "specialties" { setLabelViaTag(.Specialties, value: skill.specialtiesAsString) }
    }
    
    
    override var description: String {
        let desc = super.description, name = skill.name ?? "No name", ticks = skill.ticks.description
        return "\(desc) skill: \(name) ticks: \(ticks)"
    }
    
    // Underline the skill box.
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        // White background.
        UIColor.whiteColor().set()
        UIBezierPath(rect:rect).fill()
        
        // Grey underline.
        UIColor.lightGrayColor().set()
        var path = UIBezierPath()
        
        var bounds = self.bounds
        var lineOrigin = CGPointMake(bounds.origin.x, bounds.origin.y + bounds.size.height)
        var lineEnd    = CGPointMake(lineOrigin.x + bounds.size.width, lineOrigin.y)
        
        path.moveToPoint(lineOrigin)
        path.addLineToPoint(lineEnd)
        path.stroke()
    }
    

}
