//
//  CombatTargetsViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 04/04/2016.
//  Copyright © 2016 Patrick Wallace. All rights reserved.
//

import UIKit

private let CELL_ID = "SpellTargetsCell"

private let kDimensions = "Dimensions", kDuration = "Duration", kDifficulty = "Difficulty", kDistance = "Distance"

/*

The plan is to have the data hard-coded in an array or in XML or something
and read it into the table.

Dimensions	Distance		Duration	Difficulty
----------  --------		--------	----------
tiny -1		self -1			second -1	trivial -1
small 0		reach 0			minute 0	simple 0
medium 1	stone's throw 1	hour 1		unusual 1
large 2		bowshot 2		day 2		tricky 2
huge 3		perception 3	week 3		finicky 3
*/

// All range from -1 to 3
private let dimensions = ["Tiny"   , "Small" , "Medium"       , "Large"  , "Huge"      ]
private let distance   = ["Self"   , "Reach" , "Stone's throw", "Bowshot", "Perception"]
private let duration   = ["Second" , "Minute", "Hour"         , "Day"    , "Week"      ]
private let difficulty = ["Trivial", "Simple", "Unusual"      , "Tricky" , "Finicky"   ]
private let data = [
	kDimensions: dimensions,
	kDistance  : distance,
	kDuration  : duration,
	kDifficulty: difficulty
]

/// Copy of the keys in data.
///
/// A copy is kept here so the sort ordering will not change
/// and we don't have to re-sort them for each call to the data source.

private let keys = [kDimensions, kDistance, kDuration, kDifficulty]
private typealias ArrayIndex = Int

class SpellTargetsViewController: CharSheetViewController
{
	// MARK: Interface Builder
	@IBOutlet var table: UITableView!

	@IBAction func editDone(sender: AnyObject?)
	{
		assert(presentingViewController != nil)
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}

	// MARK: Overrides

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		valuesSelected.removeAll()
	}

	// MARK: Data

	/// The values selected for each category.
	///
	/// The value is the index into the relevant array of the selected object.
	private var valuesSelected: [String: ArrayIndex] = [:]

	/// This is the final total from all the values selected.
	/// Sections where the user has not yet decided are not included in the total.
	private var finalTotal: Int {
		return valuesSelected.values.reduce(0) { $0 + $1 - 1 }
	}
}

// MARK: - Private support methods

extension SpellTargetsViewController
{

	/// Returns true if the index path refers to the totals section.
	/// False if it refers to one of the data sections.
	private func isTotalsSection(sectionIndex: ArrayIndex) -> Bool
	{
		assert(sectionIndex >= 0 || sectionIndex <= data.count, "section index \(sectionIndex) is out of range.")
		return sectionIndex >= data.count
	}

	/// Returns true if the given section has been collapsed because the user has specified a value.
	private func isCollapsed(sectionId: String) -> Bool
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		return valuesSelected[sectionId] != nil
	}

	/// Collapse the section specified as the user has specified one of the values to use.
	///
	/// - parameter sectionId: The string ID of the section to collapse
	/// - parameter selectedIndex: The index into the relevant array of the value the user selected.
	private func collapseSection(sectionId: String, selectedValue: ArrayIndex)
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		assert(selectedValue >= 0 || selectedValue < 4, "selected value \(selectedValue) is out of range.")
		valuesSelected[sectionId] = selectedValue
	}

	/// Expand the section specified.
	/// This occurs if the user changes hir mind and wants to pick from the list again.
	///
	/// - parameter sectionId: The string ID of the section to expand.  
	///
	/// The user's choice is deleted and the section will be shown when the table is viewed again.
	private func restoreSection(sectionId: String)
	{
		assert(keys.contains(sectionId), "Invalid section ID \(sectionId)")
		valuesSelected[sectionId] = nil
	}
}

// MARK: - Data Source

extension SpellTargetsViewController: UITableViewDataSource
{
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		// All the data sections and a totals section at the end.
		return data.count + 1
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return isTotalsSection(section) ? "Total" : keys[section]
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		// The final totals section and all collapsed sections always just have one row.
		if isTotalsSection(section) || isCollapsed(keys[section]) {
			return 1
		}
		return  data[keys[section]]!.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID) ?? UITableViewCell()

		if isTotalsSection(indexPath.section) {
			cell.textLabel?.text = "Final total: "
			cell.detailTextLabel?.text = "\(finalTotal)"
		} else {
			// Find the key for the section, then get the index of the cell
			// -from the stored data if present or from the index path if not.
			let sectionKey = keys[indexPath.section]
			guard let sectionData = data[sectionKey] else {
				fatalError("Data not found for key \(sectionKey) from index path \(indexPath)")
			}

			let selectedIndex = isCollapsed(sectionKey) ? valuesSelected[sectionKey]! : indexPath.row
			cell.textLabel?.text = sectionData[selectedIndex]
			cell.detailTextLabel?.text = "\(selectedIndex - 1)"
		}
		return cell
	}
}

// MARK: - Delegate

extension SpellTargetsViewController: UITableViewDelegate
{
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		// Totals section is always visible and never selected.
		if isTotalsSection(indexPath.section) {
			tableView.deselectRowAtIndexPath(indexPath, animated: false)
			return
		}

		let sectionKey = keys[indexPath.section]
		if isCollapsed(sectionKey) {
			restoreSection(sectionKey)
		} else {
			collapseSection(sectionKey, selectedValue: indexPath.row)
		}
		let indexSet = NSMutableIndexSet(index: indexPath.section)
		indexSet.addIndex(data.count) // The Totals section.
		table.reloadSections(indexSet, withRowAnimation: .Automatic)
	}
}

