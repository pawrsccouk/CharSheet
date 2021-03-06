//
//  PWDieRoll.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//  This holds the various stats and skills that make up a die roll, and then performs the rolling.

import Foundation
import CoreData

private enum State
{
	case preparing
	case rolled(
		// The result as an HTML format string for display to the user
		resultForDisplay: String,
		// The result as a simple string for displaying in the log.
		resultForLog: String)
}

/// This object handles one roll of the dice, including both the stats and skills to roll and the final result.
///
/// It contains input properties to specify which stats and skills to include.
/// Once you call the roll() method, it also contains output properties indicating the result of the roll.
/// Primarily you use the *total* field to get the final value and the *resultAsHTML* field to get the final result
/// formatted to display to the user.

@objc class DieRoll : NSObject
{
    // MARK: Input Properties

	typealias StatInfo = (name: String, value: Int16)

	/// The stat whose value (if set) will be added to the die roll.
    var stat: StatInfo? {
        didSet {
            state = .preparing
        }
    }

	/// Set of skills whose values will be rolled and included in this die roll.
    var skills: MutableOrderedSet<Skill> = MutableOrderedSet() {
        didSet {
            state = .preparing
            assert( skills.array.filter{ $0.name == nil }.isEmpty, "All skills must have a name." )
        }
    }

	/// A total value to be added to the final die roll.
    @objc dynamic var adds: Int = 0 {
        didSet {
            state = .preparing
        }
    }

	/// A collection of specialties to be included when making the die roll.
	///
	/// This is a dictionary whose key is the name of the skill and whose value is the specialty selected.
	/// If there is no value for a given key, it means that skill had no specialty or the specialty wasn't relevant.
    dynamic var specialties: [String: Specialty] = [:] {
        didSet {
            state = .preparing
        }
    }

	/// Any extra D4s to roll and add to the total.
	///
	/// The default is usually 1d4 per roll, except for magic skills.
	/// However this can vary and some GMs will add extra d4s as a circumstance bonus so the user can specify it here.
    @objc dynamic var extraD4s: Int16 = 1 {
        didSet {
            state = .preparing
        }
    }
    
    var charSheet: CharSheet!

	var resultAsHTML: String {
		switch state {
		case .rolled(let (resultForDisplay, _)):
			return resultForDisplay
		case .preparing:
			assert(false, "Invalid state: Cannot call resultAsHTML until the dice have been rolled.")
		}
	}

	fileprivate var state: State = .preparing


    // MARK: - Housekeeping

    convenience init(charSheet: CharSheet) {
        self.init()
        self.charSheet = charSheet
    }

    override init() {
        super.init()
        state = .preparing
    }
    
    // MARK: Public API

	/// Create a new LogEntry object containing the stats and skills rolled on and the result of the roll.
	/// The log entry is added to Core Data automatically.
    func addLogEntry() -> LogEntry
	{
		switch state {
		case .rolled(let (_, resultForLog)):
			let entry = charSheet.addLogEntry()
			entry.summary = getSummary()
			entry.change  = resultForLog
			return entry;
		case .preparing:
			assert(false, "Invalid state: Can't add log entry until the dice have been rolled.")
		}
    }

	/// Roll the D6s and D4s requested and store the results.
	func roll()
	{
		/// Rolls a die with numSides sides and returns the result.
		func rollDie(_ numSides: UInt32) -> Int16
		{
			return Int16(arc4random() % numSides) + 1
		}
		/// Simulate rolling 2D6, optionally rerolling on a double.
		/// Rolling a botch (2+1 or 1+2) will abort immediately.
		///
		/// - parameter doublesReroll: If true and the dice both have the same value, then roll the dice again
		///                       and include the result. This can happen repeatedly.
		/// - returns: An array holding all the die rolls that were made.
		func rollD6(_ doublesReroll: Bool) -> [Int16]
		{
			var results: [Int16] = [], firstRoll = true, n1 = Int16(0), n2 = Int16(0)
			repeat {
				(n1, n2) = (rollDie(6), rollDie(6))
				results.append(n1)
				results.append(n2)

				// If the first roll was a botch, then return immediately.
				if firstRoll && isBotch(results) {
					return results
				}
				firstRoll = false
			} while doublesReroll && n1 == n2
			return results
		}

		// Using arc4random now, which is automatically seeded.
		//srand(UInt32(Date.timeIntervalSinceReferenceDate))

		// D6 rolls
		let d6Rolls = rollD6(true)
		// D4 rolls.
		var dieRollsPerSkill: [String: [Int16]] = [:]
		for skill in self.skills.array {
			// Zero-value skills are allowed. They roll no dice but avoid failure penalties.
			if skill.value == 0 {
				dieRollsPerSkill[skill.name!] = []
			} else {
				dieRollsPerSkill[skill.name!] = (1...skill.value).map { (_) in rollDie(4) }
			}
		}
		let extraD4Rolls = (extraD4s > 0) ? (1...extraD4s).map { (_) in rollDie(4) } : []
		// Totals and display values.
		let total      = calculateTotal(d6Rolls, dieRollsPerSkill: dieRollsPerSkill, extraD4Rolls: extraD4Rolls)
		let htmlResult = showResultAsHTML(total, d6Rolls: d6Rolls, dieRollsPerSkill: dieRollsPerSkill, extraD4Rolls: extraD4Rolls)
		let logResult  = getLogDetail(total, d6Rolls: d6Rolls, dieRollsPerSkill: dieRollsPerSkill, extraD4Rolls: extraD4Rolls)

		state = State.rolled(resultForDisplay: htmlResult, resultForLog: logResult)
	}



    // MARK: Private API

	/// Converts characters in the input which would interferere with HTML formatting
	/// into the equivalent escape sequences.
	///
	/// - parameter   input: A string to convert. This must not include any HTML markup
	///                 as it will be replaced with &lt; &gt; etc.
	/// - returns: A string suitable to be embedded in an HTML document.
    fileprivate func sanitiseHTML(_ input: String) -> String
	{
        let output = NSMutableString(capacity: input.count)
        for c in input {
            switch c {
            case "<" : output.append("&lt;" )
            case ">" : output.append("&gt;" )
            case "&" : output.append("&amp;")
            case "\n": output.append("<br/>")
            default  : output.append("\(c)")
            }
        }
        return output as String
    }

	/// Returns true if the first two die rolls in the array provided indicate a botch.
	///
	/// - parameter d6Rolls: An array holding at least 2 integers, each being the result of a d6 roll.
    fileprivate func isBotch(_ d6Rolls: [Int16]) -> Bool
	{
        assert(d6Rolls.count >= 2, "Not enough d6")
        return d6Rolls[0] + d6Rolls[1] == 3
    }
    

	/// Returns a summary of a die roll suitable for adding to the logs.
	///
	/// - returns: A text string in the format: "stat + skill1/skill2..."
	///           It will fit on one line.
	fileprivate func getSummary() -> String
	{
		var statStr  = "No stat"
		if let statName = stat?.name {
			var prefix = String(statName[..<statName.index(statName.startIndex, offsetBy: 3)])
			switch prefix {
			case "Luc": prefix = "Lck"
			case "Spe": prefix = "Spd"
			default: break;
			}
			statStr = prefix
		}
		let skillNames = skills.array.map{ obj in (obj as Skill).name! }
		let skillStr = skillNames.joined(separator: "/")
		return "\(statStr) + \(skillStr)"
	}


	/// Returns the detail text of a die roll in a short format for adding to the logs.
	///
	/// - returns: A multi-line text string with the full detail of the roll.
	fileprivate func getLogDetail(
		_ total: Int16,
		d6Rolls: [Int16],
		dieRollsPerSkill: [String: [Int16]],
		extraD4Rolls: [Int16]) -> String
	{
        func summariseSkillRoll(_ skill: Skill) -> String
		{
            var d4Rolls: [Int16] = []
            if let dieRollsForSkill = dieRollsPerSkill[skill.name!] {
                d4Rolls = dieRollsForSkill
            }
            let d4rollStr = d4Rolls.map{ $0.description }.joined(separator: " + ")
            var specValue: Int16 = 0
            if let spec = specialties[skill.name!] {
                specValue = spec.value
            }
            return "\(skill.name!): \(d4rollStr) (+\(specValue))"
            
        }

		var statText = "Stat: None"
		if let s = stat {
			statText = "Stat: \(s.name) = \(s.value)"
		}
        let d6s     = d6Rolls.map{ $0.description }.joined(separator: " + ")
        let d6str   = "D6 Rolls: \(d6s)"
        let skillResults = skills.array.map(summariseSkillRoll)
        let skillStr = skillResults.joined(separator: "\n")

		let extraD4Text = extraD4Rolls.map{ "\($0)" }.joined(separator: " + ")

		return "\(d6str)\n\(statText)\n\(skillStr)\nExtraD4s: \(extraD4Text)\nAdds: \(adds)\nTotal: \(total)"
    }
    
	/// Returns an HTML document with the contents of the last die roll in a readable format.
	///
	/// This doesn't trigger a die roll, just provides a detailed description of the last roll made.
	fileprivate func showResultAsHTML(
		_ total  : Int16,
		d6Rolls: [Int16],
		dieRollsPerSkill: [String: [Int16]],
		extraD4Rolls    : [Int16]) -> String
	{
		let log = NSMutableString()
		log.append("<html><head/><style>")
		log.append("div { margin-left: 25px; }")
		log.append("span { margin-left: 25px; }")
		log.append(".botch { color: red; }")
		log.append("</style><body>")
		log.append("<b>D6 Roll:</b><br/>")

		// For the D6 rolls, first check for a botch and return immediately if so.
		if isBotch(d6Rolls) {
			log.append("<div>\(d6Rolls[0]) + \(d6Rolls[1]) (<b class=botch>Botch!</b>)</div></body></html>")
			return log.description
		}

		// Format the D6 rolls.
		assert(d6Rolls.count % 2 == 0, "Uneven number of d6 rolls")
		let d6Results: [String] = group(2, collection: d6Rolls).map {
			let doubleStr = ($0[0] == $0[1] ? " (Double!)" : "")
			return "\($0[0]) + \($0[1])\(doubleStr)"
		}
		log.append("<div>")
		log.append(d6Results.joined(separator: ", "))
		let d6Total = d6Rolls.reduce(0) { $0 + $1 }
		log.append("&nbsp;&nbsp;= \(d6Total)</div>")

		// Add the stat if necessary.
		if let si = stat {
			log.append("<b>Stats:</b><br/><div>\(si.name) = \(si.value)</div>")
		}
		// Now add the skill rolls.
		if skills.count > 0 {
			log.append("<b>Skills:</b><br/><div>")
			let skillLines = skills.array.map { (skill) -> String in
				if let skillName = skill.name {
					let rollsForSkill: [Int16] = dieRollsPerSkill[skillName] ?? []
					var specStr    = "", finalTotal = Int16(0)
					if let specialty = self.specialties[skillName] {
						let specName = specialty.name ?? "No name"
						specStr = "<br/><span>(+ \(specName) = \(specialty.value))</span>"
					}
					finalTotal += rollsForSkill.reduce(0) { $0 + $1 }
					let rollsText = rollsForSkill.map{$0.description}.joined(separator: " + ")
					let safeName = self.sanitiseHTML(skillName)
					if rollsForSkill.isEmpty { // Zero-level skills. Don't show the rolls as there aren't any.
						return "\(safeName) (\(rollsForSkill.count)) = \(finalTotal) \(specStr)"
					} else {
						return "\(safeName) (\(rollsForSkill.count)) = \(rollsText) = \(finalTotal) \(specStr)"
					}
				} else {
					fatalError("Skill \(skill) has no name!")
				}
			}
			log.append(skillLines.joined(separator: "<br/>"))
			log.append("</div>")
		}

		// Add extra d4s.
		if extraD4s != 0 {
			let extraD4Text = extraD4Rolls.map{"\($0)"}.joined(separator: " + ")
			let extraD4Value = extraD4Rolls.reduce(0) { $0 + $1 }
			log.append("<b>Extra D4s:</b><br/><div>\(extraD4Text) = \(extraD4Value)</div>")
		}

		// Add any final adds.
		if(adds != 0) {
			log.append("<b>Adds:</b><br/><div>\(adds)</div><br/>")
		}
		log.append("<br/><hr/>")
		log.append("<b>Total = \(total)</b>")
		log.append("</body></html>")
		return log.description
	}

	/// The total value of all the rolled dice, stats and static adds used for this roll.
	fileprivate func calculateTotal(
		_ d6Rolls: [Int16],
		dieRollsPerSkill: [String: [Int16]],
		extraD4Rolls: [Int16]) -> Int16
	{
		if isBotch(d6Rolls) { return 0 }
		var total = d6Rolls.reduce(0) { $0 + $1 }

		if let s = stat {
			total += s.value
		}
		for skill in skills.array {
			if let skillName = skill.name {
				if let rolls = dieRollsPerSkill[skillName] {
					total += rolls.reduce(0) { $0 + $1 }
				}
				if let spec = specialties[skillName] {
					total += spec.value
				}
			} else { fatalError("Skill \(skill) has no name!") }
		}
		total += Int16(adds)
		total += extraD4Rolls.reduce(0) { $0 + $1 }
		return total
	}
}

/// Given an array, split it into groups and return an array of all the groups.
///
/// - parameter groupSize: The size of each group. Must be greater than zero or we return an empty array.
/// - parameter collection: The collection to split into groups.
///
/// If the number of items in the collection isn't an exact multiple of *groupSize*
/// then the remaining items are simply ignored.  For example:
///   group(2, [1, 2, 3, 4]) would return [[1, 2], [3, 4]]
///   group(2, [1, 2, 3]) would return [[1, 2]] and 3 would be missing.
///
/// - todo: Switch to using sequences instead of fixed arrays. Currently it requires the size of the array
///   so it cannot be lazy.
func group<T>(_ groupSize: Int, collection: Array<T>) -> [Array<T>]
{
	assert(groupSize > 0, "groupSize(\(groupSize)) must be greater than zero")
	if groupSize <= 0 { return [] }

	var result: [Array<T>] = []
	let count = collection.count
	for i in stride(from: 0, to: count, by: groupSize) {
		// If we have enough entries to make a full group, then
		// copy the values out of the slice and into a home of their own.
		if i + (groupSize - 1) < count {
			var arr: [T] = []
			for t in collection[i...i+(groupSize-1)] { arr.append(t) }
			result.append(arr)
		}
	}
	return result
}



