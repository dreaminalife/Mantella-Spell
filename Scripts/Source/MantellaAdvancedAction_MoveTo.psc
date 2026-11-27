Scriptname MantellaAdvancedAction_MoveTo extends Quest Hidden
{Walks NPCs over to someone: the MoveTo action, and NPCs Walk Over to Talk. Twelve walking places, one for each of the quest's
MoveToSourceAlias1-12 (aliases 0 to 11), which have the MoveTo package: it follows MoveToTargetAlias, so everyone walking goes to
the same person}

Actor Property PlayerRef Auto
MantellaRepository property repository Auto
MantellaConstants property mConsts Auto
MantellaInterface property EventInterface Auto
Faction Property MantellaFunctionSourceFaction Auto
Package Property MantellaMoveToPackage Auto
ReferenceAlias Property MoveToTargetAlias Auto

Actor[] _movingActors ; Who walks in each place. None: the place is free
bool[] _wasWaitingBeforeMove ; Track wait states to restore after movement
bool[] _isWalkingOver ; Sent by NPCs Walk Over to Talk, not by the MoveTo action
int _placesVersion = 0 ; 1 once the places are set up. Saves from before kept who walked last in _movingActors after they stopped
int _actionNumber = 0 ; Goes up with each MoveTo action, so an older one still waiting leaves the newer one's walkers alone

; Near enough to count as next to the player, in game units: about 4.5 m. NPCs Walk Over to Talk sends those farther away, and lets them
; go once they're this close. The MoveTo package stops them within 3.6 m
float Function WALK_OVER_DISTANCE() global
    return 320.0
EndFunction

event OnInit()
    RegisterForModEvent(EventInterface.EVENT_ACTIONS_PREFIX + mConsts.ACTION_NPC_MOVETO, "OnNpcMoveToActionReceived")
    RegisterForModEvent(EventInterface.EVENT_ADVANCED_ACTIONS_PREFIX + mConsts.ACTION_NPC_MOVETO, "OnNpcMoveToAdvancedActionReceived")
EndEvent

event OnNpcMoveToActionReceived(Form speaker)
    int thisAction = StartAction(PlayerRef)
    StartWalking(speaker as Actor, PlayerRef, false)
    WaitForMovement(PlayerRef, thisAction)
    EndAction(thisAction)
endEvent


event OnNpcMoveToAdvancedActionReceived(Form speaker, Form conversationQuest, int argumentsHandle)
    MantellaConversation conversation = conversationQuest as MantellaConversation

    ; Extract NPC names from parameters
    string[] sourceNames = SKSE_HTTP.getStringArray(argumentsHandle, mConsts.ACTION_ARG_SOURCE)
    string targetName = SKSE_HTTP.getString(argumentsHandle, mConsts.ACTION_ARG_TARGET)

    ; Only one target supported for move to action
    Actor targetActor = conversation.GetActorByName(targetName)
    if targetActor
        int thisAction = StartAction(targetActor)
        int numSources = sourceNames.Length
        if numSources > 12
            numSources = 12  ; Cap at available aliases
        endif

        ; Resolve each name to an Actor reference and start movement
        int i = 0
        While i < numSources
            Actor sourceActor = conversation.GetActorByName(sourceNames[i])
            if sourceActor
                StartWalking(sourceActor, targetActor, false)
            endif
            i += 1
        EndWhile

        ; Wait for actors to reach destination
        WaitForMovement(targetActor, thisAction)
        EndAction(thisAction)
    endIf
endEvent


; A new MoveTo action takes over from an older one still under way, whose walkers stop where they are. Those walking over to talk keep
; going if this action sends people to the player too. Otherwise they stop where they are: everyone walking goes to the same person
int Function StartAction(Actor target)
    EnsurePlaces()
    _actionNumber += 1
    int i = 0
    While i < 12
        if _movingActors[i] && (!_isWalkingOver[i] || target != PlayerRef)
            StopWalking(i)
        endIf
        i += 1
    EndWhile
    MoveToTargetAlias.ForceRefTo(target)
    return _actionNumber
EndFunction

; Once the action's walkers have arrived, or after 30 seconds, they stop following and stand still. Unless a newer action took over
Function EndAction(int thisAction)
    if thisAction != _actionNumber
        return
    endIf
    int i = 0
    While i < 12
        if _movingActors[i] && !_isWalkingOver[i]
            StopWalking(i)
        endIf
        i += 1
    EndWhile
    ClearTargetIfNobodyWalks()
EndFunction


; Sends the NPC walking to the target, in a free place, or theirs if they're walking already. The target is in MoveToTargetAlias.
; False when all twelve places are taken
bool Function StartWalking(Actor source, Actor target, bool isWalkingOver)
    if !source || !target
        return false
    endIf
    int place = _movingActors.Find(source)
    if place < 0
        place = FreePlace()
        if place < 0
            return false
        endIf
        ; Store wait state to restore it after movement
        bool wasWaiting = false
        if source.IsPlayerTeammate()
            wasWaiting = (source.GetActorValue("WaitingForPlayer") == 1)
            if wasWaiting
                ; Temporarily clear wait so the NPC can move
                source.SetActorValue("WaitingForPlayer", 0)
            endif
        endif
        _wasWaitingBeforeMove[place] = wasWaiting
        _movingActors[place] = source
    endIf
    _isWalkingOver[place] = isWalkingOver ; The MoveTo action takes over someone walking over to talk
    if !isWalkingOver
        Debug.Notification(source.GetDisplayName() + " moves to " + target.GetDisplayName() + ".")
    endIf

    ; Add to MoveTo faction
    source.SetFactionRank(MantellaFunctionSourceFaction, 1)

    ; Assign to specific alias which has the MoveTo package
    ReferenceAlias sourceAlias = self.GetNthAlias(place) as ReferenceAlias
    sourceAlias.ForceRefTo(source)
    source.EvaluatePackage()
    return true
EndFunction

; The walker in this place stops following and goes back to what they did before: standing still to talk, in a conversation
Function StopWalking(int place)
    Actor a = _movingActors[place]
    ReferenceAlias sourceAlias = GetNthAlias(place) as ReferenceAlias
    sourceAlias.Clear()
    if a
        if a.GetFactionRank(MantellaFunctionSourceFaction) == 1 ; Not another action's rank (Loot, Flee) given since
            a.RemoveFromFaction(MantellaFunctionSourceFaction)
        endIf
        ; Restore wait state if actor was waiting before movement
        if _wasWaitingBeforeMove[place] && a.IsPlayerTeammate()
            a.SetActorValue("WaitingForPlayer", 1)
        endif
        a.EvaluatePackage()
    endIf
    _movingActors[place] = None
    _wasWaitingBeforeMove[place] = false
    _isWalkingOver[place] = false
EndFunction


Function WaitForMovement(Actor target, int thisAction)
    float elapsedTime = 0.0
    float maxWaitTime = 30.0
    float checkInterval = 5.0

    While elapsedTime < maxWaitTime && thisAction == _actionNumber
        bool allNearTarget = true
        int i = 0

        ; Check if all of the action's walkers are near the target
        While i < 12
            if _movingActors[i] && !_isWalkingOver[i]
                float distance = _movingActors[i].GetDistance(target)
                if distance > 256.0  ; Within default follow distance
                    allNearTarget = false
                endif
            endif
            i += 1
        EndWhile

        if allNearTarget
            return
        endif

        Utility.Wait(checkInterval)
        elapsedTime += checkInterval
    EndWhile
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   NPCs Walk Over to Talk    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The NPC walks over to the player, and stands still to talk once StopArrivedWalkOvers finds them next to the player. Not while a
; MoveTo action sends people to someone else: the action comes first. False when the NPC isn't sent
bool Function WalkOver(Actor npc)
    EnsurePlaces()
    if _movingActors.Find(npc) >= 0
        return false ; Sent by the MoveTo action, which lets them go
    endIf
    if HasActionWalkers() && MoveToTargetAlias.GetReference() != PlayerRef
        return false
    endIf
    MoveToTargetAlias.ForceRefTo(PlayerRef)
    return StartWalking(npc, PlayerRef, true)
EndFunction

; Those walking over who are now next to the player stop following and stand still to talk. The conversation runs this with each NPC
; line. Returns whether anyone is still walking over
bool Function StopArrivedWalkOvers()
    if _placesVersion != 1
        return false
    endIf
    bool isStillWalking = false
    int i = 0
    While i < 12
        if _movingActors[i] && _isWalkingOver[i]
            if _movingActors[i].GetDistance(PlayerRef) <= WALK_OVER_DISTANCE()
                StopWalking(i)
            else
                isStillWalking = true
            endIf
        endIf
        i += 1
    EndWhile
    ClearTargetIfNobodyWalks()
    return isStillWalking
EndFunction

; Everyone walking over stops where they are: the conversation ended
Function StopWalkOvers()
    if _placesVersion != 1
        return
    endIf
    int i = 0
    While i < 12
        if _movingActors[i] && _isWalkingOver[i]
            StopWalking(i)
        endIf
        i += 1
    EndWhile
    ClearTargetIfNobodyWalks()
EndFunction

; The NPC stops where they are if they're walking over: they left the conversation
Function StopWalkOver(Actor npc)
    if _placesVersion != 1
        return
    endIf
    int place = _movingActors.Find(npc)
    if place >= 0 && _isWalkingOver[place]
        StopWalking(place)
        ClearTargetIfNobodyWalks()
    endIf
EndFunction


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Walking places        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function EnsurePlaces()
    if _placesVersion != 1 || !_movingActors || _movingActors.Length != 12 || !_wasWaitingBeforeMove || !_isWalkingOver
        _movingActors = new Actor[12]
        _wasWaitingBeforeMove = new bool[12]
        _isWalkingOver = new bool[12]
        _placesVersion = 1
    endIf
EndFunction

int Function FreePlace()
    int i = 0
    While i < 12
        if !_movingActors[i]
            return i
        endIf
        i += 1
    EndWhile
    return -1
EndFunction

bool Function HasActionWalkers()
    int i = 0
    While i < 12
        if _movingActors[i] && !_isWalkingOver[i]
            return true
        endIf
        i += 1
    EndWhile
    return false
EndFunction

Function ClearTargetIfNobodyWalks()
    int i = 0
    While i < 12
        if _movingActors[i]
            return
        endIf
        i += 1
    EndWhile
    MoveToTargetAlias.Clear()
EndFunction
