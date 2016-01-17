# CharSheet-Swift notes and TODOs
## TODOs
[x] Log details should appear linked to the row that triggered them, not at the bottom of the screen.
[ ] Ensure all die rolls are appearing as they should. Ensure they are properly random.
[ ] Where we have empty tables (e.g. Die Roll/Skills) we should have an initial row marked <Add Skill> which the user
	can click on to add the skill. Currently the "+" icon is too far away from the user's attention.
[x] Die roll results should be more readable, possibly in an HTML table or using proper tabbing.
[x] Automatically select the last-used character on startup.
[ ] Associate a GUID with the character so we can tell which character is which even if the name changes.
[x] Find out how Steppers & Input Fields are supposted to work.

## Bugs
[x] When importing a character the date is always added, even if there is no character with that name already.
[x] When rearranging specialties in the Edit view, the old skill cell in the Use view doesn't update.
	Open a character, pick any skill. Note the positions in the 'use' cell. Then go Edit, Skill Info, drag the specialties.
	Close skill info, close main edit page. Note the specialties have not been updated in the 'Use' view.
[x] Disable the Edit, Notes, XP etc. in the Use Controller when there are no characters selected in the table view controller.
[x] Dates in the XML files use the locale-dependent full format, which means you can get crashes reading back older XML files.
    We should use a canonical format, such as YYYY-MM-DD HH:MM which has no ambiguity.
	(We can try and parse the full format as well, for backwards compatibility but only if the canonical format isn't found)
[x] ExtraD4 initial value should default to 1 or be taken from the die roll object.
[x] Cannot remove skill once added to die roll view.
[x] Die Roll view is adding skills instead of updating an existing skill.
[x] Specialty says "Detail" when no specialty provided. Should say nothing.
[x] Automatic loading of last char sheet viewed fails for Portrait as the MasterViewController is not shown.
[x] Rearranging the XP Gain table doesn't persist across quit and restart.
	Note - Core Data's *Ordered* property doesn't seem to persist across restarts. It just says to use an ordered set
	when instanciating the data. So I've added an *order* property to the data and I sort the set on load and update
	the order property on save.

## Ugly files
MasterViewController
DieRoll
DieRollViewController

