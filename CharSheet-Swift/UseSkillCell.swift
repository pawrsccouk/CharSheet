//
//  PWSkillCell.m
//  CharSheet
//
//  Created by Patrick Wallace on 19/11/2012.
//
//

import UIKit

/// A cell to display a Skill object as part of a collection view.
/// This loads the contents from UseSkillCellView.nib and gets/sets the properties by searching for tagged components.

class UseSkillCell : UICollectionViewCell
{
	/// Each skill cell has tagged labels for the components to display.
	/// This enum specifies those label tags.
    enum CellTags : Int
	{
        case name = 1, value, specialties, ticks
    }
    
    weak var _contentView: UIView?
    
	/// The skill object this cell displays.
    var skill: Skill! {
		// Add observers to the skill when we set it, so that we can update the display when it changes.
        didSet {
            if skill != oldValue {
                if let oldSkill = oldValue {
					["name", "value"].forEach { oldSkill.removeObserver(self, forKeyPath: $0) }
                }
                
                if let newSkill = skill {
					["name", "value"].forEach { newSkill.addObserver(self, forKeyPath: $0, options: .new, context: nil) }

                    setLabelViaTag(.name       , value: newSkill.name ?? "")
                    setLabelViaTag(.value      , value: newSkill.value.description)
                    setLabelViaTag(.specialties, value: newSkill.specialtiesAsString)
                    
					assert(self.viewWithTag(CellTags.ticks.rawValue)?.isKind(of: TicksView.self) ?? false,
						"View \(self.viewWithTag(CellTags.ticks.rawValue)) is not a TicksView object")
					guard let tv = self.viewWithTag(CellTags.ticks.rawValue) as? TicksView  else { fatalError("TicksView not found") }
					tv.skill = newSkill
                }
                setNeedsDisplay()
            }
        }
    }

	let notificationCentre = NotificationCenter.default

	// MARK: Overrides
    
    override init(frame: CGRect)
	{
        super.init(frame:frame)

		// Update the text on the skill box whenever the specialties change.
		notificationCentre.addObserver(forName: NSNotification.Name(rawValue: Skill.specialtiesChangedNotification), object: nil, queue: nil) {
			(_) in
			self.setLabelViaTag(.specialties, value: self.skill.specialtiesAsString)
		}

        var arrayOfViews = Bundle.main.loadNibNamed("UseSkillCellView", owner:self, options:nil)
        
        if (arrayOfViews?.count)! >= 1 {
			if let content = arrayOfViews?[0] as? UIView {
				contentView.addSubview(content)
			}
            selectedBackgroundView = UIView(frame:frame)
            selectedBackgroundView?.backgroundColor = UIColor(red:0.25, green:0.25, blue:0.75, alpha:0.25)
        }
    }
   
    required init?(coder: NSCoder)
	{
        super.init(coder: coder)
    }

	deinit
	{
		notificationCentre.removeObserver(self)
	}

    override func observeValue(forKeyPath keyPath: String?
		, 					     of object: Any?
		,								  change: [NSKeyValueChangeKey: Any]?
		,								 context: UnsafeMutableRawPointer?)
	{
        if      keyPath == "name"        { setLabelViaTag(.name       , value: skill.name ?? "") }
        else if keyPath == "value"       { setLabelViaTag(.value      , value: skill.value.description) }
    }
    
    
    override var description: String {
        let desc = super.description, name = skill.name ?? "No name", ticks = skill.ticks.description
        return "\(desc) skill: \(name) ticks: \(ticks)"
    }
    
    // Underline the skill box.
    override func draw(_ rect: CGRect)
	{
        super.draw(rect)
        
        // White background.
        UIColor.white.set()
        UIBezierPath(rect:rect).fill()
        
        // Grey underline.
        UIColor.lightGray.set()
        let path = UIBezierPath()
        
        let bounds = self.bounds
        let lineOrigin = CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height)
        let lineEnd    = CGPoint(x: lineOrigin.x + bounds.size.width, y: lineOrigin.y)
        
        path.move(to: lineOrigin)
        path.addLine(to: lineEnd)
        path.stroke()
    }

	// MARK: Private Functions.

	/// Given a string value and a tag, search the view for the label/textView which has that tag
	/// and then use the appropriate message to set the text in that control to VALUE.
	///
	/// If the label/textview is not found, this does nothing.
	///
	/// - parameter tag: The tag of one of the labels in this cell.
	/// - parameter value: The text which the control will be set to display.

    fileprivate func setLabelViaTag(_ tag: CellTags, value: String)
	{
        let view = viewWithTag(tag.rawValue)
        assert(view != nil)
        switch view! {
		case let l as UILabel:     l.text  = value
		case let tv as UITextView: tv.text = value
		default:                   fatalError("View \(view) found, class should be text view or label.")
        }
    }
}
