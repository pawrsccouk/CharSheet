//
//  PWEditSkillCell.m
//  CharSheet
//
//  Created by Patrick Wallace on 22/11/2012.
//
//

import UIKit

/// A Table-view cell subclass specialised for displaying skills.
/// This links the labels from InterfaceBuilder to a class I can modify.
///
/// Displays them as
///
///		Name: Value
///		Specialty; Specialty; Specialty.
///

class EditSkillCell : UITableViewCell
{
    // MARK: - Interface Builder Outlets.
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var specialtiesLabel: UILabel!

	// MARK: Public properties

	/// The name of the skill.
    var name: String = "" {
        didSet {
            if let l = nameLabel {
                l.text = name
            }
        }
    }

	/// The value of the skill.
    var value: Int16 = 0 {
        didSet {
            if let l = valueLabel {
                l.text = value.description
            }
        }
    }

	/// A summary of all the specialties associated with that skill.
    var specialties: String = "" {
        didSet {
            if let l = specialtiesLabel {
                l.text = specialties
            }
        }
    }
}

