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
    Debug.Notification("Please save and reload to activate Mantella.")
endEvent

Function AddIngameEventToConversation(string eventText)
    If (conversation.IsRunning())
        conversation.AddIngameEvent(eventText)
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
    If(conversation.IsRunning())
        conversation.EndConversation()
    endif
    ; If (MantellaMCMQuest.IsRunning() || MantellaMCMQuest.IsNotProperlyInitialised())
    ;     Debug.MessageBox("Detecting old version of Mantella in this save. MCM settings will be reset once.")
    ;     MantellaMCMQuest.Stop()
    ;     MantellaMCMQuest.Start()
    ;     MantellaMCMQuest.OnConfigInit()
    ;     repository.assignDefaultSettings(0,true)
    ; EndIf
    RegisterForModEvent("SKSE_HTTP_OnHttpReplyReceived", "OnHttpReplyReceived")
    RegisterForModEvent("Mantella_NpcInitiativeHotkey", "OnNpcInitiativeHotkey")
    RegisterForMenu("Loading Menu")
    _lastCell = PlayerRef.GetParentCell()
    ; Real time starts from 0 on every game launch, so times kept in the save would be in the future
    _initiativePending = false
    _isCheckingInitiative = false ; In case the save was made during a check
    _lastInitiativeCheckTime = Utility.GetCurrentRealTime()
    _lastPlayerConversationTime = _lastInitiativeCheckTime
    _initiativeSentTime = _lastInitiativeCheckTime
    RegisterForSingleUpdate(repository.radiantFrequency)
EndEvent

event OnUpdate()
    bool hasSentInitiativeCheck = false
    if conversation.IsRunning() && conversation.IsPlayerInConversation()
        _lastPlayerConversationTime = Utility.GetCurrentRealTime()
    elseIf repository.npcInitiativeEnabled && repository.npcInitiativeIdleMinutes > 0 && Utility.GetCurrentRealTime() - _lastPlayerConversationTime >= repository.npcInitiativeIdleMinutes * 60
        hasSentInitiativeCheck = TryNpcInitiative()
    endIf
    ; No radiant attempt in the same tick, so a radiant conversation and the NPC Initiative check don't start together
    if repository.radiantEnabled && !hasSentInitiativeCheck
        ; if no Mantella conversation active
        if !conversation.IsRunning()
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
        endIf
    endIf
    RegisterForSingleUpdate(repository.radiantFrequency)
endEvent


;All the event listeners  below have 'if' clauses added after Mantella 0.9.2 (except ondying)
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if repository.playerTrackingOnItemAdded
        string itemName = akBaseItem.GetName()
        string itemCount = ""
        if itemName == "gold" ; only count the number of items if it is gold
            itemCount = aiItemCount+" "
        endIf
        string itemPickedUpMessage = getPlayerName() + " picked up / took " + itemCount + itemName 

        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != ""
            itemPickedUpMessage = getPlayerName() + " picked up / took " + itemCount + itemName + " from " + sourceName 
        endIf
        
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
            itemCount = aiItemCount+" "
        endIf
        string itemDroppedMessage = getPlayerName() + " dropped " + itemCount + itemName 

        string destName = akDestContainer.getbaseobject().getname()
        if destName != ""
            itemDroppedMessage = getPlayerName() + " placed/gave " + itemCount + itemName + " in/on/to " + destName 
        endIf
        
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
                ;Debug.Notification("The player casted the spell "+ spellCast)
                AddIngameEventToConversation(getPlayerName() + " casted the spell / consumed " + spellCast )
            endIf
        endIf
    endif
endEvent


String lastHitSource = ""
String lastAggressor = ""
Int timesHitSameAggressorSource = 0
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    if repository.playerTrackingOnHit
        string aggressor = akAggressor.getdisplayname()
        string hitSource = akSource.getname()

        ; avoid writing events too often (continuous spells record very frequently)
        ; if the actor and weapon hasn't changed, only record the event every 5 hits
        if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5) && (hitSource != "Mantella") && (hitSource != "Mantella Remove NPC") && (hitSource != "Mantella End Conversation")
            lastHitSource = hitSource
            lastAggressor = aggressor
            timesHitSameAggressorSource = 0
            
            if (aggressor == "None") || (aggressor == "")
                AddIngameEventToConversation(getPlayerName() + " took damage.")
            elseif (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched the player.")
                AddIngameEventToConversation(aggressor + " punched " + getPlayerName(False) + " .")
            else
                ;Debug.MessageBox(aggressor + " hit the player with " + hitSource)
                AddIngameEventToConversation(aggressor + " hit " + getPlayerName(False) + " with " + hitSource)
            endIf
        else
            timesHitSameAggressorSource += 1
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
        AddIngameEventToConversation(getPlayerName() + " fired an arrow.")
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        NPC Initiative       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A nearby NPC who has a reason to talk to the player walks up and starts a conversation.
; Mantella's server decides who (if anyone) that is.

float _lastInitiativeCheckTime = 0.0
float _lastPlayerConversationTime = 0.0
float _initiativeSentTime = 0.0
bool _initiativePending = false
Actor[] _initiativeCandidates
int _initiativeCandidateCount = 0
float initiativePendingTimeout = 30.0 ; Seconds. An error reply can't be told apart from other requests' errors, so a lost reply times out
bool _isCheckingInitiative = false

; The hotkey checks right away, even when NPC Initiative is off or a check ran recently
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
    if _isCheckingInitiative
        return false
    endIf
    _isCheckingInitiative = true
    bool hasSent = RunNpcInitiativeCheck(isManual)
    _isCheckingInitiative = false
    return hasSent
EndFunction

bool Function RunNpcInitiativeCheck(bool isManual)
    if (!repository.npcInitiativeEnabled && !isManual) || conversation.IsRunning()
        return false
    endIf
    float now = Utility.GetCurrentRealTime()
    if _initiativePending && now - _initiativeSentTime < initiativePendingTimeout
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

    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, consts.HTTP_ROUTE_MAIN)
    _initiativePending = true
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

bool Function IsInitiativeCandidate(Actor npc)
    if !npc || npc == PlayerRef || npc.IsDisabled() || npc.IsDead() || npc.IsUnconscious() || npc.IsBleedingOut()
        return false
    endIf
    if npc.IsHostileToActor(PlayerRef) || npc.IsInCombat()
        return false
    endIf
    if !repository.npcInitiativeIncludeFollowers && IsActiveFollower(npc)
        return false
    endIf
    if npc.GetSleepState() == 3 || npc.IsInDialogueWithPlayer() ; 3 is asleep
        return false
    endIf
    ; Either one seeing the other counts: the NPC's side lets NPCs behind the player count, the player's side lets
    ; NPCs who can't turn toward the player count, like those sitting facing away
    return repository.npcInitiativeIgnoreLineOfSight || npc.HasLOS(PlayerRef) || PlayerRef.HasLOS(npc)
EndFunction

; Following the player right now: a vanilla-style follower who is not told to wait, or one recruited with Mantella's follow action.
; Waiting, dismissed and potential followers are not active followers
bool Function IsActiveFollower(Actor npc)
    if npc.IsPlayerTeammate() && npc.GetActorValue("WaitingForPlayer") == 0
        return true
    endIf
    return npc.GetFactionRank(repository.giafac_Following) >= 1 ; Mantella's follow action sets rank 1, ending it sets -2
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

event OnHttpReplyReceived(int typedDictionaryHandle)
    MantellaConstants consts = conversation.mConsts
    if SKSE_HTTP.getString(typedDictionaryHandle, consts.KEY_REPLYTYPE, "") != consts.KEY_REPLYTYPE_NPCINITIATIVE
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
        endIf
        return
    endIf
    ; The situation may have changed while the server decided
    if !CanPlayerBeApproached() || !IsInitiativeCandidate(chosen)
        if repository.showNpcInitiativeMessages
            Debug.Notification("NPC Initiative: " + chosen.GetDisplayName() + " can no longer approach")
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

