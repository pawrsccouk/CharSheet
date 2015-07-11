# CharSheet-Swift notes and TODOs
## TODOs
[ ] Log details should appear linked to the row that triggered them, not at the bottom of the screen.
[ ] Ensure all die rolls are appearing as they should. Ensure they are properly random.
[ ] Where we have empty tables (e.g. Die Roll/Skills) we should have an initial row marked <Add Skill> which the user
can click on to add the skill. Currently the "+" icon is too far away from the user's attention.
[ ] Die roll results should be more readable, possibly in an HTML table or using proper tabbing.
[x] Automatically select the last-used character on startup.
[ ] Associate a GUID with the character so we can tell which character is which even if the name changes.

## Bugs
[x] ExtraD4 initial value should default to 1 or be taken from the die roll object.
[x] Cannot remove skill once added to die roll view.
[x] Die Roll view is adding skills instead of updating an existing skill.
[x] Specialty says "Detail" when no specialty provided. Should say nothing.