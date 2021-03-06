//
//  CombatTargetsViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 04/04/2016.
//  Copyright © 2016 Patrick Wallace. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


private let CELL_ID = "SpellTargetsCell"

private let kDimensions = "Dimensions", kDuration = "Duration", kDifficulty = "Difficulty", kDistance = "Distance", kGroups = "Groups"

// All range from -1 to 3
private let dimensions = ["Tiny"   , "Small" , "Medium"       , "Large"  , "Huge"      ]
private let distance   = ["Self"   , "Reach" , "Stone's throw", "Bowshot", "Perception"]
private let duration   = ["Second" , "Minute", "Hour"         , "Day"    , "Week"      ]
private let difficulty = ["Trivial", "Simple", "Unusual"      , "Tricky" , "Finicky"   ]
// Ranges from 0 to +4
private let groups     = ["Single target", "Squad (up to 15)", "Company (up to 200)", "Army (up to 3,000)", "Host (up to 50,000)"]

private let data = [
	kDimensions: dimensions,
	kDistance  : distance,
	kDuration  : duration,
	kDifficulty: difficulty,
	kGroups    : groups
]

/// Copy of the keys in data.
///
/// A copy is kept here so the sort ordering will not change
/// and we don't have to re-sort them for each call to the data source.

private let keys = [kDimensions, kDistance, kDuration, kDifficulty, kGroups]
private typealias ArrayIndex = Int

class SpellTargetsViewController: CharSheetViewController
{
	// MARK: Interface Builder
	@IBOutlet var table: UITableView!

	@IBAction func editDone(_ sender: AnyObject?)
	{
		assert(presentingViewController != nil)
		presentingViewController?.dismiss(animated: true, completion: nil)
	}

	// MARK: Overrides

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		valuesSelected.removeAll()
	}

	// MARK: Data

	/// The values selected for each category.
	///
	/// The value is the index into the relevant array of the selected object.
	fileprivate var valuesSelected: [String: ArrayIndex] = [:]

	/// This is the final total from all the values selected.
	/// Sections where the user has not yet decided are not included in the total.
	fileprivate var finalTotal: Int {
		var total = 0
		for (key, value) in valuesSelected {
			total += (key == kGroups ? value : value - 1)  // Groups ranges from 0..4, others from -1..4
		}
		return total
	}
}

// MARK: - Private support methods

extension SpellTargetsViewController
{

	/// Returns true if the index path refers to the totals section.
	/// False if it refers to one of the data sections.
	fileprivate func isTotalsSection(_ sectionIndex: ArrayIndex) -> Bool
	{
		assert(sectionIndex >= 0 || sectionIndex <= data.count, "section index \(sectionIndex) is out of range.")
		return sectionIndex >= data.count
	}

	/// Returns true if the given section has been collapsed because the user has specified a value.
	fileprivate func isCollapsed(_ sectionId: String) -> Bool
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		return valuesSelected[sectionId] != nil
	}

	/// Collapse the section specified as the user has specified one of the values to use.
	///
	/// - parameter sectionId: The string ID of the section to collapse
	/// - parameter selectedIndex: The index into the relevant array of the value the user selected.
	fileprivate func collapseSection(_ sectionId: String, selectedValue: ArrayIndex)
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		assert(selectedValue >= 0 || selectedValue < data[sectionId]?.count, "selected value \(selectedValue) is out of range for group \(sectionId).")

		// Most values range from -1 to 4, but the groups value ranges from 0 to 4.
		valuesSelected[sectionId] = selectedValue
	}

	/// Expand the section specified.
	/// This occurs if the user changes hir mind and wants to pick from the list again.
	///
	/// - parameter sectionId: The string ID of the section to expand.  
	///
	/// The user's choice is deleted and the section will be shown when the table is viewed again.
	fileprivate func restoreSection(_ sectionId: String)
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		valuesSelected[sectionId] = nil
	}
}

// MARK: - Data Source

extension SpellTargetsViewController: UITableViewDataSource
{
	func numberOfSections(in tableView: UITableView) -> Int
	{
		// All the data sections and a totals section at the end.
		return data.count + 1
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return isTotalsSection(section) ? "Total" : keys[section]
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		// The final totals section and all collapsed sections always just have one row.
		if isTotalsSection(section) || isCollapsed(keys[section]) {
			return 1
		}
		return  data[keys[section]]!.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID) ?? UITableViewCell()

		if isTotalsSection(indexPath.section) {
			let dieRoll = 10 + (5 * max(finalTotal, 0))
			cell.textLabel?.text = "Final total: "
			cell.detailTextLabel?.text = "\(finalTotal) - Die roll \(dieRoll)"
		} else {
			// Find the key for the section, then get the index of the cell
			// -from the stored data if present or from the index path if not.
			let sectionKey = keys[indexPath.section]
			guard let sectionData = data[sectionKey] else {
				fatalError("Data not found for key \(sectionKey) from index path \(indexPath)")
			}

			let selectedIndex = isCollapsed(sectionKey) ? valuesSelected[sectionKey]! : indexPath.row
			cell.textLabel?.text = sectionData[selectedIndex]
			cell.detailTextLabel?.text = "\(sectionKey == kGroups ? selectedIndex : selectedIndex - 1)"
		}
		return cell
	}
}

// MARK: - Delegate

extension SpellTargetsViewController: UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Totals section is always visible and never selected.
		if isTotalsSection(indexPath.section) {
			tableView.deselectRow(at: indexPath, animated: false)
			return
		}

		let sectionKey = keys[indexPath.section]
		if isCollapsed(sectionKey) {
			restoreSection(sectionKey)
		} else {
			collapseSection(sectionKey, selectedValue: indexPath.row)
		}
		var indexSet = IndexSet(integer: indexPath.section)
		indexSet.insert(data.count) // The Totals section.
		table.reloadSections(indexSet, with: .automatic)
	}
}

