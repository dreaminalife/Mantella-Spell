scriptname MantellaQuestChecks hidden

; Functions of the MantellaQuestChecks SKSE plugin (MantellaQuestChecks.dll), which answers the checks behind quest tags.
; Check that the plugin is loaded (MantellaRepository.IsQuestChecksInstalled) before calling them.

; Keeps the check list MantellaSoftware sent, until the next one. The arrays are parallel, one entry per check:
; the game's condition function, what it runs on ("" for the player), and its first and second values
bool function SetCheckList(string version, string[] functions, string[] references, string[] params1, string[] params2) global native
; The version of the list the plugin holds, or "" when it has none
string function GetListVersion() global native
; Answers every check on the list, in about one frame
float[] function Evaluate() global native
