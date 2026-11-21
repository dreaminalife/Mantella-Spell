Scriptname MantellaHeardLines Hidden

; Functions of the MantellaHeardLines SKSE plugin (MantellaHeardLines.dll), which catches the voiced lines NPCs speak in the game.
; Check that the plugin is loaded (MantellaRepository.IsHeardLinesInstalled) before calling them.

; Hands the plugin its settings (see MantellaRepository.SendHeardLinesSettings). It catches nothing until it has them once.
; Returns false and changes nothing if hearingDistance (game units) or mostWaiting is 0 or less
Bool Function SetSettings(Bool catchLines, Bool nearbyOverhear, Float hearingDistance, Int mostWaiting) Global Native
; The lines caught since the last call, as JSON text. Always JSON with the game's time, even when no lines wait, so Mantella can
; tell when an older save was loaded. The plugin forgets the lines once handed over
String Function TakeLines() Global Native
