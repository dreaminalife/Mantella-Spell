Scriptname MantellaListenerScript extends ReferenceAlias

Spell property MantellaSpell auto
Spell property MantellaPower auto;gia
Spell Property MantellaEndSpell auto
Spell Property MantellaEndPower auto
Spell Property MantellaRemoveNpcSpell auto
Spell Property MantellaRemoveNpcPower auto
MantellaRepository property repository auto
Quest Property MantellaActorPicker auto  
ReferenceAlias Property PotentialActor1 auto  
ReferenceAlias Property PotentialActor2 auto  

Quest Property MantellaNearbyActors Auto
ReferenceAlias Property NearbyActor1 Auto
ReferenceAlias Property NearbyActor2 Auto
ReferenceAlias Property NearbyActor3 Auto
ReferenceAlias Property NearbyActor4 Auto
ReferenceAlias Property NearbyActor5 Auto
MantellaConversation Property conversation auto
MantellaMCM Property MantellaMCMQuest auto
Actor Property PlayerRef Auto

event OnInit()
    PlayerRef.AddSpell(MantellaSpell)
    PlayerRef.AddSpell(MantellaPower);gia
    PlayerRef.AddSpell(MantellaEndSpell)
    PlayerRef.AddSpell(MantellaEndPower)
    PlayerRef.AddSpell(MantellaRemoveNpcSpell)
    PlayerRef.AddSpell(MantellaRemoveNpcPower)
    PlayerRef.AddToFaction(repository.giafac_AllowDialogue);gia
    MantellaKillEvents.Register(self)
    repository.SendHeardLinesSettings() ; A new game never runs OnPlayerLoadGame, and the plugin catches nothing until it has its settings
    Debug.Notification("Please save and reload to activate Mantella.")
endEvent

Function AddIngameEventToConversation(string eventText, bool withCooldown = false)
    If (conversation.IsRunning())
        If (withCooldown) ; For events that can repeat many times a second, like hits and spell casts
            conversation.AddIngameEventWithCooldown(eventText)
        Else
            conversation.AddIngameEvent(eventText)
        EndIf
    EndIf
EndFunction

Float meterUnits = 71.0210
Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction

string Function getPlayerName(bool isStartOfSentence = True)
    if (repository.playerTrackingUsePCName)
        return PlayerRef.GetDisplayName()
    Elseif (isStartOfSentence)
        return "The player"
    Else
        return "the player"
    endif
EndFunction

Event OnPlayerLoadGame()
    conversation.RegisterForConversationEvents() ; Its own quest script never gets OnPlayerLoadGame
    If(conversation.IsRunning())
        conversation.EndAfterSaveLoad()
    endif
    ; If (MantellaMCMQuest.IsRunning() || MantellaMCMQuest.IsNotProperlyInitialised())
    ;     Debug.MessageBox("Detecting old version of Mantella in this save. MCM settings will be reset once.")
    ;     MantellaMCMQuest.Stop()
    ;     MantellaMCMQuest.Start()
    ;     MantellaMCMQuest.OnConfigInit()
    ;     repository.assignDefaultSettings(0,true)
    ; EndIf
    repository.RegisterHotkeys()
    RegisterForModEvent("SKSE_HTTP_OnHttpReplyReceived", "OnHttpReplyReceived")
    RegisterForModEvent("Mantella_VoiceClipsDone", "OnVoiceClipsDone")
    RequestQuestCheckList()
    SendVoiceClipsSaveLoaded()
    repository.SendHeardLinesSettings()
    WarnOldVanillaDialogue()
    RegisterForModEvent("Mantella_NpcInitiativeHotkey", "OnNpcInitiativeHotkey")
    RegisterForModEvent("Mantella_NpcEventHotkey", "OnNpcEventHotkey")
    RegisterForModEvent("Mantella_EventTest", "OnEventTest")
    RegisterForModEvent("Mantella_TalkTest", "OnTalkTest")
    RegisterForModEvent("Mantella_ActionTest", "OnActionTest")
    RegisterForModEvent("Mantella_HeardLinesTest", "OnHeardLinesTest")
    if repository.heardLinesTestOnLoad != 0 ; A save the in-game test of Vanilla Dialogues made: it goes on with its next run
        float heardLinesRun = repository.heardLinesTestOnLoad as float
        repository.heardLinesTestOnLoad = 0
        SendModEvent("Mantella_HeardLinesTest", "", heardLinesRun)
    endIf
    RegisterForModEvent(NPC_EVENT_BUILD_EVENT(), "OnNpcEventBuild")
    RegisterForMenu("Loading Menu")
    MantellaKillEvents.Register(self) ; Again here, in case this save never ran OnInit with it, or the extender was only just installed
    _lastCell = PlayerRef.GetParentCell()
    ; Real time starts from 0 on every game launch, so times kept in the save would be in the future
    _initiativePending = false
    _eventPending = false
    _isSendingCheck = false ; In case the save was made during a check
    _lastInitiativeCheckTime = Utility.GetCurrentRealTime()
    _lastPlayerConversationTime = _lastInitiativeCheckTime
    _initiativeSentTime = _lastInitiativeCheckTime
    _eventSentTime = _lastInitiativeCheckTime
    _lastEventCheckTime = _lastInitiativeCheckTime
    _lastRadiantAttemptTime = _lastInitiativeCheckTime
    RegisterForSingleUpdate(tickSeconds)
EndEvent

; Once per load, while the old Mantella Vanilla Dialogue plugin is still installed: Mantella now does its job
Function WarnOldVanillaDialogue()
    if repository.IsOldVanillaDialogueInstalled()
        Debug.MessageBox("The old Mantella Vanilla Dialogue mod is still installed. Mantella now does its job itself, so NPCs would hear every line twice. Please uninstall that mod.")
    endIf
EndFunction

; Asks MantellaSoftware once for the quest tag checks. If it isn't running yet, the list comes with the first conversation's start reply instead
Function RequestQuestCheckList()
    if !repository.IsQuestChecksInstalled()
        return
    endIf
    MantellaConstants consts = conversation.mConsts
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, consts.KEY_REQUESTTYPE, consts.KEY_REQUESTTYPE_QUESTCHECKLIST)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
EndFunction

; MantellaSoftware can't call the game: voice clip work waiting there (Prepare all voices on its Text-to-Speech page) comes with its
; next reply. Sent once when a save loads, so that work doesn't wait for the first conversation. Never on a timer
Function SendVoiceClipsSaveLoaded()
    if !repository.IsVoiceClipsInstalled()
        return
    endIf
    MantellaConstants consts = conversation.mConsts
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, consts.KEY_REQUESTTYPE, consts.KEY_REQUESTTYPE_VOICECLIP_SAVELOADED)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
EndFunction

; Any reply can carry requests for voice clips, which the MantellaVoiceClips plugin copies from the game files in the background,
; and short notices about the voice service
Function HandleVoiceReplyParts(int handle, MantellaConstants consts)
    if SKSE_HTTP.hasKey(handle, consts.KEY_VOICECLIP_REQUESTS) && repository.IsVoiceClipsInstalled()
        string[] requests = SKSE_HTTP.getStringArray(handle, consts.KEY_VOICECLIP_REQUESTS)
        int i = 0
        while i < requests.Length
            MantellaVoiceClips.FetchClips(requests[i])
            i += 1
        endWhile
    endIf
    if SKSE_HTTP.hasKey(handle, consts.KEY_VOICE_NOTICES)
        string[] notices = SKSE_HTTP.getStringArray(handle, consts.KEY_VOICE_NOTICES)
        int i = 0
        while i < notices.Length
            Debug.Notification(notices[i])
            i += 1
        endWhile
    endIf
EndFunction

; The plugin copied a request's lines: MantellaSoftware takes them in
Event OnVoiceClipsDone(string eventName, string requestId, float clipCount, Form sender)
    MantellaConstants consts = conversation.mConsts
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, consts.KEY_REQUESTTYPE, consts.KEY_REQUESTTYPE_VOICECLIP_DELIVERED)
    SKSE_HTTP.setString(handle, consts.KEY_VOICECLIP_REQUESTID, requestId)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
EndEvent

; NPC Initiative, NPC Events and radiant conversations share the one conversation slot. Each has its own frequency, checked on a short tick.
; Only one of them starts per tick, and nothing starts while a check waits for the server
float tickSeconds = 5.0
float _lastRadiantAttemptTime = 0.0

Actor[] Function ScanNearbyActors()
    MantellaNearbyActors.start()

    Actor[] nearbyActors = new Actor[5]
    
    if (NearbyActor1.GetReference() as Actor)
        nearbyActors[0] = NearbyActor1.GetReference() as Actor
        if (NearbyActor2.GetReference() as Actor)
            nearbyActors[1] = NearbyActor2.GetReference() as Actor
            if (NearbyActor3.GetReference() as Actor)
                nearbyActors[2] = NearbyActor3.GetReference() as Actor
                if (NearbyActor4.GetReference() as Actor)
                    nearbyActors[3] = NearbyActor4.GetReference() as Actor
                    if (NearbyActor5.GetReference() as Actor)
                        nearbyActors[4] = NearbyActor5.GetReference() as Actor
                    endIf
                endIf
            endIf
        endIf
    endIf
    
    MantellaNearbyActors.stop()
    
    return nearbyActors
EndFunction

event OnUpdate()
    if repository.eventTestRun != 0 ; Set from the console by the in-game test's batch file
        repository.eventTestRun = 0
        SendModEvent("Mantella_EventTest") ; Runs on its own thread, so the ticks go on during the test
    endIf
    if repository.talkTestRun != 0 ; Set from the console by the in-game test of the talk settings
        repository.talkTestRun = 0
        SendModEvent("Mantella_TalkTest")
    endIf
    if repository.actionTestRun != 0 ; Set from the console by the in-game test of the NPC actions: 1, or 2 with Advanced Actions on, 3 or 4 for other mods' actions
        float testRun = repository.actionTestRun as float
        repository.actionTestRun = 0
        SendModEvent("Mantella_ActionTest", "", testRun)
    endIf
    if repository.heardLinesTestRun != 0 ; Set from the console by the in-game test of Vanilla Dialogues
        float heardLinesRun = repository.heardLinesTestRun as float
        repository.heardLinesTestRun = 0
        SendModEvent("Mantella_HeardLinesTest", "", heardLinesRun)
    endIf
    float now = Utility.GetCurrentRealTime()
    if conversation.IsRunning()
        if conversation.IsPlayerInConversation()
            _lastPlayerConversationTime = now
        endIf
        if conversation.IsNpcEvent() && !conversation.IsEnding() ; Saving the memories can take longer than a tick
            MonitorNpcEvent()
        endIf
        if conversation.IsShouting() && !conversation.IsEnding()
            conversation.RefreshShoutNearby() ; Who can join now. NPC Events run in Shout too
        endIf
        if !conversation.IsEnding()
            conversation.RefreshStaleActors() ; Who was kept, not built again, by the last join or leave
        endIf
    elseIf IsCheckPending(now)
        ; The check's result may start a conversation
    elseIf repository.npcInitiativeEnabled && repository.npcInitiativeIdleMinutes > 0 && now - _lastPlayerConversationTime >= repository.npcInitiativeIdleMinutes * 60 && TryNpcInitiative()
        ; Checked first, as it is aimed at the player
    elseIf repository.npcEventEnabled && TryNpcEvent()
        ; Sent only once its frequency allows
    elseIf repository.radiantEnabled && now - _lastRadiantAttemptTime >= repository.radiantFrequency
        _lastRadiantAttemptTime = now
        TryRadiantConversation()
    endIf
    RegisterForSingleUpdate(tickSeconds)
endEvent

Function TryRadiantConversation()
    ;MantellaActorList taken from this tutorial:
    ;http://skyrimmw.weebly.com/skyrim-modding/detecting-nearby-actors-skyrim-modding-tutorial
    MantellaActorPicker.start()

    ; if both actors found
    if (PotentialActor1.GetReference() as Actor) && (PotentialActor2.GetReference() as Actor)
        Actor Actor1 = PotentialActor1.GetReference() as Actor
        Actor Actor2 = PotentialActor2.GetReference() as Actor

        float distanceToClosestActor = PlayerRef.GetDistance(Actor1)
        float maxDistance = ConvertMeterToGameUnits(repository.radiantDistance)
        if distanceToClosestActor <= maxDistance
            String Actor1Name = Actor1.getdisplayname()
            String Actor2Name = Actor2.getdisplayname()
            float distanceBetweenActors = Actor1.GetDistance(Actor2)

            ;TODO: make distanceBetweenActors customisable
            if (distanceBetweenActors <= 1000)
                ;have spell casted on Actor 1 by Actor 2
                MantellaSpell.Cast(Actor2 as ObjectReference, Actor1 as ObjectReference)
            elseif(repository.showRadiantDialogueMessages)
                Debug.Notification("Radiant dialogue attempted. No NPCs available")
            endIf
        elseif(repository.showRadiantDialogueMessages)
            Debug.Notification("Radiant dialogue attempted. NPCs too far away at " + ConvertGameUnitsToMeter(distanceToClosestActor) + " meters")
            Debug.Notification("Max distance set to " + repository.radiantDistance + "m in Mantella MCM")
        endIf
    elseif(repository.showRadiantDialogueMessages)
        Debug.Notification("Radiant dialogue attempted. No NPCs available")
    endIf

    MantellaActorPicker.stop()
EndFunction


;All the event listeners  below have 'if' clauses added after Mantella 0.9.2 (except ondying)
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if repository.playerTrackingOnItemAdded
        string itemName = akBaseItem.GetName()
        string itemCount = ""
        if itemName == "gold" ; only count the number of items if it is gold
            itemCount = aiItemCount+" "
        endIf
        string sourceName = ""
        if akSourceContainer != None ; if the source container is a container, not an actor
            sourceName = " from " + akSourceContainer.getdisplayname()
        endif
        string itemPickedUpMessage = getPlayerName() + " picked up / took " + itemCount + itemName + sourceName
        if itemName != "Iron Arrow" ; Papyrus hallucinates iron arrows
            ;Debug.MessageBox(itemPickedUpMessage)
            AddIngameEventToConversation(itemPickedUpMessage)
        endIf
    endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.playerTrackingOnItemRemoved
        string itemName = akBaseItem.GetName()
        string itemCount = ""
        if itemName == "gold" ; only count the number of items if it is gold
            itemCount = aiItemCount + " "
        endIf
        string destName = ""
        if akDestContainer != None
            destName = " in/on/to " + akDestContainer.getdisplayname()
        endif
        string itemDroppedMessage = getPlayerName() + " dropped/gave " + itemCount + itemName + destName
        if itemName != "Iron Arrow" ; Papyrus hallucinates iron arrows
            ;Debug.MessageBox(itemDroppedMessage)
            AddIngameEventToConversation(itemDroppedMessage)
        endIf
    endif
endEvent


Event OnSpellCast(Form akSpell)
    if (repository.playerTrackingOnSpellCast) 
        string spellCast = (akSpell as form).getname()
        if spellCast 
            if (spellCast != "Mantella") && (spellCast != "Mantella Remove NPC") && (spellCast != "Mantella End Conversation")
                ;Debug.Notification("The player cast the spell "+ spellCast)
                AddIngameEventToConversation(getPlayerName() + " cast the spell / consumed " + spellCast , true)
            endIf
        endIf
    endif
endEvent


; Heals and buffs also count as a hit in the game. They are worded as "used ... on", so they don't read like an attack.
; Mantella merges the events by these wordings (ingame_event_tidy.py), so keep them in sync
bool Function IsFriendlySpell(Form akSource)
    Spell sourceSpell = akSource as Spell
    return sourceSpell && !sourceSpell.IsHostile()
EndFunction

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    if repository.playerTrackingOnHit
        string aggressor = akAggressor.getdisplayname()
        string hitSource = akSource.getname()

        ; Continuous spells hit very frequently, so repeats are limited by the event repeat cooldown
        if (hitSource != "Mantella") && (hitSource != "Mantella Remove NPC") && (hitSource != "Mantella End Conversation")
            if (aggressor == "None") || (aggressor == "")
                AddIngameEventToConversation(getPlayerName() + " took damage.", true)
            elseif (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched the player.")
                AddIngameEventToConversation(aggressor + " punched " + getPlayerName(False) + " .", true)
            elseif IsFriendlySpell(akSource)
                AddIngameEventToConversation(aggressor + " used " + hitSource + " on " + getPlayerName(False), true)
            else
                ;Debug.MessageBox(aggressor + " hit the player with " + hitSource)
                AddIngameEventToConversation(aggressor + " hit " + getPlayerName(False) + " with " + hitSource, true)
            endIf
        endIf
    endif
EndEvent


Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    ; check if radiant dialogue is playing, and end conversation if the player leaves the area
    If (conversation.IsRunning() && !conversation.IsPlayerInConversation())
        conversation.EndConversation()
    elseIf repository.playerTrackingOnLocationChange
        string _location = (akNewLoc as Form).GetName()
        if _location == ""
            _location = "Skyrim"
        endIf
        AddIngameEventToConversation("The location is now " + _location)
    endIf
    if repository.npcInitiativeEnabled && repository.npcInitiativeOnLocationChange && !conversation.IsRunning()
        Utility.Wait(repository.npcInitiativeSettleDelay) ; Lets the NPCs of the new location load
        TryNpcInitiative()
    endIf
endEvent


; Rooms behind a load door are often separate cells of the same location, so OnLocationChange doesn't fire when entering them.
; A loading screen that ends in a new cell counts as a location change for NPC Initiative.
; When OnLocationChange also fires, the first check to run makes the other wait for the min time between checks
Cell _lastCell
Event OnMenuClose(String menuName)
    if menuName != "Loading Menu"
        return
    endIf
    Cell newCell = PlayerRef.GetParentCell()
    if newCell == _lastCell
        return
    endIf
    _lastCell = newCell
    if repository.npcInitiativeEnabled && repository.npcInitiativeOnLocationChange && !conversation.IsRunning()
        Utility.Wait(repository.npcInitiativeSettleDelay) ; Lets the NPCs of the new cell load
        TryNpcInitiative()
    endIf
EndEvent


Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectEquipped
        string itemEquipped = akBaseObject.getname()

        if (itemEquipped != "Mantella") && (itemEquipped != "Mantella Remove NPC") && (itemEquipped != "Mantella End Conversation")
            ;Debug.MessageBox("The player equipped " + itemEquipped)
            AddIngameEventToConversation(getPlayerName() + " equipped " + itemEquipped)
        endIf
    endif
endEvent


Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectUnequipped
        string itemUnequipped = akBaseObject.getname()

        if (itemUnequipped != "Mantella") && (itemUnequipped != "Mantella Remove NPC") && (itemUnequipped != "Mantella End Conversation")
            ;Debug.MessageBox("The player unequipped " + itemUnequipped)
            AddIngameEventToConversation(getPlayerName() + " unequipped " + itemUnequipped )
        endIf
    endif
endEvent


Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)
    if repository.playerTrackingOnPlayerBowShot
        ;Debug.MessageBox("The player fired an arrow.")
        AddIngameEventToConversation(getPlayerName() + " fired an arrow.", true)
    endif
endEvent


Event OnSit(ObjectReference akFurniture)
    if repository.playerTrackingOnSit
        ; Debug.MessageBox("playerTrackingOnSit is true")
        String furnitureName = akFurniture.getbaseobject().getname()
        AddIngameEventToConversation(getPlayerName() + " rested on / used a(n) "+furnitureName)
    endif
endEvent


Event OnGetUp(ObjectReference akFurniture)
    if repository.playerTrackingOnGetUp
        ;Debug.MessageBox("The player stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        AddIngameEventToConversation(getPlayerName() + " stood up from a(n) "+furnitureName)
    endif
EndEvent


Event OnDying(Actor akKiller)
    If (conversation.IsRunning())
        conversation.EndConversation()
    EndIf
EndEvent


; Who landed the killing blow on an enemy. The OnDying handlers only cover the player and the conversation's own participants,
; so without this nobody learns that a follower finally brought down the dragon the whole party was fighting.
; Sent by powerofthree's Papyrus Extender, which is an OPTIONAL requirement: without it this event never arrives and nothing
; else changes. MantellaKillEvents holds every mention of the extender, so this script loads fine when it isn't installed.
; Mantella merges these lines by this wording (ingame_event_tidy.py), so keep them in sync
Event OnActorKilled(Actor akVictim, Actor akKiller)
    If (!akVictim || !akKiller || !conversation.IsRunning())
        return
    EndIf
    ; A downed follower is not a kill: essential and protected NPCs bleed out and get back up. Essential ones can never die,
    ; and the others are only passed over while they are bleeding out without being dead yet.
    ; IsDead() alone can't be trusted here (it isn't reliably set yet when the kill is reported), and IsBleedingOut() alone
    ; would throw away the real deaths that pass through bleedout first, which is how dragons and 'no bleedout recovery' NPCs die
    If (akVictim.IsEssential() || (akVictim.IsBleedingOut() && !akVictim.IsDead()))
        return
    EndIf
    ; Only a kill by someone in the conversation is worth a line, or a big fight nearby would fill the events with strangers.
    ; A participant's own death is already reported by the OnDying handlers, so it is left out here.
    ; Note that OnDying takes the dead one out of the conversation, so if it ran first this event no longer sees them as a
    ; participant and reports the death a second time. The sentence below is worded exactly as OnDying words it, which lets
    ; Mantella merge the two into one line (ingame_event_tidy.py). Keep the two wordings identical
    If (!conversation.Participants.HasForm(akKiller) || conversation.Participants.HasForm(akVictim))
        return
    EndIf
    String victimName = akVictim.GetDisplayName()
    If (victimName == "")
        return
    EndIf
    String killerName = akKiller.GetDisplayName()
    If (akKiller == PlayerRef)
        killerName = getPlayerName(False)
    EndIf
    ; With a cooldown: a death can be reported twice, and one fight often kills several enemies with the same name
    AddIngameEventToConversation(victimName + " was killed by " + killerName, true)
EndEvent


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        NPC Initiative       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A nearby NPC who has a reason to talk to the player walks up and starts a conversation.
; Mantella's server decides who (if anyone) that is.

float _lastInitiativeCheckTime = 0.0
float _lastPlayerConversationTime = 0.0
float _initiativeSentTime = 0.0
bool _initiativePending = false
bool _isInitiativeManual = false ; The pending check was started with the hotkey or the wheel, so the player hears back when nobody comes
Actor[] _initiativeCandidates
int _initiativeCandidateCount = 0
float initiativePendingTimeout = 30.0 ; Seconds. An error reply can't be told apart from other requests' errors, so a lost reply times out
bool _isSendingCheck = false ; Shared by NPC Initiative and NPC Events, so only one check is sent at a time

; The hotkey (and Approach on the wheel) checks right away, even when a check ran recently or NPC Initiative is off,
; like the NPC Event hotkey. Enabled only controls the automatic checks
Event OnNpcInitiativeHotkey(string eventName, string strArg, float numArg, Form sender)
    if TryNpcInitiative(true)
        if !repository.showNpcInitiativeMessages ; Otherwise the check already named the NPCs it considers
            Debug.Notification("NPC Initiative: checking nearby NPCs")
        endIf
    else
        Debug.Notification("NPC Initiative: can't check right now")
    endIf
EndEvent

; Returns true if a check was sent to the server
bool Function TryNpcInitiative(bool isManual = false)
    ; Calls into other scripts let other events run, so a location change and the idle timer could otherwise check at the same time.
    ; Nothing may call another script between this test and the set
    if _isSendingCheck
        return false
    endIf
    _isSendingCheck = true
    bool hasSent = RunNpcInitiativeCheck(isManual)
    _isSendingCheck = false
    return hasSent
EndFunction

bool Function RunNpcInitiativeCheck(bool isManual)
    if (!repository.npcInitiativeEnabled && !isManual) || conversation.IsRunning()
        return false
    endIf
    float now = Utility.GetCurrentRealTime()
    if IsCheckPending(now)
        return false
    endIf
    if (!isManual && now - _lastInitiativeCheckTime < repository.npcInitiativeMinInterval) || !CanPlayerBeApproached()
        return false
    endIf
    _lastInitiativeCheckTime = now

    FindInitiativeCandidates()
    if _initiativeCandidateCount == 0
        if repository.showNpcInitiativeMessages
            Debug.Notification("NPC Initiative: no NPCs nearby")
        endIf
        return false
    endIf

    MantellaConstants consts = conversation.mConsts
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, consts.KEY_REQUESTTYPE, consts.KEY_REQUESTTYPE_NPCINITIATIVE)
    SKSE_HTTP.setString(handle, consts.KEY_STARTCONVERSATION_WORLDID, PlayerRef.GetDisplayName() + repository.worldID)
    if isManual && repository.npcInitiativeHotkeySkipsThreshold
        SKSE_HTTP.setBool(handle, consts.KEY_NPCINITIATIVE_SKIPTHRESHOLD, true)
    endIf

    int[] actorHandles = Utility.CreateIntArray(_initiativeCandidateCount + 1)
    actorHandles[0] = conversation.buildActorSetting(PlayerRef)
    string candidateNames = ""
    int i = 0
    while i < _initiativeCandidateCount
        actorHandles[i + 1] = conversation.buildActorSetting(_initiativeCandidates[i])
        candidateNames += _initiativeCandidates[i].GetDisplayName() + " "
        i += 1
    endWhile
    SKSE_HTTP.setNestedDictionariesArray(handle, consts.KEY_ACTORS, actorHandles)

    int contextHandle = SKSE_HTTP.createDictionary()
    string locationName = "Skyrim"
    Location currentLocation = PlayerRef.GetCurrentLocation()
    if currentLocation && currentLocation.GetName() != ""
        locationName = currentLocation.GetName()
    endIf
    SKSE_HTTP.setString(contextHandle, consts.KEY_CONTEXT_LOCATION, locationName)
    SKSE_HTTP.setInt(contextHandle, consts.KEY_CONTEXT_TIME, conversation.GetCurrentHourOfDay())
    SKSE_HTTP.setNestedDictionary(handle, consts.KEY_CONTEXT, contextHandle)

    conversation.AddHeardLines(handle) ; Only sent while no conversation is running
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
    _initiativePending = true
    _isInitiativeManual = isManual
    _initiativeSentTime = now
    _lastPlayerConversationTime = now ; A sent check counts as the idle check, so the next one comes after the idle minutes again
    if repository.showNpcInitiativeMessages
        Debug.Notification("NPC Initiative check: " + candidateNames)
    endIf
    return true
EndFunction

bool Function CanPlayerBeApproached()
    return !conversation.IsRunning() && !PlayerRef.IsInCombat() && !PlayerRef.IsSneaking() && !Utility.IsInMenuMode() && !UI.IsMenuOpen("Dialogue Menu")
EndFunction

; True while a check sent to the server has not been answered yet. Its result may start a conversation
bool Function IsCheckPending(float now)
    return (_initiativePending && now - _initiativeSentTime < initiativePendingTimeout) || (_eventPending && now - _eventSentTime < eventPendingTimeout)
EndFunction

; Alive, awake, not hostile, not busy in a scene and free to talk. Used by NPC Initiative and NPC Events
bool Function IsAvailableNpc(Actor npc)
    return MantellaActorChecks.IsAvailableNpc(npc)
EndFunction

bool Function IsInitiativeCandidate(Actor npc)
    if !IsAvailableNpc(npc)
        return false
    endIf
    if !repository.npcInitiativeIncludeFollowers && IsActiveFollower(npc)
        return false
    endIf
    ; Either one seeing the other counts: the NPC's side lets NPCs behind the player count, the player's side lets
    ; NPCs who can't turn toward the player count, like those sitting facing away
    return repository.npcInitiativeIgnoreLineOfSight || npc.HasLOS(PlayerRef) || PlayerRef.HasLOS(npc)
EndFunction

; Following the player right now: a vanilla-style follower who is not told to wait, or one recruited with Mantella's follow action.
; Waiting, dismissed and potential followers are not active followers
bool Function IsActiveFollower(Actor npc)
    return MantellaActorChecks.IsActiveFollower(npc, repository)
EndFunction

; Keeps the nearest candidates in _initiativeCandidates: the nearest active followers, up to their own cap so a big
; group of followers can't crowd out everyone else, then the nearest other NPCs for the places left
Function FindInitiativeCandidates()
    int maxCount = ClampInt(repository.npcInitiativeMaxCandidates, 1, 10)
    int maxFollowers = 0
    if repository.npcInitiativeIncludeFollowers
        maxFollowers = ClampInt(repository.npcInitiativeMaxFollowers, 0, maxCount)
    endIf
    Actor[] followers = new Actor[10]
    float[] followerDistances = new float[10]
    int followerCount = 0
    Actor[] others = new Actor[10]
    float[] otherDistances = new float[10]
    int otherCount = 0

    ; ScanCellNPCs' own keyword filter misses keywords that come from the race, like ActorTypeNPC, so it is checked here
    Keyword actorTypeNPC = Keyword.GetKeyword("ActorTypeNPC")
    Actor[] found = MiscUtil.ScanCellNPCs(PlayerRef, ConvertMeterToGameUnits(repository.npcInitiativeMaxDistance))
    Actor npc
    int i = 0
    while i < found.Length
        npc = found[i]
        if npc.HasKeyword(actorTypeNPC) && IsInitiativeCandidate(npc)
            if IsActiveFollower(npc)
                followerCount = InsertByDistance(followers, followerDistances, followerCount, maxFollowers, npc, PlayerRef.GetDistance(npc))
            else
                otherCount = InsertByDistance(others, otherDistances, otherCount, maxCount, npc, PlayerRef.GetDistance(npc))
            endIf
        endIf
        i += 1
    endWhile

    _initiativeCandidates = new Actor[10]
    _initiativeCandidateCount = 0
    i = 0
    while i < followerCount
        _initiativeCandidates[_initiativeCandidateCount] = followers[i]
        _initiativeCandidateCount += 1
        i += 1
    endWhile
    i = 0
    while i < otherCount && _initiativeCandidateCount < maxCount
        _initiativeCandidates[_initiativeCandidateCount] = others[i]
        _initiativeCandidateCount += 1
        i += 1
    endWhile
EndFunction

; Inserts npc into a list sorted by distance that holds at most maxCount NPCs, dropping the farthest when it is full.
; Returns the new number of NPCs in the list
int Function InsertByDistance(Actor[] npcs, float[] distances, int count, int maxCount, Actor npc, float distance)
    if maxCount < 1 || (count >= maxCount && distance >= distances[count - 1])
        return count
    endIf
    int slot = count
    if count < maxCount
        count += 1
    else
        slot = count - 1
    endIf
    while slot > 0 && distances[slot - 1] > distance
        npcs[slot] = npcs[slot - 1]
        distances[slot] = distances[slot - 1]
        slot -= 1
    endWhile
    npcs[slot] = npc
    distances[slot] = distance
    return count
EndFunction

int Function ClampInt(int value, int min, int max)
    if value < min
        return min
    elseIf value > max
        return max
    endIf
    return value
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          NPC Events         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mantella's server invents a scene between some of the NPCs near the player, who then act it out while the player is a bystander.
; The player can watch, walk away or step in, and the NPCs can draw in others nearby, the player included.
; The scene runs in Shout from the start: the people nearby join by Shout, found with the NPC Event's rules while the player watches

float _lastEventCheckTime = 0.0
float _eventSentTime = 0.0
bool _eventPending = false
string _lastNpcEventOutcome = "" ; What came of the last check: "" while it waits for MantellaSoftware's answer. For the in-game tests
float eventPendingTimeout = 90.0 ; Seconds. The event generator writes a whole scene, so it can take longer than an NPC Initiative check
Actor[] _eventCandidates ; Everyone nearby named in the last check, nearest first. The scene's participants are among them
int _eventCandidateCount = 0
Form[] _eventBuiltActors ; The nearest candidates, sent in full with the last check
int[] _eventBuiltHandles ; Their actor settings, which the scene's start uses again
int _eventPlayerHandle = 0 ; The player's actor settings, sent with the check
int _npcEventBuildId = 0 ; Counts the builds asked for (BuildNpcEventActors). A newer one changes it, so an older build stops and its result is unused
int _npcEventBuildStartedId = 0 ; The last build that began running
int _npcEventBuildDoneId = 0 ; The last build that finished

string Function NPC_EVENT_BUILD_EVENT() global
    return "Mantella_NpcEventBuild"
EndFunction

; The hotkey checks right away, even when NPC Events are off or a check ran recently. Also NPC Event on the Conversation Wheel.
; If no check can be sent, the player is told why
Event OnNpcEventHotkey(string eventName, string strArg, float numArg, Form sender)
    string reason = TryNpcEventCheck(true)
    if reason != ""
        Debug.Notification("NPC Event: " + reason)
    elseIf !repository.showNpcEventMessages ; Otherwise the check already named the NPCs it considers
        Debug.Notification("NPC Event: checking nearby NPCs")
    endIf
EndEvent

Event OnEventTest(string eventName, string strArg, float numArg, Form sender)
    MantellaEventTest.Run(repository, conversation, self)
EndEvent

Event OnTalkTest(string eventName, string strArg, float numArg, Form sender)
    MantellaTalkTest.Run(repository, conversation, self)
EndEvent

Event OnActionTest(string eventName, string strArg, float numArg, Form sender)
    if numArg == 2.0
        MantellaActionTest.RunAdvanced(repository, conversation, self)
    elseIf numArg == 3.0 || numArg == 4.0 ; Other mods' actions, 4 with Advanced Actions on
        MantellaActionTest.RunOtherMods(repository, conversation, self, numArg == 4.0)
    else
        MantellaActionTest.Run(repository, conversation, self)
    endIf
EndEvent

; The in-game test of other mods' actions counts OStim's scenes while it runs (MantellaActionTest.RunOtherMods)
int property OStimScenesStarted auto hidden
int property OStimScenesEnded auto hidden

Function WatchOStimScenes(bool watch)
    if watch
        RegisterForModEvent("ostim_thread_start", "OnOStimSceneStart")
        RegisterForModEvent("ostim_thread_end", "OnOStimSceneEnd")
    else
        UnregisterForModEvent("ostim_thread_start")
        UnregisterForModEvent("ostim_thread_end")
    endIf
EndFunction

Event OnOStimSceneStart(string eventName, string strArg, float numArg, Form sender)
    OStimScenesStarted += 1
EndEvent

Event OnOStimSceneEnd(string eventName, string strArg, float numArg, Form sender)
    OStimScenesEnded += 1
EndEvent

Event OnHeardLinesTest(string eventName, string strArg, float numArg, Form sender)
    MantellaHeardLinesTest.Run(numArg as int, repository, conversation)
EndEvent

; Returns true if a check was sent to the server
bool Function TryNpcEvent(bool isManual = false)
    return TryNpcEventCheck(isManual) == ""
EndFunction

; Returns "" if a check was sent to the server, otherwise why not, as the player is told it
string Function TryNpcEventCheck(bool isManual)
    if _isSendingCheck
        return "busy with another check, try again in a moment"
    endIf
    _isSendingCheck = true
    string reason = RunNpcEventCheck(isManual)
    _isSendingCheck = false
    return reason
EndFunction

; Started by the player (isManual), with Ask for a Hint, a text box asks what they would like to happen, once there are enough people nearby.
; Cancelled or empty: a surprise
string Function RunNpcEventCheck(bool isManual)
    if !repository.npcEventEnabled && !isManual
        return "NPC Events are off"
    endIf
    string reason = WhyNpcEventCantStart()
    if reason != ""
        return reason
    endIf
    float now = Utility.GetCurrentRealTime()
    if IsCheckPending(now)
        return "busy with another check, try again in a moment"
    elseIf !isManual && now - _lastEventCheckTime < repository.npcEventFrequency * 60
        return "too soon after the last check"
    endIf
    _lastEventCheckTime = now
    _lastNpcEventOutcome = ""

    FindNpcEventCandidates()
    if _eventCandidateCount < 2
        if !isManual && repository.showNpcEventMessages ; The hotkey tells the player itself
            Debug.Notification("NPC Event: not enough NPCs nearby")
        endIf
        return "not enough people nearby, it needs at least 2"
    endIf

    string hint = ""
    _npcEventBuildId += 1
    int buildId = _npcEventBuildId
    if isManual && repository.npcEventAskForHint
        StartNpcEventBuild(buildId) ; While the player types
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        hint = UIExtensions.GetMenuResultString("UITextEntryMenu")
        Utility.Wait(0.1) ; Only counts once the text box has closed, so the check below doesn't see the game still in a menu
        reason = WhyNpcEventCantStart() ; Something may have started while the player typed
        if reason != ""
            _npcEventBuildId += 1 ; The build stops
            return reason
        endIf
        now = Utility.GetCurrentRealTime() ; The check is sent now, not when the text box opened
        buildId = FinishNpcEventBuild(buildId)
    else
        BuildNpcEventActors(buildId)
    endIf
    if _npcEventBuildDoneId != buildId ; Replaced by another check: its people aren't these
        return "busy with another check, try again in a moment"
    endIf

    MantellaConstants consts = conversation.mConsts
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, consts.KEY_REQUESTTYPE, consts.KEY_REQUESTTYPE_NPCEVENT)
    SKSE_HTTP.setString(handle, consts.KEY_STARTCONVERSATION_WORLDID, PlayerRef.GetDisplayName() + repository.worldID)
    if hint != ""
        SKSE_HTTP.setString(handle, consts.KEY_EVENT_HINT, hint)
    endIf

    ; Everyone nearby by name. Only the nearest (Most People Described) in full, so the event generator gets their bios and memories.
    ; Built by BuildNpcEventActors
    int described = 0
    if _eventBuiltHandles
        described = _eventBuiltHandles.Length
    endIf
    int[] actorHandles = Utility.CreateIntArray(described + 1)
    actorHandles[0] = _eventPlayerHandle
    int[] refids = Utility.CreateIntArray(_eventCandidateCount)
    string[] names = Utility.CreateStringArray(_eventCandidateCount)
    string candidateNames = ""
    int i = 0
    while i < _eventCandidateCount
        refids[i] = (_eventCandidates[i] as Form).GetFormID()
        names[i] = _eventCandidates[i].GetDisplayName()
        if i < described
            actorHandles[i + 1] = _eventBuiltHandles[i]
            candidateNames += names[i] + " "
        endIf
        i += 1
    endWhile
    if _eventCandidateCount > described
        candidateNames += "and " + (_eventCandidateCount - described) + " more by name"
    endIf
    SKSE_HTTP.setNestedDictionariesArray(handle, consts.KEY_ACTORS, actorHandles)
    SKSE_HTTP.setIntArray(handle, consts.KEY_NPCEVENT_NEARBY_REFIDS, refids)
    SKSE_HTTP.setStringArray(handle, consts.KEY_NPCEVENT_NEARBY_NAMES, names)

    int contextHandle = SKSE_HTTP.createDictionary()
    string locationName = "Skyrim"
    Location currentLocation = PlayerRef.GetCurrentLocation()
    if currentLocation && currentLocation.GetName() != ""
        locationName = currentLocation.GetName()
    endIf
    SKSE_HTTP.setString(contextHandle, consts.KEY_CONTEXT_LOCATION, locationName)
    SKSE_HTTP.setInt(contextHandle, consts.KEY_CONTEXT_TIME, conversation.GetCurrentHourOfDay())
    conversation.AddCurrentWeather(contextHandle)
    SKSE_HTTP.setNestedDictionary(handle, consts.KEY_CONTEXT, contextHandle)

    conversation.AddHeardLines(handle) ; Only sent while no conversation is running
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
    _eventPending = true
    _eventSentTime = now
    if repository.showNpcEventMessages
        Debug.Notification("NPC Event check: " + candidateNames)
    endIf
    return ""
EndFunction

; Builds the player's actor settings and the nearest candidates' (Most People Described), for the check and then the scene's start.
; Building someone takes a moment, so with Ask for a Hint it runs on another thread while the player types (StartNpcEventBuild)
Function BuildNpcEventActors(int buildId)
    _npcEventBuildStartedId = buildId
    Actor[] candidates = _eventCandidates
    int described = ClampInt(repository.npcEventMaxCandidates, 2, 10)
    if described > _eventCandidateCount
        described = _eventCandidateCount
    endIf
    Form[] built = Utility.CreateFormArray(described)
    int[] handles = Utility.CreateIntArray(described)
    int playerHandle = conversation.buildActorSetting(PlayerRef)
    int i = 0
    while i < described
        if buildId != _npcEventBuildId
            return ; Replaced, or the check was given up
        endIf
        built[i] = candidates[i]
        handles[i] = conversation.buildActorSetting(candidates[i])
        i += 1
    endWhile
    if buildId != _npcEventBuildId || _npcEventBuildDoneId == buildId
        return
    endIf
    _eventBuiltActors = built
    _eventBuiltHandles = handles
    _eventPlayerHandle = playerHandle
    _npcEventBuildDoneId = buildId
EndFunction

Function StartNpcEventBuild(int buildId)
    RegisterForModEvent(NPC_EVENT_BUILD_EVENT(), "OnNpcEventBuild") ; Again here, in case this save never registered it on load
    int eventHandle = ModEvent.Create(NPC_EVENT_BUILD_EVENT())
    if eventHandle
        ModEvent.PushInt(eventHandle, buildId)
        ModEvent.Send(eventHandle)
    endIf
EndFunction

Event OnNpcEventBuild(int buildId)
    if buildId != _npcEventBuildId || _npcEventBuildStartedId == buildId || _npcEventBuildDoneId == buildId
        return ; Replaced, or FinishNpcEventBuild built them itself
    endIf
    BuildNpcEventActors(buildId)
EndEvent

; Waits for the build to finish. If it never began (the mod event didn't arrive), or still runs after MAX_BUILD_WAIT (it should never take
; that long), it is given up and the people are built here. Returns the id of the build whose people are ready
int Function FinishNpcEventBuild(int buildId)
    float waited = 0.0
    while _npcEventBuildDoneId != buildId && buildId == _npcEventBuildId && (_npcEventBuildStartedId == buildId || waited < 2.0) && waited < MantellaConversation.MAX_BUILD_WAIT()
        Utility.WaitMenuMode(0.1)
        waited += 0.1
    endWhile
    if _npcEventBuildDoneId != buildId && buildId == _npcEventBuildId
        if _npcEventBuildStartedId == buildId
            _npcEventBuildId += 1 ; Given up: the build stops at its next step, and its result is unused
            buildId = _npcEventBuildId
        endIf
        BuildNpcEventActors(buildId)
    endIf
    return buildId
EndFunction

bool Function CanNpcEventStart()
    return WhyNpcEventCantStart() == ""
EndFunction

; Why an NPC Event can't start now, as the player is told it. "" if it can. The player can be sneaking: watching unseen is part of it
string Function WhyNpcEventCantStart()
    if conversation.IsRunning()
        return "a conversation is already running"
    elseIf PlayerRef.IsInCombat()
        return "not during combat"
    elseIf Utility.IsInMenuMode() || UI.IsMenuOpen("Dialogue Menu")
        return "not while a menu or dialogue is open"
    endIf
    return ""
EndFunction

; Keeps everyone nearby in _eventCandidates, nearest first: within the NPC Event's Hearing Distance, at most the Shout Mode page's
; Most People Listed. Line of sight is not needed
Function FindNpcEventCandidates()
    _eventCandidates = MantellaShout.FindNearbyForNpcEvent(repository, conversation)
    _eventCandidateCount = 0
    if _eventCandidates
        _eventCandidateCount = _eventCandidates.Length
    endIf
EndFunction

Actor Function FindNpcEventCandidate(int refid)
    int i = 0
    while i < _eventCandidateCount
        if (_eventCandidates[i] as Form).GetFormID() == refid
            return _eventCandidates[i]
        endIf
        i += 1
    endWhile
    return None
EndFunction

Function OnNpcEventResult(int handle)
    MantellaConstants consts = conversation.mConsts
    _eventPending = false
    int eventId = SKSE_HTTP.getInt(handle, consts.KEY_NPCEVENT_ID, 0)
    int[] refids = SKSE_HTTP.getIntArray(handle, consts.KEY_NPCEVENT_PARTICIPANT_REFIDS)
    if eventId == 0 || refids.Length < 2
        NoteNpcEventOutcome("nothing happens")
        if repository.showNpcEventMessages
            Debug.Notification("NPC Event: nothing happens")
        endIf
        return
    endIf
    ; The situation may have changed while the server wrote the event
    Actor[] participants = PapyrusUtil.ActorArray(refids.Length)
    string names = ""
    int i = 0
    while i < refids.Length
        Actor npc = FindNpcEventCandidate(refids[i])
        if !npc || !IsAvailableNpc(npc) || !CanNpcEventStart()
            if !npc
                NoteNpcEventOutcome("can no longer start: someone in it isn't among the people nearby")
            elseIf !IsAvailableNpc(npc)
                NoteNpcEventOutcome("can no longer start: " + npc.GetDisplayName() + " is " + MantellaActorChecks.UnavailableReason(npc))
            else
                NoteNpcEventOutcome("can no longer start: " + WhyNpcEventCantStart())
            endIf
            if repository.showNpcEventMessages
                Debug.Notification("NPC Event: can no longer start")
            endIf
            return
        endIf
        participants[i] = npc
        names += npc.GetDisplayName() + " "
        i += 1
    endWhile
    NoteNpcEventOutcome("starts: " + names)
    if repository.showNpcEventMessages
        Debug.Notification("NPC Event starts: " + names)
    endIf
    string text = SKSE_HTTP.getString(handle, consts.KEY_EVENT_TEXT, "")
    bool showText = text != "" && repository.ShowsEventText("npc")
    conversation.Start()
    conversation.SetNpcEvent(eventId)
    conversation.SetNpcEventScan(_eventCandidates, _eventBuiltActors, _eventBuiltHandles) ; So the start doesn't scan and build again
    if showText
        conversation.HoldForEventText()
    endIf
    conversation.StartConversation(participants)
    if showText
        ; The conversation is started first, so MantellaSoftware writes and voices the first line while the text is read.
        ; Waits until the box is closed: nobody speaks before. The game is paused meanwhile
        conversation.ShowEventText("npc", text)
    endIf
EndFunction

; Kept for the in-game tests, and written to the Papyrus log, so a scene that doesn't start says why
Function NoteNpcEventOutcome(string outcome)
    _lastNpcEventOutcome = outcome
    Debug.Trace("Mantella NPC Event: " + outcome)
EndFunction

; Whether MantellaSoftware has answered the last check
bool Function IsNpcEventCheckAnswered()
    return _lastNpcEventOutcome != ""
EndFunction

string Function LastNpcEventOutcome()
    if _lastNpcEventOutcome == ""
        return "no answer from MantellaSoftware"
    endIf
    return _lastNpcEventOutcome
EndFunction

; The server picked the player watching the scene, who joins before anyone speaks again. People nearby join by Shout instead
Function AddNpcEventActor(int refid)
    if !conversation.IsRunning() || !conversation.IsNpcEvent()
        return
    endIf
    if refid == (PlayerRef as Form).GetFormID()
        conversation.AddNpcEventActor(PlayerRef)
    endIf
EndFunction

; Runs on every tick while an NPC Event is running. Ends the scene once a bystander player has walked away,
; and tells the server whether the player can be noticed. Who is nearby goes with the Shout values
Function MonitorNpcEvent()
    float hearingDistance = ConvertMeterToGameUnits(repository.npcEventHearingDistance)
    bool isPlayerInScene = conversation.IsPlayerInConversation()
    float nearestDistance = -1.0
    bool isInSight = false
    int i = 0
    while i < conversation.CountActorsInConversation()
        Actor participant = conversation.GetActorInConversationByIndex(i)
        if participant && participant != PlayerRef
            float distance = PlayerRef.GetDistance(participant)
            if nearestDistance < 0 || distance < nearestDistance
                nearestDistance = distance
            endIf
            ; Either one seeing the other counts, as for NPC Initiative
            if repository.npcEventRequireLineOfSight && !isInSight && distance <= hearingDistance
                isInSight = participant.HasLOS(PlayerRef) || PlayerRef.HasLOS(participant)
            endIf
        endIf
        i += 1
    endWhile
    if nearestDistance < 0
        return ; The scene is still starting and nobody has been added yet. A scene that loses its NPCs is ended by RemoveActors
    endIf
    if !isPlayerInScene && nearestDistance > hearingDistance
        if repository.showNpcEventMessages
            Debug.Notification("NPC Event: you walked away")
        endIf
        conversation.EndConversation()
        return
    endIf
    bool isNoticeable = !isPlayerInScene && nearestDistance <= hearingDistance && !PlayerRef.IsSneaking() && (isInSight || !repository.npcEventRequireLineOfSight)
    conversation.SetNpcEventMonitorValues(isNoticeable)
EndFunction

event OnHttpReplyReceived(int typedDictionaryHandle)
    MantellaConstants consts = conversation.mConsts
    HandleVoiceReplyParts(typedDictionaryHandle, consts)
    string replyType = SKSE_HTTP.getString(typedDictionaryHandle, consts.KEY_REPLYTYPE, "")
    if replyType == consts.KEY_REPLYTYPE_NPCEVENT
        OnNpcEventResult(typedDictionaryHandle)
        return
    elseIf replyType == consts.KEY_REPLYTYPE_NPCEVENT_ADDACTOR
        AddNpcEventActor(SKSE_HTTP.getInt(typedDictionaryHandle, consts.KEY_NPCEVENT_ADDACTOR_REFID, 0))
        return
    elseIf replyType == consts.KEY_REPLYTYPE_QUESTCHECKLIST
        repository.SetQuestCheckList(SKSE_HTTP.getNestedDictionary(typedDictionaryHandle, consts.KEY_QUESTCHECKS_LIST), consts)
        return
    elseIf replyType != consts.KEY_REPLYTYPE_NPCINITIATIVE
        return
    endIf
    _initiativePending = false
    int chosenRefId = SKSE_HTTP.getInt(typedDictionaryHandle, consts.KEY_NPCINITIATIVE_CHOSEN_REFID, 0)
    Actor chosen = None
    int i = 0
    while i < _initiativeCandidateCount && chosenRefId != 0
        if (_initiativeCandidates[i] as Form).GetFormID() == chosenRefId
            chosen = _initiativeCandidates[i]
        endIf
        i += 1
    endWhile
    if !chosen
        if repository.showNpcInitiativeMessages
            Debug.Notification("NPC Initiative: nobody")
        else
            NotifyNobodyComes()
        endIf
        return
    endIf
    ; The situation may have changed while the server decided
    if !CanPlayerBeApproached() || !IsInitiativeCandidate(chosen)
        if repository.showNpcInitiativeMessages
            Debug.Notification("NPC Initiative: " + chosen.GetDisplayName() + " can no longer approach")
        else
            NotifyNobodyComes()
        endIf
        return
    endIf
    if repository.showNpcInitiativeMessages
        Debug.Notification("NPC Initiative: " + chosen.GetDisplayName() + " approaches")
    endIf
    Actor[] actors = new Actor[2]
    actors[0] = PlayerRef
    actors[1] = chosen
    conversation.Start()
    conversation.SetNpcInitiative()
    conversation.StartConversation(actors)
endEvent

; Only for checks the player started. The automatic checks stay quiet when nobody comes.
; A conversation the player started while the check waited also gives "nobody", which needs no note
Function NotifyNobodyComes()
    if _isInitiativeManual && !conversation.IsRunning()
        Debug.Notification("Nobody comes over")
    endIf
EndFunction

