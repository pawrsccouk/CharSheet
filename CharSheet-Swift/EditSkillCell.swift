//
//  PWEditSkillCell.m
//  CharSheet
//
//  Created by Patrick Wallace on 22/11/2012.
//
//

import UIKit

class EditSkillCell : UITableViewCell {
    
    // MARK: - Interface Builder Outlets.
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var specialtiesLabel: UILabel!
    
    var name: String = "" {
        didSet {
            if let l = nameLabel {
                l.text = name
            }
        }
    }
    
    var value: Int16 = 0 {
        didSet {
            if let l = valueLabel {
                l.text = value.description
            }
        }
    }
    
    var specialties: String = "" {
        didSet {
            if let l = specialtiesLabel {
                l.text = specialties
            }
        }
    }
}

