//
//  PWListSelectController.m
//  CharSheet
//
//  Created by Patrick Wallace on 25/11/2012.
//
//

import UIKit
import CoreData

class SkillSelectController : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: Interface Builder
    
    @IBOutlet weak var skillPicker: UIPickerView!
    @IBOutlet weak var specialtyPicker: UIPickerView!
    
    // MARK: Properties
    
    // The char sheet used to get the available skills and specialties.
    //@property (nonatomic, strong) PWCharSheet *charSheet;
    
    // The currently selected skill and specialty.
    var selectedSkill: Skill?
    var selectedSpecialty: Specialty?
    
    // The possible skills we can pick.
    var skillsToPick = MutableOrderedSet<Skill>()
    
    // Callback if the selection changes.
    typealias SelectionChanged = (selectedSkill: Skill, selectedSpecialty: Specialty) -> Void
    var  selectionChangedBlock: SelectionChanged?
    
    // Call to get a new skill select controller from the Nib file. Use in place of Alloc/Init.
    class func skillSelectControllerFromNib() -> SkillSelectController {
        let allObjects = NSBundle.mainBundle().loadNibNamed("SkillSelectView", owner: self, options: nil)
        return allObjects[0] as! SkillSelectController
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we have been given a selected skill or specialty, then set the pickers to show those values by default.
        
        if let skill = selectedSkill {
            var indexOfObject = skillsToPick.indexOfObject(skill)
            assert(indexOfObject != NSNotFound, "Skill \(skill) is not in the list of skills to pick \(skillsToPick)")
            skillPicker.selectRow(indexOfObject, inComponent: 0, animated: false)
        
            if let spec = selectedSpecialty {
                let indexOfObject = skill.specialties.indexOfObject(spec)
                assert(indexOfObject != NSNotFound, "Specialty \(spec) is not in the list of specialties \(skill.specialties) for skill \(skill)")
                    specialtyPicker.selectRow(indexOfObject + 1, inComponent: 0, animated: false)
            }
            else {
                specialtyPicker.selectRow(0, inComponent: 0, animated: false)   // The "None" row.
            }
        }
    }

////func getFirstListEntries() -> OrderedSet<Skill>
////{
////    if(!firstListItems)
////        firstListItems = [self.delegate listSelectController:self itemsForList:PWListSelectPrimaryList];
////    return firstListItems;
////}
////
////
////
////
////
////-(NSOrderedSet*)getSecondListEntriesForceReload:(BOOL)forceReload
////{
////    if(forceReload || !secondListItems)
////        secondListItems = [self.delegate listSelectController:self itemsForList:PWListSelectSecondaryList];
////    return secondListItems;
////}
////
////
////static void selectItemInPicker(UIPickerView *picker, NSOrderedSet *items, id sel, PWListSelectController *self)
////{
////    if(picker && sel) {
////        NSInteger i = [items indexOfObject:sel];
////        if(i != NSNotFound) {
////            [picker selectRow:i inComponent:0 animated:YES];
////            [self pickerView:picker didSelectRow:i inComponent:0];
////        }
////    }
////}
////
////
////
////-(void)setSelectedItemList1:(id)selectedItemList1
////{
////        // Always trigger the update when this method is called, even if we "select" the same object.
////    _selectedItemList1 = selectedItemList1;
////    selectItemInPicker(pickerView1, firstListItems, selectedItemList1, self);
////    [self reloadList2FromList1];
////}
////
////
////
////
////-(void)reloadList2FromList1
////{
////        // Update the second list from the value selected in the first.
////    if (use2ndList) {
////        pickerLabel2.text = [self.delegate respondsToSelector:@selector(listSelectController:titleForList:)]
////                          ? [self.delegate listSelectController:self titleForList:PWListSelectSecondaryList]
////                          : @"";
////        
////        secondListItems = [self getSecondListEntriesForceReload:YES];
////        [pickerView2 reloadAllComponents];
////        
////        self.selectedItemList2 = secondListItems.count > 0  ? [secondListItems objectAtIndex:0] :  nil;
////    }
////}
////
////
////
////
////
////-(void)setSelectedItemList2:(id)selectedItemList2
////{
////        // Always trigger the update when this method is called, even if we "select" the same object.
////    _selectedItemList2 = selectedItemList2;
////    selectItemInPicker(pickerView2, secondListItems, selectedItemList2, self);
////}
////
////
////
////-(void)reloadData
////{
////    _selectedItemList1 = _selectedItemList2 = nil;
////    firstListItems = secondListItems = nil;
////    pickerLabel1.text = pickerLabel2.text = @"";
////    use2ndList = [self.delegate useSecondListInlistSelectController:self];
////        // Find out if we need to display the second list.
////    BOOL hide2ndList    = !use2ndList;
////    pickerView2.hidden  = hide2ndList;
////    pickerLabel2.hidden = hide2ndList;
////    pickerLabel1.text = [self.delegate listSelectController:self titleForList:PWListSelectPrimaryList];
////    
////    [self populateFirstList];
////
////}



//MARK: - Picker View Delegate

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }





    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: NSInteger) -> Int
    {
        assert(pickerView == skillPicker || pickerView == specialtyPicker, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
        if      pickerView == skillPicker     { return skillsToPick.count }
        else if pickerView == specialtyPicker { return (selectedSkill?.specialties?.count ?? 0) + 1 } // Extra row "None" in the specialties list.
        else { return 0 }
    }
    
    
    
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String {
        assert(component == 0, "Component ID \(component) is not 0")
        assert(pickerView == skillPicker || pickerView == specialtyPicker, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
        
        if pickerView == skillPicker {
            var skill = self.skillsToPick[row]
            return skill.name as? String ?? "No name"
        }
        else if pickerView == specialtyPicker  {
            // First row should always be "None" and other rows follow in order after that.
            if row == 0 { return "None" }
            if let specialty = selectedSkill?.specialties[row - 1] as? Specialty {
                return specialty.name as? String ?? "No name"
            }
        }
        return ""
    }

    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        assert(component == 0, "Component ID \(component) is not 0")
        assert(pickerView == skillPicker || pickerView == specialtyPicker, "Unknown picker \(pickerView) passed to numberOfRowsInComponent for SkillSelectController \(self)")
        
        if pickerView == skillPicker {
            selectedSkill = self.skillsToPick[row]
            self.selectedSpecialty = nil
            specialtyPicker.reloadAllComponents()   // Reload the specialty picker now the skill has changed.
        }
        else if(pickerView == specialtyPicker) {     // First row "None" equates to a nil selected specialty.
            selectedSpecialty = (row == 0) ? nil : self.selectedSkill?.specialties[row - 1] as? Specialty
        }
    }
    
    
}

