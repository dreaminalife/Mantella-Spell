Scriptname MantellaRepository extends Quest Conditional

Actor Property PlayerRef Auto

Spell property MantellaSpell auto
Spell property MantellaRemoveNpcSpell auto
Spell Property MantellaEndSpell auto
;Faction Property giafac_Sitters  Auto ;gia
;Faction Property giafac_Sleepers  Auto ;gia
;Faction Property giafac_talktome  Auto ;gia
Faction Property giafac_AllowFollower  Auto ;gia
Faction Property giafac_AllowAnger  Auto ;gia
;Faction Property giafac_AllowForgive  Auto ;gia
Faction Property fac_AllowInventory  Auto
Faction Property giafac_AllowDialogue  Auto ;gia
Faction Property giafac_Following  Auto ;gia
Faction Property giafac_Mantella  Auto ;gia
quest property gia_FollowerQst auto ;gia


bool property microphoneEnabled auto
bool property useHotkeyToStartMic auto
float property MantellaEffectResponseTimer auto
bool property showReminderMessages auto

int property MantellaStartHotkey auto
int property MantellaListenerTextHotkey auto
int property MantellaEndHotkey auto
int property MantellaCustomGameEventHotkey auto
int property MantellaRadiantHotkey auto
int property MantellaInterruptHotkey auto
int property MantellaNpcInitiativeHotkey auto
int property MantellaNpcEventHotkey auto
int property MantellaWheelHotkey auto

bool property showDialogueItems auto Conditional

bool property radiantEnabled auto
float property radiantDistance auto
float property radiantFrequency auto
bool property showRadiantDialogueMessages auto

bool property npcInitiativeEnabled auto
bool property npcInitiativeOnLocationChange auto
float property npcInitiativeIdleMinutes auto
float property npcInitiativeMinInterval auto
float property npcInitiativeSettleDelay auto
float property npcInitiativeMaxDistance auto
int property npcInitiativeMaxCandidates auto
bool property npcInitiativeIncludeFollowers auto
int property npcInitiativeMaxFollowers auto
bool property npcInitiativeIgnoreLineOfSight auto
bool property showNpcInitiativeMessages auto
bool property npcInitiativeHotkeySkipsThreshold auto

bool property npcEventEnabled auto
float property npcEventFrequency auto ; Minutes
float property npcEventHearingDistance auto ; Meters
bool property npcEventRequireLineOfSight auto
bool property npcEventIncludeFollowers auto ; On by default. A follower in a scene follows the player, so walking away doesn't end it: the scene's line limit does
int property npcEventMaxCandidates auto ; Most People Described: the nearest people the event generator gets the bios and memories of
bool property showNpcEventMessages auto
bool property npcEventAskForHint auto ; A text box asks what should happen when the player starts an NPC Event

; Conversation, Nearby and Random Events: picked on the Conversation Wheel during a conversation. Set up on the Events page.
; Send the Conversation So Far and Include Me are Mantella's own settings (Conversation page)
bool property conversationEventAskForHint auto
bool property nearbyEventAskForHint auto
int property nearbyEventMaxDescribed auto
bool property nearbyEventIncludeFollowers auto
bool property randomEventAskForHint auto
int property randomEventMaxDescribed auto
bool property randomEventIncludeFollowers auto
bool property eventDefaultsAssigned auto ; False on a save the version 18 update never reached, see EnsureEventDefaults
bool property eventFollowerDefaultsAssigned auto ; False on a save that never got the version 20 follower defaults, see EnsureEventDefaults
; Show What Happened on the Events page, one per kind of event, stored the other way round: false (the value of a save that never set it)
; shows the event in a message box, so no default has to be assigned
bool property npcEventHideText auto
bool property conversationEventHideText auto
bool property nearbyEventHideText auto
bool property randomEventHideText auto

; Shout: switched on from the Conversation Wheel. See MantellaShout.
; Most People in Conversation, People Who Must Answer a Group Line and Newcomers Remember are Mantella's own settings (Conversation page)
bool property showShoutMessages auto
float property shoutHearingDistance auto ; Meters
int property shoutMaxCandidates auto ; Most People Described: the nearest people the Game Master gets the bios and memories of
int property shoutMaxListed auto ; Most People Listed: the nearest people the Game Master may pick, by name
bool property shoutRequireLineOfSight auto
; Include Followers on the Shout Mode page, stored the other way round: false (the value of a save that never set it) lets followers join, as before
bool property shoutExcludeFollowers auto

string property playerCharacterDescription1 auto
string property playerCharacterDescription2 auto
bool property playerCharacterUsePlayerDescription2 auto
bool property playerCharacterVoicePlayerInput auto
string property playerCharacterVoiceModel auto
bool property playerTrackingUsePCName auto


bool property playerTrackingOnItemAdded auto
bool property playerTrackingOnItemRemoved auto
bool property playerTrackingOnSpellCast auto
bool property playerTrackingOnHit auto
bool property playerTrackingOnObjectEquipped auto
bool property playerTrackingOnObjectUnequipped auto
bool property playerTrackingOnPlayerBowShot auto
bool property playerTrackingOnSit auto
bool property playerTrackingOnGetUp auto

bool property playerTrackingOnLocationChange auto
bool property playerTrackingOnTimeChange auto
bool property playerTrackingOnWeatherChange auto
float property eventRepeatCooldown auto ; Seconds before the same hit, spell cast or bow shot can be added again


bool property playerEquipmentBody auto
bool property playerEquipmentHead auto
bool property playerEquipmentHands auto
bool property playerEquipmentFeet auto
bool property playerEquipmentAmulet auto
bool property playerEquipmentRightHand auto
bool property playerEquipmentLeftHand auto

int property worldID auto


bool property targetTrackingItemAdded auto 
bool property targetTrackingItemRemoved auto
bool property targetTrackingOnSpellCast auto
bool property targetTrackingOnHit auto
bool property targetTrackingOnCombatStateChanged auto
bool property targetTrackingOnObjectEquipped auto
bool property targetTrackingOnObjectUnequipped auto
bool property targetTrackingOnSit auto
bool property targetTrackingOnGetUp auto
bool property targetTrackingAngerState auto

bool property targetEquipmentBody auto
bool property targetEquipmentHead auto
bool property targetEquipmentHands auto
bool property targetEquipmentFeet auto
bool property targetEquipmentAmulet auto
bool property targetEquipmentRightHand auto
bool property targetEquipmentLeftHand auto

bool property enableVanillaDialogueAwareness auto ; read by the Mantella Vanilla Dialogue SKSE plugin
bool property AllowForNPCtoFollow auto ;gia
;bool property followingNPCsit auto ;gia
;bool property followingNPCsleep auto ;gia
;bool property NPCstopandTalk auto ;gia
bool property NPCAnger auto ;gia
bool property NPCInventory auto
bool property NPCPackage auto Conditional
;bool property NPCForgive auto ;gia
bool property NPCDialogue auto ;gia

bool property NPCdebugSelectModeEnabled auto
; bool restartMantellaExe = False
int property HttpPort auto
int property eventTestRun auto ; Set to 1 from the console (setpqv MantellaQuest eventTestRun 1) to run the in-game test of the events. See MantellaEventTest
int property talkTestRun auto ; Set to 1 from the console (setpqv MantellaQuest talkTestRun 1) to run the in-game test of the talk settings. See MantellaTalkTest

; The Conversation Wheel while it is open (see MantellaWheel)
bool _isWheelOpen = false
int _wheelPointedAt = 0 ; The place on the wheel pointed at now. It opens on place 0
int _wheelChoice = -1 ; The place that was picked. -1 for none yet
bool _wasWheelCancelled = false
int property LEFT_MOUSE_BUTTON = 256 autoReadonly


event OnInit()
    assignDefaultSettings(0, true)
endEvent

; event OnUpdate()
;     If (restartMantellaExe)
;         restartMantellaExe = false
;         MantellaLauncher.LaunchMantellaExe()
;     EndIf
; endEvent

; lastVersion is the previous MCM version number defined in 'MantellaMCM.psc' before the new update is applied.
; Whenever a new repository value OR a new MCM setting is added, up the MCM version number returned by `ManatellaMCM.GetVersion()`
; and add the corresponding default value here in a block corresponding to the version number like the examples below
; Doing it like this will only assign the defaul values to settings that haven't been initialised prior.
function assignDefaultSettings(int lastVersion, bool isFirstInit = false)
    ; Version 21 added Show What Happened (npcEventHideText and the others). Stored the other way round, so it needs no default here
    If (lastVersion < 20 || isFirstInit)
        if !eventFollowerDefaultsAssigned ; Once only, so a later choice is kept even when an older block runs again (see MantellaMCM.OnConfigOpen)
            AssignEventFollowerDefaults()
        endIf
    EndIf
    ; Version 19 added People Who Must Answer a Group Line, and 17 Newcomers Remember. Both are Mantella's own settings now
    If (lastVersion < 18 || isFirstInit)
        shoutExcludeFollowers = false
        AssignEventDefaults()
    EndIf
    If (lastVersion < 16 || isFirstInit)
        shoutMaxListed = 30
    EndIf
    If (lastVersion < 15 || isFirstInit)
        showShoutMessages = false
        shoutHearingDistance = 20
        shoutMaxCandidates = 6
        shoutRequireLineOfSight = false
    EndIf
    If (lastVersion < 14 || isFirstInit)
        MantellaWheelHotkey = -1
    EndIf
    If (lastVersion < 13 || isFirstInit)
        eventRepeatCooldown = 10
    EndIf
    If (lastVersion < 12 || isFirstInit)
        npcEventEnabled = false
        npcEventFrequency = 20
        npcEventHearingDistance = 20
        npcEventRequireLineOfSight = false
        npcEventIncludeFollowers = true
        npcEventMaxCandidates = 6
        showNpcEventMessages = false
        MantellaNpcEventHotkey = -1
    EndIf
    If (lastVersion < 11 || isFirstInit)
        MantellaNpcInitiativeHotkey = -1
        npcInitiativeHotkeySkipsThreshold = false
        npcInitiativeIgnoreLineOfSight = false
    EndIf
    If (lastVersion < 10 || isFirstInit)
        npcInitiativeEnabled = false
        npcInitiativeOnLocationChange = true
        npcInitiativeIdleMinutes = 10
        npcInitiativeMinInterval = 60
        npcInitiativeSettleDelay = 3
        npcInitiativeMaxDistance = 10
        npcInitiativeMaxCandidates = 5
        npcInitiativeIncludeFollowers = true
        npcInitiativeMaxFollowers = 2
        showNpcInitiativeMessages = false
    EndIf
    ; 7 is the Mantella Vanilla Dialogue mod's version, which already set this. 8 is this add-on's previous release, which didn't
    If (lastVersion < 7 || lastVersion == 8 || isFirstInit)
        enableVanillaDialogueAwareness = true
    EndIf
    If (lastVersion < 8 || isFirstInit)
        MantellaInterruptHotkey = -1
    EndIf
    If (lastVersion < 6 || isFirstInit)
        NPCInventory = false
    EndIf
    If (lastVersion < 5 || isFirstInit)
        showReminderMessages = true
    EndIf
    If (lastVersion < 4 || isFirstInit)
        playerTrackingOnTimeChange = true
        playerTrackingOnWeatherChange = true
    EndIf
    If (lastVersion < 3 || isFirstInit)
        worldID = 1
    EndIf
    If (lastVersion < 2 || isFirstInit)
        showRadiantDialogueMessages = true
    EndIf
    If (lastVersion < 1 || isFirstInit)
        microphoneEnabled = true
        useHotkeyToStartMic = false
        MantellaEffectResponseTimer = 180

        MantellaStartHotkey = -1
        MantellaListenerTextHotkey = 35
        BindPromptHotkey(MantellaListenerTextHotkey)
        MantellaEndHotkey = -1
        MantellaCustomGameEventHotkey = -1
        MantellaRadiantHotkey = -1

        showDialogueItems = true

        radiantEnabled = false
        radiantDistance = 20
        radiantFrequency = 10


        playerCharacterDescription1 = ""
        playerCharacterDescription2 = ""
        playerCharacterUsePlayerDescription2 = false
        playerCharacterVoicePlayerInput = false
        playerCharacterVoiceModel = ""
        playerTrackingUsePCName = true

        
        playerTrackingOnItemAdded = true
        playerTrackingOnItemRemoved = true
        playerTrackingOnSpellCast = true
        playerTrackingOnHit = true
        playerTrackingOnLocationChange = true
        playerTrackingOnObjectEquipped = true
        playerTrackingOnObjectUnequipped = true
        playerTrackingOnPlayerBowShot = true
        playerTrackingOnSit = true
        playerTrackingOnGetUp = true

        playerEquipmentBody = true
        playerEquipmentHead = true
        playerEquipmentHands = true
        playerEquipmentFeet = true
        playerEquipmentAmulet = true
        playerEquipmentRightHand = true
        playerEquipmentLeftHand = true


        targetTrackingItemAdded = true
        targetTrackingItemRemoved = true
        targetTrackingOnSpellCast = true
        targetTrackingOnHit = true
        targetTrackingOnCombatStateChanged = true
        targetTrackingOnObjectEquipped = true
        targetTrackingOnObjectUnequipped = true
        targetTrackingOnSit = true
        targetTrackingOnGetUp = true
        targetTrackingAngerState = true

        targetEquipmentBody = true
        targetEquipmentHead = true
        targetEquipmentHands = true
        targetEquipmentFeet = true
        targetEquipmentAmulet = true
        targetEquipmentRightHand = true
        targetEquipmentLeftHand = true
        

	;followingNPCsit = false ;gia
	;followingNPCsleep = false ;gia
	;NPCstopandTalk = false ;gia
	AllowForNPCtoFollow = false ;gia
	NPCAnger = false ;gia
    NPCPackage = true
	;NPCForgive = false ;gia
	NPCDialogue = True ;gia
    
    NPCdebugSelectModeEnabled = false

        HttpPort = 4999
    EndIf
endFunction

; The Events page's defaults (MCM version 18)
Function AssignEventDefaults()
    npcEventAskForHint = false
    conversationEventAskForHint = false
    nearbyEventAskForHint = false
    nearbyEventMaxDescribed = 6
    nearbyEventIncludeFollowers = true
    randomEventAskForHint = false
    randomEventMaxDescribed = 6
    randomEventIncludeFollowers = true
    eventDefaultsAssigned = true
EndFunction

; Followers can be in every kind of event by default (MCM version 20). Until then they were left out by default
Function AssignEventFollowerDefaults()
    npcEventIncludeFollowers = true
    nearbyEventIncludeFollowers = true
    randomEventIncludeFollowers = true
    eventFollowerDefaultsAssigned = true
EndFunction

; Show What Happened on the Events page, for "npc", "conversation", "nearby" or "random"
bool Function ShowsEventText(string kind)
    if kind == "npc"
        return !npcEventHideText
    elseIf kind == "conversation"
        return !conversationEventHideText
    elseIf kind == "nearby"
        return !nearbyEventHideText
    elseIf kind == "random"
        return !randomEventHideText
    endIf
    return false
EndFunction

; SkyUI's version update does not run on every save. Called when the menu opens and before an event is generated
Function EnsureEventDefaults()
    if !eventDefaultsAssigned
        AssignEventDefaults()
    endIf
    if !eventFollowerDefaultsAssigned
        AssignEventFollowerDefaults()
    endIf
EndFunction

function BindStartAddHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the start hotkey KeyMapChange
    UnregisterForKey(MantellaStartHotkey)
    MantellaStartHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindPromptHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the prompt hotkey KeyMapChange
    UnregisterForKey(MantellaListenerTextHotkey)
    MantellaListenerTextHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindEndHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the end hotkey KeyMapChange
    UnregisterForKey(MantellaEndHotkey)
    MantellaEndHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindCustomGameEventHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the custom game event hotkey KeyMapChange
    UnregisterForKey(MantellaCustomGameEventHotkey)
    MantellaCustomGameEventHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindRadiantHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the prompt hotkey KeyMapChange
    UnregisterForKey(MantellaRadiantHotkey)
    MantellaRadiantHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindInterruptHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the interrupt hotkey KeyMapChange
    UnregisterForKey(MantellaInterruptHotkey)
    MantellaInterruptHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindNpcInitiativeHotkey(int keyCode)
    ;used by the MCM_GeneralSettings KeyMapChange (from the NPC Initiative page) when updating the NPC Initiative hotkey
    UnregisterForKey(MantellaNpcInitiativeHotkey)
    MantellaNpcInitiativeHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindNpcEventHotkey(int keyCode)
    ;used by the MCM_GeneralSettings KeyMapChange (from the NPC Events page) when updating the NPC Event hotkey
    UnregisterForKey(MantellaNpcEventHotkey)
    MantellaNpcEventHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

function BindWheelHotkey(int keyCode)
    ;used by the MCM_GeneralSettings when updating the Conversation Wheel hotkey KeyMapChange
    UnregisterForKey(MantellaWheelHotkey)
    MantellaWheelHotkey=keyCode
    RegisterHotkeys() ; Also brings back a key another hotkey shares. An unmapped key (-1) isn't registered
endfunction

; Called on every game load (from MantellaListenerScript). A key registration can get lost while the key stays set in the MCM,
; and then the hotkey does nothing until it is rebound
function RegisterHotkeys()
    RegisterHotkey(MantellaStartHotkey)
    RegisterHotkey(MantellaListenerTextHotkey)
    RegisterHotkey(MantellaEndHotkey)
    RegisterHotkey(MantellaCustomGameEventHotkey)
    RegisterHotkey(MantellaRadiantHotkey)
    RegisterHotkey(MantellaInterruptHotkey)
    RegisterHotkey(MantellaNpcInitiativeHotkey)
    RegisterHotkey(MantellaNpcEventHotkey)
    RegisterHotkey(MantellaWheelHotkey)
endfunction

function RegisterHotkey(int keyCode)
    if keyCode > 0 ; -1 is unbound
        RegisterForKey(keyCode)
    endIf
endfunction

bool Function IsVR()
    return Debug.GetVersionNumber() == "1.4.15.0"
EndFunction

; True when the Mantella Vanilla Dialogue SKSE plugin (MantellaDialogue.dll) is loaded
bool Function IsVanillaDialogueInstalled()
    return SKSE.GetPluginVersion("MantellaDialogue") >= 0
EndFunction

; True when the quest tag check plugin (MantellaQuestChecks.dll) is loaded
bool Function IsQuestChecksInstalled()
    return SKSE.GetPluginVersion("MantellaQuestChecks") >= 0
EndFunction

; Hands a check list from MantellaSoftware (a nested dictionary of the reply) to the quest tag check plugin
bool Function SetQuestCheckList(int listHandle, MantellaConstants consts)
    if !listHandle || !IsQuestChecksInstalled()
        return false
    endIf
    string version = SKSE_HTTP.getString(listHandle, consts.KEY_QUESTCHECKS_VERSION, "")
    string[] functions = SKSE_HTTP.getStringArray(listHandle, consts.KEY_QUESTCHECKS_FUNCTIONS)
    string[] references = SKSE_HTTP.getStringArray(listHandle, consts.KEY_QUESTCHECKS_REFERENCES)
    string[] params1 = SKSE_HTTP.getStringArray(listHandle, consts.KEY_QUESTCHECKS_PARAMS1)
    string[] params2 = SKSE_HTTP.getStringArray(listHandle, consts.KEY_QUESTCHECKS_PARAMS2)
    return MantellaQuestChecks.SetCheckList(version, functions, references, params1, params2)
EndFunction

bool function restartMantellaExe()
    ; restartMantellaExe = true
    ; RegisterForSingleUpdate(1)
    MantellaLauncher.LaunchMantellaExe() 
    ;Note: If you need to debug this call to the SKSE plugin, you need to call it from the commented out single update above instead
    ;      or the VS debugger will crash (due to being called from the MCM thread?).
    ;      Check the corresponding commented out OnUpdate at the beginning of the script.
EndFunction

; The wheel shows while the hotkey is held. Point at an option and click (or press Activate) to pick it.
; Letting go of the hotkey closes it, and nothing happens unless an option was picked
Function OpenWheel()
    if _isWheelOpen
        return
    endIf
    _isWheelOpen = true
    _wheelPointedAt = 0
    _wheelChoice = -1
    _wasWheelCancelled = false
    ; Left registered after the wheel closes: unregistering here could stop the next wheel, which may already be open by then.
    ; Every handler checks _isWheelOpen
    RegisterForModEvent("UIWheelMenu_SetOption", "OnWheelPointedAt")
    RegisterForModEvent("UIWheelMenu_ChooseOption", "OnWheelChoice")
    RegisterForModEvent("UIWheelMenu_CloseMenu", "OnWheelClosed")
    RegisterForModEvent("UIWheelMenu_LoadMenu", "OnWheelShown")
    RegisterForKey(LEFT_MOUSE_BUTTON) ; The wheel itself only picks with Activate (E / Enter), not with a click
    MantellaWheel.Open(self) ; Calls WheelFinished. Not called again here: by then the next wheel may be open
EndFunction

; Called by MantellaWheel as soon as the wheel has closed, before the chosen option runs. Some options take a few seconds
; (starting a conversation), and the wheel can open again right away instead of after them
Function WheelFinished()
    if !_isWheelOpen
        return
    endIf
    if !IsMantellaHotkey(LEFT_MOUSE_BUTTON)
        UnregisterForKey(LEFT_MOUSE_BUTTON)
    endIf
    _isWheelOpen = false
EndFunction

bool Function IsMantellaHotkey(int keyCode)
    return keyCode == MantellaStartHotkey || keyCode == MantellaListenerTextHotkey || keyCode == MantellaEndHotkey || keyCode == MantellaCustomGameEventHotkey || keyCode == MantellaRadiantHotkey || keyCode == MantellaInterruptHotkey || keyCode == MantellaNpcInitiativeHotkey || keyCode == MantellaNpcEventHotkey || keyCode == MantellaWheelHotkey
EndFunction

; The hotkey may have been let go before the wheel was on screen, when OnKeyUp could not close it yet
Event OnWheelShown(string eventName, string strArg, float numArg, Form sender)
    if !_isWheelOpen
        return
    endIf
    if _wheelChoice < 0 && !Input.IsKeyPressed(MantellaWheelHotkey)
        CloseWheel()
        return
    endIf
    FitWheelTexts()
EndEvent

; UIWheelMenu's text fields are small and cut off what doesn't fit: the labels on the wheel, the text below it and the name above it.
; They shrink it to fit instead, as UIExtensions' own follower wheel does for names. Then the texts are set again, so they are laid out
; with it (UIWheelMenu sets them on this same event, maybe before this ran)
Function FitWheelTexts()
    string root = "_root.WheelPhase.WheelBase."
    string[] fields = new string[10]
    fields[0] = "TextLeft00"
    fields[1] = "TextLeft01"
    fields[2] = "TextLeft02"
    fields[3] = "TextLeft03"
    fields[4] = "TextRight00"
    fields[5] = "TextRight01"
    fields[6] = "TextRight02"
    fields[7] = "TextRight03"
    fields[8] = "Option"
    fields[9] = "Name"
    int i = 0
    while i < fields.Length
        UI.SetString("CustomMenu", root + fields[i] + ".textAutoSize", "shrink")
        i += 1
    endWhile
    UIWheelMenu wheel = UIExtensions.GetMenu("UIWheelMenu", false) as UIWheelMenu
    if wheel && _isWheelOpen
        wheel.UpdateWheelOptionLabels()
        wheel.UpdateWheelOptions()
        wheel.UpdateWheelSelection() ; Shows the pointed-at option's text again
    endIf
EndFunction

Event OnWheelPointedAt(string eventName, string strArg, float numArg, Form sender)
    _wheelPointedAt = numArg as int
EndEvent

; Picked with Activate (E / Enter)
Event OnWheelChoice(string eventName, string strArg, float numArg, Form sender)
    if _wheelChoice < 0
        _wheelChoice = numArg as int
    endIf
EndEvent

; Closes the wheel from here: on a click, or when the hotkey is let go. Nothing is picked unless _wheelChoice is set
Function CloseWheel()
    if _wheelChoice < 0
        _wasWheelCancelled = true
    endIf
    UI.CloseCustomMenu()
    EndWheelWait()
EndFunction

; UIWheelMenu waits for its own choice event, which a click or letting go of the hotkey never sends, so its wait is ended
; here. Otherwise it would only return 5 seconds later, and the wheel couldn't open again until then. Its wait only ends
; once the wheel is off the screen. A choice event can't end it: UIWheelMenu stops listening for choices when it closes
Function EndWheelWait()
    UIExtensions.GetMenu("UIWheelMenu", false).Unlock()
EndFunction

; Closed by the wheel itself: picked with Activate, or closed with Escape / Tab
Event OnWheelClosed(string eventName, string strArg, float numArg, Form sender)
    if _isWheelOpen
        if _wheelChoice < 0
            _wasWheelCancelled = true
        endIf
        EndWheelWait()
    endIf
EndEvent

; The place that was picked, or -1 if the wheel was closed without a choice
int Function GetWheelChoice()
    return _wheelChoice
EndFunction

; True when the wheel was closed without a choice. What UIWheelMenu returned then is an old choice
bool Function WasWheelCancelled()
    return _wasWheelCancelled
EndFunction

; Not limited to outside menus like OnKeyDown: the wheel is a menu
Event OnKeyUp(int KeyCode, float HoldTime)
    if !_isWheelOpen || _wasWheelCancelled
        return
    endIf
    if KeyCode == MantellaWheelHotkey
        CloseWheel() ; Let go without a choice, or after picking with Activate in case the wheel didn't close itself
    elseIf _wheelChoice >= 0
        return
    elseIf KeyCode == LEFT_MOUSE_BUTTON && UI.IsMenuOpen("CustomMenu")
        _wheelChoice = _wheelPointedAt
        CloseWheel()
    endIf
EndEvent

Event OnKeyDown(int KeyCode)
    ;this function was previously in MantellaListener Script back in Mantella 0.9.2
	;this ensures the right key is pressed and only activated while not in menu mode
    if !utility.IsInMenuMode()
        if KeyCode == MantellaStartHotkey
            Actor targetRef = (Game.GetCurrentCrosshairRef() as actor)            
            if (targetRef) ;If we have a target under the crosshair, cast sepll on it
                MantellaSpell.cast(PlayerRef, targetRef)
                ;Utility.Wait(0.5)
            endIf        
        elseIf KeyCode == MantellaListenerTextHotkey
            MantellaConversation roomConversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
            If (!roomConversation.IsRunning())
                MantellaShout.SayToRoom(self, roomConversation) ; Just saying something: said to whoever is around
            ElseIf(!microphoneEnabled) ;Otherwise, try to open player text input if microphone is off
                MantellaConversation conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
                if(conversation.IsRunning())
                    conversation.GetPlayerTextInput()
                endIf
            elseIf (useHotkeyToStartMic)
                MantellaConversation conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
                if(conversation.IsRunning())
                    conversation.sendRequestForVoiceTranscribe()
                endIf
            endIf
        elseIf KeyCode == MantellaEndHotkey
            Actor targetRef = (Game.GetCurrentCrosshairRef() as actor)            
            if (targetRef) ;If we have a target under the crosshair, cast sepll on it
                MantellaRemoveNpcSpell.cast(PlayerRef, targetRef)
            else
                MantellaEndSpell.cast(PlayerRef)
            endIf
        elseIf KeyCode == MantellaCustomGameEventHotkey
            MantellaConversation conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
            if(conversation.IsRunning())
                UIExtensions.InitMenu("UITextEntryMenu")
                UIExtensions.OpenMenu("UITextEntryMenu")
                string gameEventEntry = UIExtensions.GetMenuResultString("UITextEntryMenu")
                if (gameEventEntry && gameEventEntry != "")
                    gameEventEntry = gameEventEntry+"\n"
                    conversation.AddIngameEvent(gameEventEntry)
                endIf
            endIf
        elseIf KeyCode == MantellaInterruptHotkey
            MantellaConversation conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
            if(conversation.IsRunning())
                conversation.RequestInterrupt()
            endIf
        elseIf KeyCode == MantellaNpcInitiativeHotkey
            SendModEvent("Mantella_NpcInitiativeHotkey") ; The check lives in MantellaListenerScript
        elseIf KeyCode == MantellaNpcEventHotkey
            SendModEvent("Mantella_NpcEventHotkey") ; The check lives in MantellaListenerScript
        elseIf KeyCode == MantellaWheelHotkey
            OpenWheel()
        elseIf KeyCode == MantellaRadiantHotkey
            radiantEnabled =! radiantEnabled
            if radiantEnabled == True
                Debug.Notification("Radiant Dialogue enabled.")
            else
                Debug.Notification("Radiant Dialogue disabled.")
            endIf
        endIf
    endIf
endEvent