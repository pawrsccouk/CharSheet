//
//  PWDieRoll.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//  This holds the various stats and skills that make up a die roll, and then performs the rolling.

import Foundation
import CoreData

/// This object handles one roll of the dice, including both the stats and skills to roll and the final result.
///
/// It contains input properties to specify which stats and skills to include.
/// Once you call the roll() method, it also contains output properties indicating the result of the roll.
/// Primarily you use the *total* field to get the final value and the *resultAsHTML* field to get the final result
/// formatted to display to the user.
class DieRoll : NSObject
{
    // MARK: - Input Properties

	typealias StatInfo = (name: String, value: Int16)

	/// The stat whose value (if set) will be added to the die roll.
    var stat: StatInfo? {
        didSet {
            resetResults()
        }
    }

	/// Set of skills whose values will be rolled and included in this die roll.
    var skills: MutableOrderedSet<Skill> = MutableOrderedSet() {
        didSet {
            resetResults()
            assert( skills.array.filter{ $0.name == nil }.isEmpty, "All skills must have a name." )
        }
    }

	/// A total value to be added to the final die roll.
    dynamic var adds: Int = 0 {
        didSet {
            resetResults()
        }
    }

	/// A collection of specialties to be included when making the die roll.
	///
	/// This is a dictionary whose key is the name of the skill and whose value is the specialty selected.
	/// If there is no value for a given key, it means that skill had no specialty or the specialty wasn't relevant.
    dynamic var specialties: [String: Specialty] = [:] {
        didSet {
            resetResults()
        }
    }

	/// Any extra D4s to roll and add to the total.
	///
	/// The default is usually 1d4 per roll, except for magic skills.
	/// However this can vary and some GMs will add extra d4s as a circumstance bonus so the user can specify it here.
    dynamic var extraD4s: Int16 = 1 {
        didSet {
            resetResults()
        }
    }
    
    var charSheet: CharSheet!

    // MARK: Output Properties
    
    // These values are only available after the die roll.

	/// The result of the d6s rolled.
    var d6Rolls: [Int16] = []

	/// The result of the d4s rolled for the each skill.
	///
	/// This is a dictionary. The key is the name of the skill and each value is an array of d4 roll results.
    var dieRollsPerSkill: [String: [Int16]] = [:]

	/// The result of any extra D4s rolled.
    var extraD4Rolls: [Int16] = []
    
	/// Returns an HTML document with the contents of the last die roll in a readable format.
	///
	/// This doesn't trigger a die roll, just provides a detailed description of the last roll made.
    var resultAsHTML: String {
        get {
            var log = NSMutableString()
            log.appendString("<html><head/><body>")
            log.appendString("D6 Roll:<br/>")
            
            // For the D6 rolls, first check for a botch and return immediately if so.
            if isBotch(d6Rolls) {
                return "\(d6Rolls[0]) + \(d6Rolls[1]) (Botch!)"
            }
            
            // Format the D6 rolls.
            assert(d6Rolls.count % 2 == 0, "Uneven number of d6 rolls")
            var d6Total = Int16(0)
            log.appendString(spacing)
            for var i = 0, c = d6Rolls.count; i < c; i += 2 {
                let n1 = d6Rolls[i], n2 = d6Rolls[i+1]
                var isDouble = n1 == n2
                if i > 0 {
                    log.appendString(", ")
                }
                let doubleStr = isDouble ? "(Double!)" : ""
                log.appendString("\(n1) + \(n2) \(doubleStr)")
                d6Total += n1 + n2
            }
            log.appendString("&nbsp;&nbsp;= \(d6Total)<br/>")
            
            // Add the stat if necessary.
            if let si = stat {
                log.appendString("Stats: <br/>\(spacing)\(si.name) = \(si.value)<br/>")
            }
            // Now add the skill rolls.
            if skills.count > 0 {
                log.appendString("Skills:<br/>")
                
                for skill in skills.array {
					assert(skill.name != nil, "Skill \(skill) has no name")
					let skillName = skill.name!
                    let spec = specialties[skillName]
                    
                    let rollsForSkill: [Int16] = dieRollsPerSkill[skillName] ?? []
                    let skillRollStr = formatSkillRoll(skill, rolls: rollsForSkill, spec: spec)
                    log.appendString("\(spacing)\(skillRollStr)<br/>")
                }
            }

			// Add extra d4s.
			let extraD4Text = " + ".join(extraD4Rolls.map{"\($0)"})
			let extraD4Value = extraD4Rolls.reduce(0) { $0 + $1 }
			log.appendString("Extra D4s:&nbsp;\(extraD4Text) = \(extraD4Value)<br/>")

            // Add any final adds.
            if(adds != 0) {
                log.appendString("Adds:<br/>\(spacing)+ \(adds)<br/>")
            }
            log.appendString("<br/><hr/>")
            log.appendString("<b>Total = \(total)</b>")
            log.appendString("</body></html>")
            return log.description
        }
    }
    
	/// The total value of all the rolled dice, stats and static adds used for this roll.
	///
	/// This doesn't trigger a die roll, just summarises the results of the last roll.
    var total: Int16 {
        get {
            if isBotch(d6Rolls) { return 0 }
            var total = d6Rolls.reduce(0) { $0 + $1 }
            
            if let s = stat {
                total += s.value
            }
            for skill in skills.array {
				assert(skill.name != nil, "Skill \(skill) has no name.")
				let skillName = skill.name!
                if let rolls = dieRollsPerSkill[skillName] {
                    total += rolls.reduce(0) { $0 + $1 }
                }
                if let spec = specialties[skillName] {
                    total += spec.value
                }
            }
            total += adds
			total += extraD4Rolls.reduce(0) {$0 + $1}
            return total
        }
    }
    
    
    // MARK: - Housekeeping
    
    convenience init(charSheet: CharSheet) {
        self.init()
        self.charSheet = charSheet
        resetResults()
    }
    
    override init() {
        super.init()
        resetResults()
    }
    
    // MARK: Public API

	/// Create a new LogEntry object containing the stats and skills rolled on and the result of the roll.
	/// The log entry is added to Core Data automatically.
    func addLogEntry() -> LogEntry
	{
        var entry = charSheet.addLogEntry()
        entry.summary = getSummary()
        entry.change  = getLogDetail()
        return entry;
    }
    
	/// Roll the D6s and D4s requested and store the results in this object.
	///
	/// :todo: Make this into an enum state machine.
	func roll()
	{
		var intSeed: UInt32 = UInt32(NSDate.timeIntervalSinceReferenceDate())
		srand(intSeed)
		resetResults()

		// D6 rolls
		d6Rolls += rollD6(true)
		// D4 rolls.
		for skill in self.skills.array {
			let d4Results = rollD4(Int16(skill.value))
			dieRollsPerSkill[skill.name!] = d4Results
		}
		extraD4Rolls = rollD4(self.extraD4s)
		// Fixed values (stat & specialties) don't need to be handled here.
	}



    // MARK: Private API

	/// Return this object to it's pre-rolled state, i.e. remove the results of all die rolls.
	/// The fields indicating which skills to roll on are preserved.
    private func resetResults()
	{
        d6Rolls = []
        dieRollsPerSkill = [:]
    }
    
    
    
	/// Converts characters in the input which would interferere with HTML formatting
	/// into the equivalent escape sequences.
	/// :param: input Any string.
	/// :returns: A string suitable to be embedded in an HTML document.
    private func sanitiseHTML(input: String) -> String
	{
        var output = NSMutableString(capacity: count(input))
        for c in input {
            switch c {
            case "<" : output.appendString("&lt;" )
            case ">" : output.appendString("&gt;" )
            case "&" : output.appendString("&amp;")
            case "\n": output.appendString("<br/>")
            default  : output.appendString("\(c)")
            }
        }
        return output as String
    }
    
    
    
	/// Returns an HTML String containing a one-line formatted result of a skill roll.
	/// This includes the name and value of the skill, any specialties used and the actual result of the roll.
	///
	/// :param: skill The skill that was rolled.
	/// :param: rolls An array containing the result of each die roll used to roll the skill.
	/// :param: spec  Optionally the specialty that was used in the roll.
    private func formatSkillRoll(skill: Skill, rolls: [Int16], spec: Specialty?) -> String
	{
        var skillTotal = rolls.reduce(0) { $0 + $1 }
        var specStr    = "", finalTotal = Int16(0)
        if let specialty = spec {
            specStr = String(format:"(+ %d)", specialty.value)
            finalTotal += specialty.value
        }
        finalTotal += skillTotal
		let skillName = skill.name!, rollsText = " + ".join(rolls.map{$0.description})
        return String(format:"%@ (%d) = %@ %@ = %d",
			sanitiseHTML(skillName), rolls.count, rollsText, specStr, finalTotal)
    }

    
	/// Returns true if the first two die rolls in the array provided indicate a botch.
	///
	/// :param: d6Rolls An array holding at least 2 integers, each being the result of a die roll.
    private func isBotch(d6Rolls: [Int16]) -> Bool
	{
        assert(count(d6Rolls) >= 2, "Not enough d6")
        return d6Rolls[0] + d6Rolls[1] == 3
    }
    
    
    
    
    private let spacing = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    
	/// Returns a summary of a die roll suitable for adding to the logs.
	private func getSummary() -> String
	{
		var statStr  = "<No stat>"
		if let statName = stat?.name {
			var prefix = statName.substringToIndex(advance(statName.startIndex, 3))
			if prefix == "Luc" {
				prefix = "Lck"
			}
			statStr = prefix
		}
		var skillNames: NSArray = skills.array.map{ obj in (obj as Skill).name! }
		var skillStr = skillNames.componentsJoinedByString("/")
		return "\(statStr) + \(skillStr)"
	}



	/// Returns the detail text of a die roll in a short format for adding to the logs.
    private func getLogDetail() -> String
	{
        func summariseSkillRoll(skill: Skill) -> String
		{
            var d4Rolls: [Int16] = []
            if let dieRollsForSkill = dieRollsPerSkill[skill.name!] {
                d4Rolls = dieRollsForSkill
            }
            let d4rollStr = " + ".join(d4Rolls.map{ $0.description })
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
        let d6s     = " + ".join(d6Rolls.map{ $0.description })
        let d6str   = "D6 Rolls: \(d6s)"
        let skillResults: NSArray = skills.array.map(summariseSkillRoll)
        let skillStr = skillResults.componentsJoinedByString("\n")

		let extraD4Text = " + ".join(extraD4Rolls.map{ "\($0)" })

        return "\(d6str)\n\(statText)\n\(skillStr)\nExtraD4s: \(extraD4Text)\nAdds: \(adds)\nTotal: \(total)"
    }
    
	/// Simulate rolling 2D6, optionally rerolling on a double.
	/// Rolling a botch (2+1 or 1+2) will abort immediately.
	///
	/// :param: doublesReroll If true and the dice both have the same value, then roll the dice again
	///                       and include the result. This can happen repeatedly.
	/// :returns: An array holding all the die rolls that were made.
    private func rollD6(doublesReroll: Bool) -> [Int16]
	{
        var results: [Int16] = []
        var firstRoll = true
        var n1 = Int16(0), n2 = Int16(0)
        
        do {
            n1 = Int16(rand() % 6) + 1
            n2 = Int16(rand() % 6) + 1
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
    
    
    
	/// Simulate rolling a number of 4-sided dice. 
	///
	/// :param: numToRoll The number of dice to roll.
	/// :returns: An array holding the results of each die roll.
    private func rollD4(numToRoll: Int16) -> [Int16]
	{
        var results: [Int16] = []
        for var i: Int16 = 0, c: Int16 = numToRoll; i < c; ++i {
            results.append((Int(rand()) % 4) + 1)
        }
        return results
    }
    
}
