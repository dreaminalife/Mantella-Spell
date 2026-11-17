scriptname MantellaVoiceClips hidden

; Functions of the MantellaVoiceClips SKSE plugin (MantellaVoiceClips.dll), which copies voice lines from the game files
; for MantellaSoftware's voice services. Check that the plugin is loaded (MantellaRepository.IsVoiceClipsInstalled) before calling them.

; The file name of the plugin that adds the form (Skyrim.esm), or "" when it has none
string function GetSourcePlugin(Form akForm) global native
; The form's ID inside that plugin, without the load order part
int function GetLocalFormID(Form akForm) global native
; Copies the voice lines a request from MantellaSoftware asks for, in the background. When done, the plugin sends the
; Mantella_VoiceClipsDone mod event with the request's ID and the number of lines copied (0: none found, -1: failed).
; False when the request can't be read
bool function FetchClips(string requestJson) global native
