Scriptname MantellaConversation extends Quest hidden

Import SKSE_HTTP
Import Utility

Topic property MantellaDialogueLine1 auto
Topic property MantellaDialogueLine2 auto
MantellaRepository property repository auto
MantellaConstants property mConsts auto
Faction Property MantellaConversationParticipantsFaction Auto
FormList Property Participants auto
Quest Property MantellaConversationParticipantsQuest auto
SPELL Property MantellaIsTalkingSpell Auto
MantellaEquipmentDescriber Property EquipmentDescriber auto
Actor Property PlayerRef Auto
VoiceType Property MantellaVoice00  Auto  
MantellaInterface property EventInterface Auto
ReferenceAlias Property Narrator Auto
MantellaListenerScript Property Listener Auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Globals           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

String[] _ingameEvents
String[] _extraRequestActions
int[] _actorHandles = None
Form[] _actorHandleActors ; Who each of _actorHandles is for, in the same order
Form[] _staleActors ; Were in the conversation before the last join or leave: their actor settings are built again by RefreshStaleActors
bool _actorsUpdated = false
int _contextHandle = 0
bool _does_accept_player_input = false
bool _isTalking = false
bool _hasBeenStopped = true
; Each start takes the next number, and ending a conversation moves it on too. So a start still being built when the conversation is ended,
; or when a save made while it was being built is loaded (EndAfterSaveLoad ends it), sees that and isn't sent: what it built is gone by then
int _startNumber = 0
Actor _lastNpcToSpeak = None
string _lastSpeakerName = ""
string _repeatingMessage = ""
string _location = ""
int _initialTime = 0
bool _useNarrator = False
int _lastTopicInfo = 0
float httpReceivedTime = 0.0
string lineToSpeakError = "Error: No line transmitted for actor to speak"
bool microphoneEnabledLastKnownStatus = false
Actor[] _cachedNearbyActors ; The people near the player at the last context, for actions aimed at someone not in the conversation
bool _waitingForActionResponse = true
int _actionResponseTimeout = 0
bool _npcInitiative = false
int _npcEventId = 0 ; The NPC Event the conversation acts out. 0 for any other conversation
bool _npcEventPlayerNoticeable = false
bool _hasNpcEventMonitorValues = false ; Set once MantellaListenerScript has checked the scene
bool _sendQuestChecksCatchUp = false ; Set when the start reply brought a new quest check list: fresh answers go with the next continue request
bool _isGroupStart = false ; The next conversation may start with more than one NPC (Talk to my companions in the Conversation Wheel)
bool _isShouting = false ; Shout (Conversation Wheel): anyone nearby can answer or join in. See MantellaShout
Actor[] _shoutNearby ; Who was last found nearby
int[] _shoutNearbyRefids ; Start with a 0 and an empty name, so they are never empty and "nobody nearby" still reaches the server
string[] _shoutNearbyNames
string _shoutNearbyShown = "" ; The names last shown with Show Messages
Form[] _shoutSentActors ; The people nearby whose full actor settings were sent, so the server has their bios and memories
int[] _shoutSentHandles ; Their actor settings, in the same order. Someone who then joins uses them instead of being built again
bool _isShoutNearbyByShoutRules = false ; _shoutNearby was found with the Shout Mode page's rules, so a Nearby or Random Event can use it instead of scanning
int[] _shoutAddFailedRefids ; Who of the people picked could not be added. Sent with the next request
string[] _shoutAddFailedReasons ; Why, in the same order
bool _isRoomStart = false ; The next conversation starts with only the player, who says something to the room (Just saying something)
string _roomLine = "" ; What the player typed to say to the room. Sent as soon as the conversation is ready. Empty with a microphone
bool _isRoomFirstTurn = false ; The room conversation is waiting for the player's first line, which the player already asked to say
Actor[] _roomNearby ; Who MantellaShout.SayToRoom found nearby, so the start doesn't scan again
int _roomScanId = 0 ; Counts the room scans asked for. Cancelling the text box, or a newer scan, changes it, so the older scan stops and its result is unused
int _roomScanStartedId = 0 ; The last room scan that began running
int _roomScanDoneId = 0 ; The last room scan that finished
Actor[] _roomScanNearby ; What the last finished room scan found
int _roomMicScanId = 0 ; Saying something to the room with the microphone: the scan finding who is nearby while the player speaks. 0 for none
Form[] _prebuiltActors ; People nearby whose full actor settings the room scan built while the player typed, or the NPC Event check built
int[] _prebuiltHandles ; Their actor settings, used by the start instead of building them again
Actor[] _npcEventNearby ; Who the NPC Event check found nearby, so the start doesn't scan again
bool _isRoomConversation = false ; Started by saying something to the room, until the first Private. Everyone in it joined by shouting, so that Private sends nobody away
bool _isGameMasterMode = false ; From MantellaSoftware's replies. Conversation, Nearby and Random Events need it
string _pendingEventKind = "" ; A Conversation, Nearby or Random Event picked on the wheel, until its result arrives. "" for none
string _pendingEventHint = ""
bool _isEventHintDone = false ; The hint was typed or cancelled, or not asked for
bool _isEventTurn = false ; It is the player's turn, so the event can be sent
bool _isEventSent = false
Actor[] _eventNearby ; Nearby and Random: who the event can be about, nearest first
Form[] _eventSentActors ; The people nearby sent in full with the event
int[] _eventSentHandles ; Their actor settings, in the same order
int _eventBuildId = 0 ; Counts the event builds asked for (StartEventBuild). The event ending changes it, so its build stops and the result is unused
int _eventBuildStartedId = 0 ; The last event build that began running
int _eventBuildDoneId = 0 ; The last event build whose people for the event itself are built
int _eventBuildAllDoneId = 0 ; The last event build whose people for Shout are built too
int _eventScanId = 0 ; Counts the searches started when the wheel opens (StartEventScan). A newer one changes it, so an older one's result is unused
int _eventScanSentId = 0 ; The last search asked for. A newer _eventScanId was never asked for, so there is nothing to wait for
int _eventScanStartedId = 0 ; The last search that began running
int _eventScanDoneId = 0 ; The last search that finished
Actor[] _eventScanNearby ; What the last finished search found: the people nearby, nearest first
bool _eventScanHasFollowers = false ; Whether that search included the active followers
float _eventScanTime = 0.0 ; When it finished, in real time
Form[] _eventPrebuiltActors ; People the pending event is about, built while the NPCs finished their line and the player typed the hint
int[] _eventPrebuiltHandles ; Their actor settings, in the same order
Form[] _shoutJoiners ; Who joined by shouting and is still in the conversation. Kept when Shout is switched off
string _confirmPrivateText = "" ; The text for the message box of ConfirmPrivate while it is open. "" otherwise
bool _holdForEventText = false ; An NPC Event's text is shown while its conversation starts: nobody speaks until the box is closed
; The player's turn before the start: with Automatic Greeting off the player speaks first, so they can type or speak while the game
; gathers the details for the start. What they said goes out once MantellaSoftware has the conversation (EndEarlyTurn)
bool _isEarlyTurnPending = false ; This start can give the early turn, once MantellaSoftware's reply to the first request says the player speaks first
bool _isEarlyTurn = false ; The early turn is on. Ends with the first reply after the start
string _earlyLine = "" ; Typed during the early turn
bool _isEarlyListening = false ; The microphone started listening during the early turn
Actor[] _startActors ; Who the conversation starts with, so the microphone hears their names from the first line

; Never assigned, so always None: arrays are cleared with these. Assigning None to an array fails in the game ("Cannot cast from None to
; Actor[]"), and a local array declared "= None" then can't take an array at all, so it stays None
Actor[] _noActors
Form[] _noForms
int[] _noInts
string[] _noStrings

event OnInit()
    RegisterForConversationEvents()
EndEvent

; Also called by MantellaListenerScript on every save load: a quest script never gets OnPlayerLoadGame. Without it, a save where this
; script stopped getting MantellaSoftware's replies could never end its conversation, so it could never start a new one either
Function RegisterForConversationEvents()
    RegisterForModEvent("SKSE_HTTP_OnHttpReplyReceived","OnHttpReplyReceived")
    RegisterForModEvent("SKSE_HTTP_OnHttpErrorReceived","OnHttpErrorReceived")
    RegisterForModEvent(EventInterface.EVENT_ACTIONS_PREFIX + mConsts.ACTION_RELOADCONVERSATION,"OnReloadConversationActionReceived")
    RegisterForModEvent(EventInterface.EVENT_ACTIONS_PREFIX + mConsts.ACTION_ENDCONVERSATION,"OnEndConversationActionReceived")
    RegisterForModEvent(EventInterface.EVENT_ACTIONS_PREFIX + mConsts.ACTION_REMOVECHARACTER,"OnRemoveCharacterActionReceived")
    RegisterForModEvent(EventInterface.EVENT_ADD_EVENT,"OnAddEventReceived")
    RegisterForModEvent(EventInterface.EVENT_ACTION_RESPONSE_COMPLETED,"OnActionResponseCompleted")
    RegisterForModEvent(ROOM_SCAN_EVENT(),"OnRoomScan")
    RegisterForModEvent(EVENT_BUILD_EVENT(),"OnEventBuild")
    RegisterForModEvent(EVENT_SCAN_EVENT(),"OnEventScan")
EndFunction

string Function ROOM_SCAN_EVENT() global
    return "Mantella_RoomScan"
EndFunction

string Function EVENT_BUILD_EVENT() global
    return "Mantella_EventBuild"
EndFunction

string Function EVENT_SCAN_EVENT() global
    return "Mantella_EventScan"
EndFunction

event OnUpdate()
    If (_repeatingMessage != "")
        Debug.Notification(_repeatingMessage)
        RegisterForSingleUpdate(10)
    EndIf
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Start new conversation   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The next conversation is started by the NPC walking up to the player (NPC Initiative)
Function SetNpcInitiative()
    _npcInitiative = true
EndFunction

; The next conversation may start with more than one NPC
Function SetGroupStart()
    _isGroupStart = true
EndFunction

; The next conversation starts with only the player, who says something to the room. Someone nearby may answer, or nobody does.
; line is what the player typed, or empty when they speak with the microphone. nearby is who can hear it (MantellaShout.FindNearby)
Function SetRoomStart(string line, Actor[] nearby)
    _isRoomStart = true
    _roomLine = line
    _roomNearby = nearby
EndFunction

bool _isSayingToRoom = false ; MantellaShout.SayToRoom is getting ready: the text box, or finding who is nearby

; False if a Say to the room is already getting ready. Checked and set in one step, so two presses can't both go ahead
bool Function BeginSayToRoom()
    if _isSayingToRoom
        return false
    endIf
    _isSayingToRoom = true
    return true
EndFunction

Function EndSayToRoom()
    _isSayingToRoom = false
EndFunction

; The next conversation acts out an NPC Event (see MantellaListenerScript). The id is sent with the start request
Function SetNpcEvent(int eventId)
    _npcEventId = eventId
EndFunction

; What the NPC Event check found and built moments ago: who is nearby, nearest first, and the actor settings of the nearest.
; The start uses them instead of scanning and building again, which took long in a crowded place
Function SetNpcEventScan(Actor[] nearby, Form[] builtActors, int[] builtHandles)
    _npcEventNearby = nearby
    _prebuiltActors = builtActors
    _prebuiltHandles = builtHandles
EndFunction

bool Function IsNpcEvent()
    return _npcEventId != 0
EndFunction

; The end was requested and the conversation is waiting for MantellaSoftware to save it
bool Function IsEnding()
    return _hasBeenStopped
EndFunction

; It is the player's turn: the game waits for the text box or the push-to-talk key. Used by the in-game test (MantellaEventTest).
; Not the early turn: the conversation hasn't started yet
bool Function IsPlayersTurn()
    return _does_accept_player_input && !_isEarlyTurn
EndFunction

; Says the line as if the player typed it in the text box. Only during the player's turn. Used by the in-game test of the talk settings (MantellaTalkTest)
Function SayAsPlayer(string line)
    if !_does_accept_player_input || line == ""
        return
    endIf
    _does_accept_player_input = False ; As the text box does after Enter
    ClearRepeatingMessage()
    SendTypedLine(line)
EndFunction

; What the player typed. During the early turn it waits until MantellaSoftware has the conversation (EndEarlyTurn)
Function SendTypedLine(string line)
    if _isEarlyTurn
        _earlyLine = line
    else
        sendRequestForPlayerInput(line, updateContext=True)
    endIf
EndFunction

; How many NPC lines have arrived from MantellaSoftware. Used by the in-game test (MantellaEventTest) to pick an event while one is spoken
int _npcLinesReceived = 0
int Function NpcLinesReceived()
    return _npcLinesReceived
EndFunction

; The people the last Nearby or Random Event that happened sent in full, nearest first. Used by the in-game test (MantellaEventTest)
Form[] _lastEventSentActors
Form[] Function LastEventSentActors()
    return _lastEventSentActors
EndFunction

; A Conversation, Nearby or Random Event was picked and its result has not arrived yet
bool Function IsEventPending()
    return _pendingEventKind != ""
EndFunction

; Sent with every continue request of an NPC Event: whether the player can be noticed. Who is nearby goes with the Shout values,
; as the scene runs in Shout from the start
Function SetNpcEventMonitorValues(bool playerNoticeable)
    _npcEventPlayerNoticeable = playerNoticeable
    _hasNpcEventMonitorValues = true
EndFunction

; The server picked the player watching the scene. They join before anyone speaks again. People nearby join by Shout (AddShoutActor)
Function AddNpcEventActor(Actor actorToAdd)
    Actor[] actors = new Actor[1]
    actors[0] = actorToAdd
    AddActors(actors)
    RequestContinueConversation()
EndFunction

function StartConversation(Actor[] actorsToStartConversationWith)
    _startNumber += 1
    int thisStart = _startNumber
    ; Cleared right away, so an early return can't leave it set for the next conversation
    bool isNpcInitiative = _npcInitiative
    _npcInitiative = false
    bool isGroupStart = _isGroupStart
    _isGroupStart = false
    bool isRoomStart = _isRoomStart
    _isRoomStart = false
    string roomLine = _roomLine
    _roomLine = ""
    Actor[] roomNearby = _roomNearby
    _roomNearby = _noActors
    Actor[] npcEventNearby = _npcEventNearby
    _npcEventNearby = _noActors
    _isRoomFirstTurn = false
    if !isRoomStart && !IsNpcEvent()
        ClearPrebuiltActors() ; Only a room start and an NPC Event use them
    endIf
    _hasNpcEventMonitorValues = false
    _sendQuestChecksCatchUp = false
    ClearShout()
    _isEarlyTurn = false
    _earlyLine = ""
    _isEarlyListening = false
    _startActors = actorsToStartConversationWith
    ; Not when an NPC speaks first (NPC Initiative, NPC Events), or the player already said their line (saying something to the room)
    _isEarlyTurnPending = !isNpcInitiative && !IsNpcEvent() && !isRoomStart && actorsToStartConversationWith.Length >= 2 && ContainsActor(actorsToStartConversationWith, PlayerRef)
    _actorHandleActors = _noForms ; Everyone is built fresh, or taken from _prebuiltActors
    _staleActors = _noForms
    if(actorsToStartConversationWith.Length > 2 && !IsNpcEvent() && !isGroupStart) ; An NPC Event or a group start can start with more people
        Debug.Notification("Cannot start conversation. Conversation is already running.")
        return
    endIf

    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_INIT)
    ; send request to initialize Mantella settings (set LLM connection, start up TTS service, load character_df etc) 
    ; while waiting for actor info and context to be prepared below
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    
    AddActors(actorsToStartConversationWith)

    if(actorsToStartConversationWith.Length < 2 && !isRoomStart) ; Saying something to the room starts with only the player
        Debug.Notification("Not enough characters to start a conversation.")
        _npcEventId = 0
        return
    endIf

    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_STARTCONVERSATION)
    SKSE_HTTP.setString(handle, mConsts.KEY_STARTCONVERSATION_WORLDID, PlayerRef.GetDisplayName() + repository.worldID)
    if (isNpcInitiative)
        SKSE_HTTP.setBool(handle, mConsts.KEY_STARTCONVERSATION_NPCINITIATIVE, true)
    endIf
    if (IsNpcEvent())
        SKSE_HTTP.setInt(handle, mConsts.KEY_NPCEVENT_ID, _npcEventId)
    endIf
    BuildContext(true)
    AddCurrentActorsAndContext(handle, true)
    if isRoomStart
        ; Starts already shouting, so MantellaSoftware starts it as a Shout conversation and its Game Master decides whether anyone answers
        _isShouting = true
        _shoutSentActors = Utility.CreateFormArray(0)
        _shoutSentHandles = Utility.CreateIntArray(0)
        SetShoutNearby(roomNearby) ; Found just before by MantellaShout.SayToRoom. Scanning again would delay the start
        AddShoutValues(handle) ; Uses the actor settings the room scan built while the player typed
        _roomLine = roomLine
        _isRoomFirstTurn = true
        _isRoomConversation = true
        ClearPrebuiltActors() ; Built while the player typed. Later requests build them fresh
        if !roomNearby || roomNearby.Length == 0
            _roomMicScanId = StartRoomScan() ; Microphone: nobody was looked for yet. Found while the player speaks (UseRoomMicScan)
        endIf
    elseIf IsNpcEvent()
        ; An NPC Event runs in Shout from the start, so its Game Master can draw in anyone nearby. While the player watches,
        ; MantellaShout finds them with the NPC Event's rules. Sent with the start, so people who join heard the whole scene
        _isShouting = true
        _shoutSentActors = Utility.CreateFormArray(0)
        _shoutSentHandles = Utility.CreateIntArray(0)
        if npcEventNearby
            SetShoutNearby(NotInConversation(npcEventNearby)) ; Found by the NPC Event check moments ago. Scanning again would delay the start
        else
            RefreshShoutNearby()
        endIf
        AddShoutValues(handle) ; Uses the actor settings the check built
        ClearPrebuiltActors() ; Later requests build them fresh
    endIf

    if repository.microphoneEnabled
        if repository.useHotkeyToStartMic
            SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_PTT)
        else
            SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_MIC)
        endIf
    Else
        SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_TEXT)
    endIf
    microphoneEnabledLastKnownStatus = repository.microphoneEnabled

    if thisStart != _startNumber
        Debug.Trace("Mantella: a conversation start was ended, or its save loaded, while it was built. Not sent")
        return
    endIf
    AddHeardLines(handle)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    ; string address = "http://localhost:" + mConsts.HTTP_PORT + "/" + mConsts.HTTP_ROUTE_MAIN
    ; Debug.Notification("Sent StartConversation http request to " + address)
    int eventHandle = ModEvent.Create(EventInterface.EVENT_CONVERSATION_STARTED)
    if (eventHandle)        
        ModEvent.Send(eventHandle)
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Continue conversation    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function AddActorsToConversation(Actor[] actorsToAdd)
    AddActors(actorsToAdd)    
EndFunction

Function RemoveActorsFromConversation(Actor[] actorsToRemove)
    RemoveActors(actorsToRemove)  
EndFunction

Function SetIsTalking(bool isTalking)
    _isTalking = isTalking
EndFunction

bool Function GetIsTalking()
    return _isTalking
EndFunction

int Function GetNextTopicID()
    If (_lastTopicInfo == 0 || _lastTopicInfo == 2)
        return 1
    Else
        return 2
    EndIf
EndFunction

Topic Function GetTopicToUse(int transmittedID)
    If (transmittedID == 2)
        return MantellaDialogueLine2
    Else
        return MantellaDialogueLine1
    EndIf
EndFunction

event OnHttpReplyReceived(int typedDictionaryHandle)
    ; httpReceivedTime = Utility.GetCurrentRealTime()
    ; NOTE: When testing run times, remember to factor in the time it takes to trace a message (noted below) and subtract this number to get the "true" operation run time
    ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to trace a message", 2)
    string replyType = SKSE_HTTP.getString(typedDictionaryHandle, mConsts.KEY_REPLYTYPE ,"error")
    ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to determine reply type", 2)
    IF replyType == mConsts.KEY_REPLYTTYPE_INITCOMPLETED
        if _isEarlyTurnPending
            _isEarlyTurnPending = false
            int thisStart = _startNumber
            if SKSE_HTTP.getBool(typedDictionaryHandle, mConsts.KEY_PLAYERSPEAKSFIRST, false) && thisStart == _startNumber ; Not ended meanwhile
                _isEarlyTurn = true
                GivePlayerTheTurn()
            endIf
        endIf
    ElseIf replyType == mConsts.KEY_REPLYTYPE_INTERRUPTRECEIVED || replyType == mConsts.KEY_REPLYTYPE_LISTENINGBEFORESTART
        None
    ElseIf replyType == mConsts.KEY_REPLYTYPE_SHOWRECEIVED
        ; Shown once the picture is taken, so the note isn't in it
        If SKSE_HTTP.getBool(typedDictionaryHandle, mConsts.KEY_SHOW_TAKEN, false)
            Debug.Notification("You show them what you see")
        ElseIf IsRunning()
            Debug.Notification("Mantella couldn't take a picture of the game")
        EndIf
    ElseIf (replyType != "error")
        ContinueConversation(replyType, typedDictionaryHandle)        
    Else
        If (!IsRunning())
            return ; Not about a conversation, e.g. a failed NPC Initiative check
        EndIf
        string errorMessage = SKSE_HTTP.getString(typedDictionaryHandle, "mantella_message","Error: Received an error reply from MantellaSoftware but there was no error message attached.")
        Debug.Notification(errorMessage)
        CleanupConversation()
    EndIf
endEvent

function ContinueConversation(string nextAction, int handle)
    ; Debug.Notification(nextAction)
    if _isShouting && SKSE_HTTP.getBool(handle, mConsts.KEY_SHOUT_UNAVAILABLE, false)
        ClearShout()
        Debug.Notification("Shout needs the Game Master model. Set it up in Mantella's settings")
    endIf
    if SKSE_HTTP.hasKey(handle, mConsts.KEY_GAMEMASTERMODE) ; In the start, continue and event replies. It can change mid-conversation
        _isGameMasterMode = SKSE_HTTP.getBool(handle, mConsts.KEY_GAMEMASTERMODE, false)
    endIf
    if _isEarlyTurn && nextAction != mConsts.KEY_REPLYTTYPE_STARTCONVERSATIONCOMPLETED && nextAction != mConsts.KEY_REPLYTYPE_PLAYERTALK
        EndEarlyTurn(false) ; An NPC speaks first after all
    endIf
    if(nextAction == mConsts.KEY_REPLYTTYPE_STARTCONVERSATIONCOMPLETED)
        _hasBeenStopped = false
        _isEarlyTurnPending = false ; A late reply to the first request doesn't give the turn now
        if(SKSE_HTTP.hasKey(handle,mConsts.KEY_STARTCONVERSATION_USENARRATOR))
            _useNarrator = SKSE_HTTP.getBool(handle, mConsts.KEY_STARTCONVERSATION_USENARRATOR, false)
        endif
        if(SKSE_HTTP.hasKey(handle, mConsts.KEY_QUESTCHECKS_LIST))
            ; The quest check list was out of date, so the answers sent with the start were unusable
            if repository.SetQuestCheckList(SKSE_HTTP.getNestedDictionary(handle, mConsts.KEY_QUESTCHECKS_LIST), mConsts)
                _sendQuestChecksCatchUp = true
                _actorsUpdated = true ; So MantellaSoftware can update what the NPCs know
            endIf
        endif
        ;Debug.Notification("Conversation started.")
        ; An NPC Event's text is still being read. MantellaSoftware writes and voices the first line meanwhile, so it is ready once the box is closed
        while _holdForEventText
            Utility.WaitMenuMode(0.1)
        endWhile
        RequestContinueConversation()
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_NPCTALK)
        _npcLinesReceived += 1
        ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to realise NPC needs to respond", 2)
        int npcTalkHandle = SKSE_HTTP.getNestedDictionary(handle, mConsts.KEY_REPLYTYPE_NPCTALK)
        ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to get NPC talk handle", 2)
        ProcessNpcSpeak(npcTalkHandle)
        RequestContinueConversation()
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_PLAYERTALK)
        If (_isEarlyTurn)
            EndEarlyTurn(true)
        ElseIf (_pendingEventKind != "")
            ; An event was picked: it is sent now, in the player's turn, instead of listening to the player
            _isEventTurn = true
            TrySendPendingEvent()
        Else
            GivePlayerTheTurn()
        EndIf
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_CONVERSATIONEVENT)
        OnConversationEventResult(handle)
    elseIf (nextAction == mConsts.KEY_REQUESTTYPE_TTS)
        ClearRepeatingMessage()
        string transcribe = SKSE_HTTP.getString(handle, mConsts.KEY_TRANSCRIBE, "*Complete gibberish*")
        sendRequestForPlayerInput(transcribe, updateContext=True)
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_NPCACTION)
        int npcActionHandle = SKSE_HTTP.getNestedDictionary(handle, mConsts.KEY_REPLYTYPE_NPCACTION)
        bool updateInGameEvents = SKSE_HTTP.getBool(npcActionHandle, mConsts.ACTION_REQUIRES_RESPONSE, false)
        if updateInGameEvents
            _waitingForActionResponse = true ; Before the actions go out: their answer can come back before RequestContinueConversation waits
        endIf
        ProcessNpcAction(npcActionHandle)
        RequestContinueConversation(updateInGameEvents=updateInGameEvents)
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_SHOUT_ADDACTOR)
        AddShoutActors(SKSE_HTTP.getIntArray(handle, mConsts.KEY_SHOUT_ADDACTOR_REFIDS))
    elseIf(nextAction == mConsts.KEY_REPLYTYPE_ENDCONVERSATION)
        if !IsRunning()
            return ; Already ended in the game, e.g. by loading a save (EndAfterSaveLoad)
        endIf
        if !_hasBeenStopped && Participants.GetSize() < 2 && IsPlayerInConversation()
            Debug.Notification("Nobody answers") ; The player said something to the room. Not when the player ended it
        endIf
        CleanupConversation()
    endIf
endFunction

; The player's turn: what they typed to say to the room is sent, the microphone starts listening, or the game waits for the text box
Function GivePlayerTheTurn()
    _does_accept_player_input = True
    If (_isRoomFirstTurn)
        ; The player asked to say something to the room: what they typed is sent now, or the microphone starts listening
        _isRoomFirstTurn = false
        string line = _roomLine
        _roomLine = ""
        If (line != "")
            _does_accept_player_input = False
            sendRequestForPlayerInput(line, updateContext=True)
        Else
            sendRequestForVoiceTranscribe()
        EndIf
    ElseIf (repository.microphoneEnabled && !repository.useHotkeyToStartMic)
        sendRequestForVoiceTranscribe()
    Else
        ShowRepeatingMessage("Awaiting player input...")
    EndIf
EndFunction

; The first reply after the start ends the early turn. With the player's turn, what the player typed meanwhile is sent now, and a
; microphone already listening gets the request for what was said. Otherwise the turn is taken back
Function EndEarlyTurn(bool isPlayersTurn)
    _isEarlyTurn = false
    string line = _earlyLine
    _earlyLine = ""
    bool wasListening = _isEarlyListening
    _isEarlyListening = false
    If (!isPlayersTurn)
        _does_accept_player_input = false
        ClearRepeatingMessage()
        If (line != "")
            Debug.Notification("Your line wasn't sent")
        EndIf
    ElseIf (line != "")
        sendRequestForPlayerInput(line, updateContext=True)
    ElseIf (wasListening)
        _does_accept_player_input = True
        sendRequestForVoiceTranscribe()
    EndIf
    ; Otherwise the player still has the turn: the text box or the push-to-talk key works as usual from now on
EndFunction

function RequestContinueConversation(bool updateInGameEvents = false)
    if(!_hasBeenStopped)    
        int handle = SKSE_HTTP.createDictionary()
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_CONTINUECONVERSATION)

        ; _lastTopicInfo is only updated once a voiceline actually plays (see ProcessNpcSpeak)
        ; If this request does not result in a voiceline (eg the reply is "playertalk"),
        ; the same topic ID is re-sent on the next request instead of being skipped,
        ; keeping the alternation in sync with what was last heard in-game
        SKSE_HTTP.setInt(handle, mConsts.KEY_CONTINUECONVERSATION_TOPICINFOFILE, GetNextTopicID())

        if(_extraRequestActions && _extraRequestActions.Length > 0)
            ;Debug.Notification("_extraRequestActions contains items. Sending them along with continue!")
            SKSE_HTTP.setStringArray(handle, mConsts.KEY_REQUEST_EXTRA_ACTIONS, _extraRequestActions)
            ClearExtraRequestAction()
            ;Debug.Notification("_extraRequestActions got cleared. Remaining items: " + _extraRequestActions.Length)
        endif

        if updateInGameEvents
            _contextHandle = SKSE_HTTP.createDictionary()

            ; Wait for action to complete with timeout
            _actionResponseTimeout = 0
            while _waitingForActionResponse && _actionResponseTimeout < 50
                Utility.Wait(0.1)
                _actionResponseTimeout += 1
            endWhile

            _waitingForActionResponse = true ; Reset for next action

            string[] past_events = deepcopy(_ingameEvents)
            SKSE_HTTP.setStringArray(_contextHandle, mConsts.KEY_CONTEXT_INGAMEEVENTS, past_events)
            ClearIngameEvent()
            SKSE_HTTP.setNestedDictionary(handle, mConsts.KEY_CONTEXT, _contextHandle)
        endIf

        if _sendQuestChecksCatchUp
            AddQuestCheckResults(handle)
            _sendQuestChecksCatchUp = false
        endIf

        if _actorsUpdated
            SKSE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_ACTORS, _actorHandles)
            _actorsUpdated = false
        endIf

        if IsNpcEvent() && _hasNpcEventMonitorValues
            SKSE_HTTP.setBool(handle, mConsts.KEY_NPCEVENT_PLAYERNOTICEABLE, _npcEventPlayerNoticeable)
        endIf

        AddShoutValues(handle)

        if repository.microphoneEnabled != microphoneEnabledLastKnownStatus
            if repository.microphoneEnabled
                if repository.useHotkeyToStartMic
                    SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_PTT)
                else
                    SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_MIC)
                endIf
            Else
                SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_TEXT)
            endIf
            microphoneEnabledLastKnownStatus = repository.microphoneEnabled
        endIf

        AddHeardLines(handle)
        SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    EndIf
endFunction

function ProcessNpcSpeak(int handle)
    string speakerName = SKSE_HTTP.getString(handle, mConsts.KEY_ACTOR_SPEAKER, "Error: No speaker transmitted for action 'NPC talk'")
    ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to get speaker name", 2)
    ;Debug.Notification("Transmitted speaker name: "+ speakerName)
    Actor speaker = None
    bool isNarration = False
    float lineDuration = 0
    if _useNarrator
        isNarration = SKSE_HTTP.getBool(handle, mConsts.KEY_ACTOR_ISNARRATION, false)
    endIf
    if isNarration
        speaker = Narrator.GetReference() as Actor
        speakerName = "MantellaNarrator"
        lineDuration = SKSE_HTTP.getFloat(handle, mConsts.KEY_ACTOR_DURATION, 0)
        ;Debug.Notification("Using Narrator.")
    ; If actor is already loaded, do not load again from actors list
    elseif speakerName == _lastSpeakerName
        speaker = _lastNpcToSpeak
    else
        speaker = GetActorInConversation(speakerName)
    endIf
    
    ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " to get actor based on speaker name", 2)
    ;Debug.Notification("Chosen Actor: "+ speaker.GetDisplayName())

    if speaker != none
        WaitForNpcToFinishSpeaking(speaker, _lastNpcToSpeak)
        ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to wait for last NPC to finish speaking", 2)
        string lineToSpeak = SKSE_HTTP.getString(handle, mConsts.KEY_ACTOR_LINETOSPEAK, lineToSpeakError)
        ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to prepare response data", 2)
        int topicID = SKSE_HTTP.getInt(handle, mConsts.KEY_CONTINUECONVERSATION_TOPICINFOFILE, 1)

        if lineToSpeak != lineToSpeakError
            Topic topicToUse = GetTopicToUse(topicID)
            bool isPlayer = speaker == PlayerRef
            if isPlayer
                VoiceType orgRaceDefaultVoice = SKSE_HTTP.GetRaceDefaultVoiceType(speaker)
                SKSE_HTTP.SetRaceDefaultVoiceType(speaker,MantellaVoice00)

                NpcSpeak(speaker, lineToSpeak, topicToUse, false, lineDuration)
                SKSE_HTTP.SetRaceDefaultVoiceType(speaker,orgRaceDefaultVoice)
            else
                VoiceType orgVoice = SKSE_HTTP.GetVoiceType(speaker)
                ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to get orinal voice type", 2)
                SKSE_HTTP.SetVoiceType(speaker, MantellaVoice00)
                ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to set voice type", 2)

                NpcSpeak(speaker, lineToSpeak, topicToUse, isNarration, lineDuration)
                SKSE_HTTP.SetVoiceType(speaker, orgVoice)
            endif
            _lastNpcToSpeak = speaker
            _lastSpeakerName = speakerName
            ; Track the topic of the last voiceline actually played so that GetNextTopicID()
            ; always alternates relative to the last audible line
            ; Playing the same topic twice in a row can cause the engine to replay the
            ; previous (cached) voiceline instead of the newly written audio file
            _lastTopicInfo = topicID
        endIf
        ; Get actions only after the NPC starts speaking to improve response times. Not for a speaker who isn't in the conversation:
        ; RaiseActionEvent would give them to someone else
        int[] actionsHandles = SKSE_HTTP.getNestedDictionariesArray(handle, mConsts.KEY_ACTOR_ACTIONS)
        if actionsHandles && actionsHandles.Length > 0
            RaiseActionEvent(speaker, actionsHandles)
        endIf
    endIf
endFunction


function ProcessNpcAction(int handle)
    int[] actionsHandles = SKSE_HTTP.getNestedDictionariesArray(handle, mConsts.KEY_ACTOR_ACTIONS)
    if actionsHandles && actionsHandles.Length > 0
        ; Who acts, when given: the last NPC to speak may be someone else in a group. None falls back in RaiseActionEvent
        Actor speaker = GetActorInConversation(SKSE_HTTP.getString(handle, mConsts.KEY_ACTOR_SPEAKER, ""))
        RaiseActionEvent(speaker, actionsHandles)
    endIf
endFunction

function WaitForVoiceAssignment(Actor speaker, bool isPlayer)
    bool hasVoiceChanged = false
    float totalWaitTime = 0
    VoiceType currentVoice
    while hasVoiceChanged == false
        if isPlayer
            currentVoice = SKSE_HTTP.GetRaceDefaultVoiceType(speaker)
        else
            currentVoice = SKSE_HTTP.GetVoiceType(speaker)
        endIf

        if currentVoice == MantellaVoice00
            hasVoiceChanged = true
        elseIf totalWaitTime > 5
            Debug.Notification("Could not assign voiceline to NPC")
            hasVoiceChanged = true
        else
            Utility.Wait(0.01)
            totalWaitTime += 0.01
        endIf
    endWhile
endFunction

function NpcSpeak(Actor actorSpeaking, string lineToSay, Topic topicToUse, bool isSpokenByNarrator, float lineDuration)
    MantellaSubtitles.SetInjectTopicAndSubtitleForSpeaker(actorSpeaking, topicToUse, lineToSay)
    actorSpeaking.Say(topicToUse, abSpeakInPlayersHead=isSpokenByNarrator)
    ; Debug.Trace((Utility.GetCurrentRealTime() - httpReceivedTime) + " seconds to start speaking", 2)
    If (!isSpokenByNarrator)
        Actor NpcToLookAt = GetNpcToLookAt(actorSpeaking, _lastNpcToSpeak)
        actorSpeaking.SetLookAt(NpcToLookAt)
        NpcToLookAt.SetLookAt(actorSpeaking)
    Else
        ; Narrations do not have an actor to apply the IsTalking spell to, so a wait time needs to be forced here
        Utility.Wait(lineDuration)
    EndIf
    actorSpeaking.AddSpell(MantellaIsTalkingSpell, False)
endfunction

string function GetActorName(actor actorToGetName)
    string actorName = actorToGetName.GetDisplayName()
    int actorID = actorToGetName.GetFactionRank(MantellaConversationParticipantsFaction)
    if actorID > 0
        actorName = actorName + " " + actorID
    endIf
    return actorName
endFunction

Actor function GetActorInConversation(string actorName)
    int i = 0
    While i < Participants.GetSize()
        Actor currentActor = Participants.GetAt(i) as Actor
        if GetActorName(currentActor) == actorName
            return currentActor
        endIf
        i += 1
    EndWhile
    return none
endFunction

Actor function GetActorByName(string actorName)
    ; First, search conversation participants
    Actor currentActor = GetActorInConversation(actorName)
    if currentActor != None
        return currentActor
    endIf

    ; If not in conversation, search the most recent nearby actors cache
    if _cachedNearbyActors
        int i = 0
        While i < _cachedNearbyActors.Length
            Actor nearbyActor = _cachedNearbyActors[i]
            if nearbyActor != None
                ; Match by display name (nearby actors don't have numbered suffixes)
                if nearbyActor.GetDisplayName() == actorName
                    return nearbyActor
                endIf
            endIf
            i += 1
        EndWhile
    endIf

    ; Not found in conversation or nearby - return None
    return None
endFunction

Actor function GetFirstGuardActor()
    ; Check each NPC in the conversation to see if they are a guard, returning the first result
    int i = 0
    While i < Participants.GetSize()
        Actor currentActor = Participants.GetAt(i) as Actor
        if currentActor != None && currentActor.IsGuard()
            return currentActor
        endIf
        i += 1
    EndWhile
    return None
endFunction

Actor[] function GetCachedNearbyActors()
    ; Returns the most recent cached nearby actors (populated by BuildContext)
    return _cachedNearbyActors
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;            Shout            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Switched on and off from the Conversation Wheel. While the player shouts, the server's Game Master may pick someone nearby,
; who is added here and then speaks. See MantellaShout and docs/conversation_wheel.md in the Mantella repository

bool Function IsShouting()
    return _isShouting
EndFunction

; Saying something to the room: finds who is nearby, and builds the full actor settings of the nearest (Most People Described), on another
; thread, so it runs while the player types. Returns the scan's id, for FinishRoomScan or CancelRoomScan
int Function StartRoomScan()
    _roomScanId += 1
    RegisterForModEvent(ROOM_SCAN_EVENT(), "OnRoomScan") ; Again here, in case this save never ran RegisterForConversationEvents with it
    int eventHandle = ModEvent.Create(ROOM_SCAN_EVENT())
    if eventHandle
        ModEvent.PushInt(eventHandle, _roomScanId)
        ModEvent.Send(eventHandle)
    endIf
    return _roomScanId
EndFunction

; The text box was cancelled, or the line can't be said. The scan stops at its next step, and what it found is unused
Function CancelRoomScan(int scanId)
    if scanId == _roomScanId
        _roomScanId += 1
    endIf
EndFunction

; Waits for the scan to finish. GetRoomScanResult then has who it found, and StartConversation uses the actor settings it built.
; Returns false if a newer scan replaced it. If the scan never began (the event didn't arrive), it scans here instead
bool Function FinishRoomScan(int scanId)
    float waited = 0.0
    while _roomScanDoneId != scanId && scanId == _roomScanId && (_roomScanStartedId == scanId || waited < 2.0)
        Utility.WaitMenuMode(0.1) ; Also counts while a menu is still open
        waited += 0.1
    endWhile
    if scanId != _roomScanId
        return false
    endIf
    if _roomScanDoneId != scanId
        _roomScanDoneId = scanId ; So the scan doesn't run if it begins after all
        ClearPrebuiltActors()
        _roomScanNearby = MantellaShout.FindNearby(repository, self)
    endIf
    return true
EndFunction

Actor[] Function GetRoomScanResult()
    Actor[] nearby = _roomScanNearby
    _roomScanNearby = _noActors
    return nearby
EndFunction

Event OnRoomScan(int scanId)
    if scanId != _roomScanId || _roomScanDoneId == scanId
        return
    endIf
    _roomScanStartedId = scanId
    Actor[] nearby = MantellaShout.FindNearby(repository, self)
    int described = repository.shoutMaxCandidates
    if described > nearby.Length
        described = nearby.Length
    endIf
    if described < 0
        described = 0
    endIf
    Form[] built = Utility.CreateFormArray(described)
    int[] handles = Utility.CreateIntArray(described)
    int i = 0
    while i < described
        if scanId != _roomScanId
            return ; Cancelled while scanning
        endIf
        built[i] = nearby[i] as Form
        handles[i] = buildActorSetting(nearby[i])
        i += 1
    endWhile
    if scanId != _roomScanId || _roomScanDoneId == scanId ; Cancelled, or FinishRoomScan gave up waiting and scanned itself
        return
    endIf
    _prebuiltActors = built
    _prebuiltHandles = handles
    _roomScanNearby = nearby
    _roomScanDoneId = scanId
EndEvent

Function ClearPrebuiltActors()
    _prebuiltActors = _noForms
    _prebuiltHandles = _noInts
EndFunction

; On: anyone nearby can answer or join in. Off (Private): nobody new joins, and the people who joined by shouting leave, once the player says yes
; in a list menu. Everyone else stays: the people the conversation started with, and anyone the player brought in themselves. In a conversation
; started by saying something to the room, everyone joined by shouting, so the first Private keeps everyone and makes them the people the
; conversation is with: a later Shout and Private sends away only who joined after it. MantellaSoftware learns about it with the next request
Function SetShout(bool isOn)
    if isOn == _isShouting || !IsRunning()
        return
    endIf
    if _pendingEventKind != "" ; Its result can switch Shout on, which would undo Private
        Debug.Notification("Wait for the event first")
        return
    endIf
    if isOn
        _isShouting = true
        _shoutSentActors = Utility.CreateFormArray(0)
        _shoutSentHandles = Utility.CreateIntArray(0)
        RefreshShoutNearby()
        Debug.Notification("Shouting: anyone nearby can answer or join in")
        return
    endIf
    Actor[] leaving
    if !_isRoomConversation
        leaving = ShoutJoinersInConversation()
        if leaving && leaving.Length > 0
            if !ConfirmPrivate(leaving)
                return ; No: keeps shouting
            endIf
            ; The conversation went on while the menu was open: it may have ended, or someone may have joined or left
            if !IsRunning() || _hasBeenStopped || !_isShouting
                return
            endIf
            leaving = ShoutJoinersInConversation() ; Everyone who joined by shouting leaves, so only the people named as staying stay
        endIf
    else
        _isRoomConversation = false
        _shoutJoiners = _noForms ; Everyone here now counts as who the conversation is with
    endIf
    ClearShout()
    if leaving && leaving.Length > 0
        RemoveActors(leaving) ; Ends the conversation if nobody else is left
        if Participants.GetSize() >= 2
            Debug.Notification("Private: nobody new joins")
        endIf
    elseIf Participants.GetSize() < 2
        EndConversation() ; The player said something to the room and nobody has joined yet
    else
        Debug.Notification("Private: nobody new joins")
    endIf
EndFunction

; The people who joined by shouting and are still in the conversation. Not the people the conversation started with, nor anyone the player
; brought in themselves (Talk / Add, Companions, the spell)
Actor[] Function ShoutJoinersInConversation()
    int count = 0
    if _shoutJoiners
        count = _shoutJoiners.Length
    endIf
    Actor[] found = PapyrusUtil.ActorArray(count)
    int foundCount = 0
    int i = 0
    while i < count
        Actor npc = _shoutJoiners[i] as Actor
        if npc && Participants.HasForm(npc)
            found[foundCount] = npc
            foundCount += 1
        endIf
        i += 1
    endWhile
    Actor[] result = PapyrusUtil.ActorArray(foundCount)
    i = 0
    while i < foundCount
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

; Asks before the people who joined by shouting are sent away, in a message box with Yes and No buttons. The box is a record in Mantella.esp,
; whose text is fixed, so OnMenuOpen puts the text with the names in once the box is on the screen
bool Function ConfirmPrivate(Actor[] leaving)
    int count = Participants.GetSize()
    Actor[] staying = PapyrusUtil.ActorArray(count)
    int stayingCount = 0
    int i = 0
    while i < count
        Actor npc = Participants.GetAt(i) as Actor
        if npc && npc != PlayerRef && leaving.Find(npc) < 0
            staying[stayingCount] = npc
            stayingCount += 1
        endIf
        i += 1
    endWhile
    string text = "Go private?\n\nIf you do, " + NamesText(leaving, leaving.Length) + Verb(" leaves", " leave", leaving.Length) + " the conversation"
    if stayingCount > 0
        text += ", and only " + NamesText(staying, stayingCount) + Verb(" stays", " stay", stayingCount) + "."
    else
        text += ", and the conversation ends."
    endIf
    Message box = Game.GetFormFromFile(0x18B645, "Mantella.esp") as Message ; MantellaConfirmPrivateMessage
    if !box
        Debug.Notification("Mantella.esp is out of date: can't ask before going private")
        return false
    endIf
    _confirmPrivateText = text
    RegisterForMenu("MessageBoxMenu")
    int answer = box.Show() ; Waits for a button. 0 is Yes, 1 is No
    UnregisterForMenu("MessageBoxMenu")
    _confirmPrivateText = ""
    return answer == 0
EndFunction

; The message box of ConfirmPrivate is on the screen with its fixed text: shows the text with the names instead
Event OnMenuOpen(string menuName)
    if menuName == "MessageBoxMenu" && _confirmPrivateText != ""
        UI.InvokeString("MessageBoxMenu", "_root.MessageMenu.SetMessage", _confirmPrivateText)
    endIf
EndEvent

; Show What Happened on the Events page: what an event's generator wrote, in the same kind of message box as ConfirmPrivate, with an OK button.
; Waits until the player closes it. The game is paused meanwhile. kind is "npc", "conversation", "nearby" or "random"
Function ShowEventText(string kind, string text)
    string title = "Random Event"
    if kind == "npc"
        title = "NPC Event"
    elseIf kind == "conversation"
        title = "Conversation Event"
    elseIf kind == "nearby"
        title = "Nearby Event"
    endIf
    Debug.MessageBox(title + "\n\n" + text) ; Doesn't wait: the box opens a moment later
    float waited = 0.0
    while !UI.IsMenuOpen("MessageBoxMenu") && waited < 2.0
        Utility.WaitMenuMode(0.1)
        waited += 0.1
    endWhile
    while UI.IsMenuOpen("MessageBoxMenu")
        Utility.WaitMenuMode(0.1)
    endWhile
    _holdForEventText = false
EndFunction

; An NPC Event's text is about to be shown (ShowEventText) while its conversation starts. Called before the start request is sent, so the
; reply can't arrive first. Nobody speaks until the box is closed
Function HoldForEventText()
    _holdForEventText = true
EndFunction

; The names of the first count actors: "Hulda", "Hulda and Mikael", "Hulda, Mikael and Lydia"
string Function NamesText(Actor[] actors, int count)
    string names = ""
    int i = 0
    while i < count
        names = AddToNames(names, actors[i].GetDisplayName(), i == count - 1)
        i += 1
    endWhile
    return names
EndFunction

; singular for one person, plural for several. Both are passed in full: Papyrus treats strings that differ only in case as the same string,
; so a lone "s" literal comes out as "S" when some other script has an "S"
string Function Verb(string singular, string plural, int count)
    if count == 1
        return singular
    endIf
    return plural
EndFunction

string Function AddToNames(string names, string name, bool isLast)
    if names == ""
        return name
    elseIf isLast
        return names + " and " + name
    endIf
    return names + ", " + name
EndFunction

Function ClearShout()
    _isShouting = false
    _shoutNearby = _noActors
    _shoutNearbyRefids = _noInts
    _shoutNearbyNames = _noStrings
    _shoutNearbyShown = ""
    _shoutSentActors = _noForms
    _shoutSentHandles = _noInts
    _shoutAddFailedRefids = _noInts
    _shoutAddFailedReasons = _noStrings
    _isShoutNearbyByShoutRules = false
EndFunction

; Finds who is nearby now. Called when Shout is switched on and on every tick of MantellaListenerScript, so requests only attach the last list
Function RefreshShoutNearby()
    if !_isShouting || _roomMicScanId != 0 ; The room scan is already looking
        return
    endIf
    bool byShoutRules = !MantellaShout.IsWatchingNpcEvent(self) ; As FindNearby decides it
    SetShoutNearby(MantellaShout.FindNearby(repository, self))
    _isShoutNearbyByShoutRules = byShoutRules
EndFunction

; Keeps who is nearby, so requests attach it. Slow to work out: each check on a person in Papyrus waits for a frame
Function SetShoutNearby(Actor[] nearby)
    _isShoutNearbyByShoutRules = false ; Unless RefreshShoutNearby found it
    if !nearby
        nearby = PapyrusUtil.ActorArray(0)
    endIf
    int[] refids = Utility.CreateIntArray(nearby.Length + 1)
    string[] names = Utility.CreateStringArray(nearby.Length + 1)
    string shown = ""
    int i = 0
    while i < nearby.Length
        refids[i + 1] = (nearby[i] as Form).GetFormID()
        names[i + 1] = nearby[i].GetDisplayName()
        if i < 5 ; The rest are counted, so a crowded room still fits in a note
            if i > 0
                shown += ", "
            endIf
            shown += names[i + 1]
        endIf
        i += 1
    endWhile
    if nearby.Length > 5
        shown += " and " + (nearby.Length - 5) + " more"
    endIf
    _shoutNearby = nearby
    _shoutNearbyRefids = refids
    _shoutNearbyNames = names
    if repository.showShoutMessages && shown != _shoutNearbyShown
        if shown == ""
            Debug.Notification("Shout: nobody nearby")
        else
            Debug.Notification("Shout: nearby: " + shown)
        endIf
    endIf
    _shoutNearbyShown = shown
EndFunction

; Sent with every continue and player input request
Function AddShoutValues(int handle)
    SKSE_HTTP.setBool(handle, mConsts.KEY_SHOUT_ENABLED, _isShouting)
    if !_isShouting
        return
    endIf
    if !_shoutNearbyRefids
        RefreshShoutNearby()
    endIf
    ; Both taken before any call, so a refresh in between can't pair the names of one scan with the refids of another
    int[] refids = _shoutNearbyRefids
    string[] names = _shoutNearbyNames
    Actor[] nearby = _shoutNearby
    SKSE_HTTP.setIntArray(handle, mConsts.KEY_SHOUT_NEARBY_REFIDS, refids)
    SKSE_HTTP.setStringArray(handle, mConsts.KEY_SHOUT_NEARBY_NAMES, names)
    AddNewShoutActors(handle, nearby)
    AddShoutSettings(handle)
    if _shoutAddFailedRefids && _shoutAddFailedRefids.Length > 0
        SKSE_HTTP.setIntArray(handle, mConsts.KEY_SHOUT_ADDFAILED_REFIDS, _shoutAddFailedRefids)
        SKSE_HTTP.setStringArray(handle, mConsts.KEY_SHOUT_ADDFAILED_REASONS, _shoutAddFailedReasons)
        _shoutAddFailedRefids = _noInts
        _shoutAddFailedReasons = _noStrings
    endIf
EndFunction

; The Shout Mode page's settings Mantella needs. Also sent by a Nearby or Random Event while Shout is off, as MantellaSoftware switches it on with the event.
; Most People in Conversation, People Who Must Answer a Group Line and Newcomers Remember are Mantella's own settings (Conversation page)
Function AddShoutSettings(int handle)
    SKSE_HTTP.setInt(handle, mConsts.KEY_SHOUT_MAXDESCRIBED, repository.shoutMaxCandidates)
EndFunction

; The full actor settings of the nearest people (Most People Described) who were not sent yet. The server puts their bios and memories in the Game Master's prompt.
; The others nearby are only sent by name
Function AddNewShoutActors(int handle, Actor[] nearby)
    if !nearby
        return
    endIf
    int described = repository.shoutMaxCandidates
    if described > nearby.Length
        described = nearby.Length
    endIf
    if described <= 0
        return
    endIf
    if !_shoutSentActors
        _shoutSentActors = Utility.CreateFormArray(0)
        _shoutSentHandles = Utility.CreateIntArray(0)
    endIf
    int[] handles = Utility.CreateIntArray(described)
    int count = 0
    int i = 0
    while i < described
        Actor npc = nearby[i]
        if npc && _shoutSentActors.Find(npc) < 0
            int built = BuiltHandle(npc) ; Built by the room scan while the player typed, by the NPC Event check, or for the pending event
            if built == 0
                built = buildActorSetting(npc)
            endIf
            handles[count] = built
            count += 1
            AddShoutSent(npc, built)
        endIf
        i += 1
    endWhile
    if count > 0
        SKSE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_SHOUT_NEARBY_ACTORS, Utility.ResizeIntArray(handles, count))
    endIf
EndFunction

; Someone's full actor settings, already built during this conversation, or 0 if they weren't: by the room scan or the NPC Event check
; (_prebuiltActors), for the pending event (StartEventBuild), or sent by Shout or with an event. Building someone takes a moment
int Function BuiltHandle(Actor npc)
    int i = -1
    int handle = 0
    if _prebuiltActors
        i = _prebuiltActors.Find(npc)
        if i >= 0 && i < _prebuiltHandles.Length
            handle = HandleIfTheirs(npc, _prebuiltHandles[i])
        endIf
    endIf
    if handle == 0 && _eventPrebuiltActors
        i = _eventPrebuiltActors.Find(npc)
        if i >= 0 && i < _eventPrebuiltHandles.Length
            handle = HandleIfTheirs(npc, _eventPrebuiltHandles[i])
        endIf
    endIf
    if handle == 0 && _shoutSentActors
        i = _shoutSentActors.Find(npc)
        if i >= 0 && _shoutSentHandles && i < _shoutSentHandles.Length
            handle = HandleIfTheirs(npc, _shoutSentHandles[i])
        endIf
    endIf
    return handle
EndFunction

; The kept number, if it still holds npc's actor settings, otherwise 0, so they are built again. Once a kept number held something else (see
; AddShoutSent), so a request went out with that person as null or as someone else's settings, and MantellaSoftware failed it
int Function HandleIfTheirs(Actor npc, int handle)
    if handle != 0 && SKSE_HTTP.getInt(handle, mConsts.KEY_ACTOR_REFID, 0) == (npc as Form).GetFormID()
        return handle
    endIf
    return 0
EndFunction

; The server now has their bios and memories, so they are not sent in full again
Function AddShoutSent(Form npc, int handle)
    if !_shoutSentActors
        _shoutSentActors = Utility.CreateFormArray(0)
    endIf
    if !_shoutSentHandles || _shoutSentHandles.Length != _shoutSentActors.Length
        _shoutSentHandles = Utility.CreateIntArray(_shoutSentActors.Length) ; A 0 for anyone whose actor settings were not kept
    endIf
    _shoutSentActors = Utility.ResizeFormArray(_shoutSentActors, _shoutSentActors.Length + 1)
    _shoutSentActors[_shoutSentActors.Length - 1] = npc
    ; The place is worked out first: "_shoutSentHandles[_shoutSentHandles.Length - 1] = handle" compiles so the length overwrites the
    ; handle before it's stored (the Papyrus compiler reuses one temporary for both), so everyone kept got their place + 1 as their number
    int last = _shoutSentHandles.Length
    _shoutSentHandles = Utility.ResizeIntArray(_shoutSentHandles, last + 1)
    _shoutSentHandles[last] = handle
EndFunction

; Joins as someone the Game Master brought in by shouting: Private sends them away again. The next request carries them.
; Also used by the in-game test (MantellaEventTest), to bring in someone an event described
Function JoinByShouting(Actor npc)
    Actor[] actors = new Actor[1]
    actors[0] = npc
    AddActors(actors)
    if !_shoutJoiners
        _shoutJoiners = Utility.CreateFormArray(0)
    endIf
    _shoutJoiners = Utility.ResizeFormArray(_shoutJoiners, _shoutJoiners.Length + 1)
    _shoutJoiners[_shoutJoiners.Length - 1] = npc
EndFunction

; The server's Game Master picked the people nearby a line was spoken to. They all join in one step, before any of them speaks.
; Whoever no longer can is skipped, and the server is told with the next request
Function AddShoutActors(int[] refids)
    int total = 0
    if refids
        total = refids.Length
    endIf
    Actor[] found = PapyrusUtil.ActorArray(total)
    int[] failedRefids = Utility.CreateIntArray(total)
    string[] failedReasons = Utility.CreateStringArray(total)
    int joinCount = 0
    int failCount = 0
    int r = 0
    while r < total
        int refid = refids[r]
        Actor npc = None
        int i = 0
        while _shoutNearby && i < _shoutNearby.Length && !npc
            if (_shoutNearby[i] as Form).GetFormID() == refid
                npc = _shoutNearby[i]
            endIf
            i += 1
        endWhile
        string reason = ""
        if !_isShouting
            reason = "Shout is off"
        elseIf !npc
            reason = "no longer in the nearby list"
        else
            reason = MantellaShout.WhyCantJoin(npc, repository, self)
        endIf
        if reason == ""
            if found.Find(npc) < 0
                found[joinCount] = npc
                joinCount += 1
            endIf
            if repository.showShoutMessages
                Debug.Notification("Shout: " + npc.GetDisplayName() + " joins the conversation")
            endIf
        else
            failedRefids[failCount] = refid
            failedReasons[failCount] = reason
            failCount += 1
            if repository.showShoutMessages
                if npc
                    Debug.Notification("Shout: " + npc.GetDisplayName() + " can't join: " + reason)
                else
                    Debug.Notification("Shout: someone picked can't join: " + reason)
                endIf
            endIf
        endIf
        r += 1
    endWhile
    if joinCount > 0
        Actor[] joiners = PapyrusUtil.ActorArray(joinCount)
        int j = 0
        while j < joinCount
            joiners[j] = found[j]
            j += 1
        endWhile
        JoinAllByShouting(joiners)
    endIf
    if failCount > 0
        _shoutAddFailedRefids = Utility.ResizeIntArray(failedRefids, failCount)
        _shoutAddFailedReasons = Utility.ResizeStringArray(failedReasons, failCount)
    endIf
    RequestContinueConversation()
EndFunction

; Everyone joins in one step, as people the Game Master brought in by shouting: Private sends them away again. The next request carries them
Function JoinAllByShouting(Actor[] joiners)
    AddActors(joiners)
    if !_shoutJoiners
        _shoutJoiners = Utility.CreateFormArray(0)
    endIf
    int first = _shoutJoiners.Length
    _shoutJoiners = Utility.ResizeFormArray(_shoutJoiners, first + joiners.Length)
    int i = 0
    while i < joiners.Length
        _shoutJoiners[first + i] = joiners[i]
        i += 1
    endWhile
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Events            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Conversation, Nearby and Random Events, picked on the Conversation Wheel. The NPCs stop and, with that event's Ask for a Hint, a text box
; asks what should happen. In the player's turn, MantellaSoftware's event generator writes what happens, and its Game Master picks who
; reacts first, the player included. Nearby and Random switch Shout on. Set up on the Events page.
; See docs/conversation_wheel.md in the Mantella repository

; kind is "conversation", "nearby" or "random"
Function RequestConversationEvent(string kind)
    if _hasBeenStopped || !IsRunning() || _pendingEventKind != "" || !IsPlayerInConversation()
        return
    endIf
    if !_isGameMasterMode
        Debug.Notification("Events need Game Master Mode")
        return
    endIf
    repository.EnsureEventDefaults()
    Actor[] nearby
    if kind == "nearby"
        ; Found before the NPCs are stopped: with nobody nearby, nothing happens. Random always goes ahead, so it looks after stopping them
        nearby = FindEventNearby(kind)
        if !nearby || nearby.Length == 0
            Debug.Notification("Nobody is nearby")
            return
        endIf
        if _hasBeenStopped || _pendingEventKind != "" ; Finding who is nearby can take a moment
            return
        endIf
    endIf
    _pendingEventKind = kind
    _eventNearby = nearby
    _eventBuildId += 1 ; No build from an earlier event is used
    _eventPrebuiltActors = _noForms
    _eventPrebuiltHandles = _noInts
    _pendingEventHint = ""
    _isEventHintDone = false
    _isEventSent = false
    _isEventTurn = _does_accept_player_input ; Already the player's turn (text, or push-to-talk not pressed yet)
    _does_accept_player_input = false ; Talking and the text box are ignored until the event arrives
    ClearRepeatingMessage()
    if !_isEventTurn
        ; The NPCs are talking, or the microphone waits for the player to speak. Both stop, and the turn comes back to the player
        int handle = SKSE_HTTP.createDictionary()
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_INTERRUPT)
        SKSE_HTTP.setString(handle, mConsts.KEY_EVENT_KIND, kind)
        SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    endIf
    if kind == "random"
        nearby = FindEventNearby(kind)
        if _pendingEventKind != kind
            return ; Ended meanwhile
        endIf
        _eventNearby = nearby
    endIf
    if kind != "conversation"
        StartEventBuild() ; While the NPCs finish their line and the player types the hint
    endIf
    if EventAsksForHint(kind)
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        string hint = UIExtensions.GetMenuResultString("UITextEntryMenu") ; Cancelled or empty: a surprise
        if _pendingEventKind != kind
            return ; Ended meanwhile
        endIf
        _pendingEventHint = hint
    endIf
    _isEventHintDone = true
    Debug.Notification("An event is generating...")
    TrySendPendingEvent()
EndFunction

; Sent once the hint is done and it is the player's turn, whichever comes last
Function TrySendPendingEvent()
    if _pendingEventKind == "" || !_isEventHintDone || !_isEventTurn || _isEventSent || _hasBeenStopped
        return
    endIf
    _isEventSent = true
    string kind = _pendingEventKind
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_CONVERSATIONEVENT)
    SKSE_HTTP.setString(handle, mConsts.KEY_EVENT_KIND, kind)
    if _pendingEventHint != ""
        SKSE_HTTP.setString(handle, mConsts.KEY_EVENT_HINT, _pendingEventHint)
    endIf
    if kind != "conversation"
        ; Before Shout's values, as Shout may send some of the same people. While shouting, Shout's new people go with the event, so its
        ; Game Master knows them from the first pick. Otherwise they go with the first request after the event, and are built meanwhile
        FinishEventBuild(_isShouting)
        if _hasBeenStopped || _pendingEventKind != kind
            return ; Ended while waiting
        endIf
    endIf
    AddShoutValues(handle) ; Before the event's nearby list, so nobody Shout sends in full is sent twice
    if kind != "conversation"
        if !_isShouting
            AddShoutSettings(handle) ; MantellaSoftware switches Shout on with the event, with these settings
        endIf
        AddEventNearby(handle, kind)
    endIf
    ; The actors and the context, as with the player's input
    if repository.targetTrackingAngerState
        UpdateNpcsInConversationArray()
    endIf
    SKSE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_ACTORS, _actorHandles)
    BuildContext()
    SKSE_HTTP.setNestedDictionary(handle, mConsts.KEY_CONTEXT, _contextHandle)
    ; Gathering the above takes a moment. If the player ended the conversation meanwhile, MantellaSoftware was told to cancel the event
    ; before this request existed, so it would write the event anyway. Only AddHeardLines comes between this check and the send. It can
    ; wait for a moment, but goes after the check, so heard lines are never taken for a request that isn't sent
    if _hasBeenStopped || _pendingEventKind != kind
        return
    endIf
    AddHeardLines(handle)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
EndFunction

; Who the event can be about, nearest first, with the full actor settings of the nearest who are not in the conversation (Most People Described).
; Not of those Shout has already sent: MantellaSoftware keeps them. Most were built while the player typed the hint (StartEventBuild)
Function AddEventNearby(int handle, string kind)
    Actor[] nearby = _eventNearby
    int count = 0
    if nearby
        count = nearby.Length
    endIf
    int described = EventDescribedCount(kind, count)
    ; Start with a 0 and an empty name, so they are never empty
    int[] refids = Utility.CreateIntArray(count + 1)
    string[] names = Utility.CreateStringArray(count + 1)
    int[] handles = Utility.CreateIntArray(described + 1)
    Form[] sent = Utility.CreateFormArray(0)
    int i = 0
    while i < count
        Actor npc = nearby[i]
        refids[i + 1] = (npc as Form).GetFormID()
        names[i + 1] = GetActorName(npc)
        if i < described && NeedsEventActorSettings(npc)
            int built = BuiltHandle(npc)
            if built == 0
                built = buildActorSetting(npc)
            endIf
            handles[sent.Length] = built
            sent = Utility.ResizeFormArray(sent, sent.Length + 1)
            sent[sent.Length - 1] = npc
        endIf
        i += 1
    endWhile
    SKSE_HTTP.setIntArray(handle, mConsts.KEY_EVENT_NEARBY_REFIDS, refids)
    SKSE_HTTP.setStringArray(handle, mConsts.KEY_EVENT_NEARBY_NAMES, names)
    SKSE_HTTP.setInt(handle, mConsts.KEY_EVENT_MAXDESCRIBED, EventMaxDescribed(kind))
    if sent.Length > 0
        SKSE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_EVENT_NEARBY_ACTORS, Utility.ResizeIntArray(handles, sent.Length))
    endIf
    _eventSentActors = sent
    _eventSentHandles = Utility.ResizeIntArray(handles, sent.Length)
EndFunction

; How many of the nearest the event describes in full (Most People Described), out of count
int Function EventDescribedCount(string kind, int count)
    int described = EventMaxDescribed(kind)
    if described > count
        described = count
    endIf
    if described < 0
        described = 0
    endIf
    return described
EndFunction

; MantellaSoftware already has the people in the conversation, and those Shout sent
bool Function NeedsEventActorSettings(Actor npc)
    return npc && !Participants.HasForm(npc) && !(_isShouting && _shoutSentActors && _shoutSentActors.Find(npc) >= 0)
EndFunction

; Builds the full actor settings of the people the pending event will describe, on another thread, so it runs while the NPCs finish their
; line and the player types the hint. Building someone takes a moment: with Most People Described at 6, it held up the event for seconds
Function StartEventBuild()
    _eventBuildId += 1
    _eventPrebuiltActors = _noForms
    _eventPrebuiltHandles = _noInts
    RegisterForModEvent(EVENT_BUILD_EVENT(), "OnEventBuild") ; Again here, in case this save never ran RegisterForConversationEvents with it
    int eventHandle = ModEvent.Create(EVENT_BUILD_EVENT())
    if eventHandle
        ModEvent.PushInt(eventHandle, _eventBuildId)
        ModEvent.Send(eventHandle)
    endIf
EndFunction

; First the people the event describes, then the people Shout will describe (Shout's Most People Described), who are sent with the event
; when Shout is on, or with the first request after it when the event switches Shout on. The event's are ready first, so the event
; never waits for Shout's: those are built while the event is generated
Event OnEventBuild(int buildId)
    if buildId != _eventBuildId || _eventBuildDoneId == buildId || _eventBuildStartedId == buildId
        return
    endIf
    _eventBuildStartedId = buildId
    ; Worked out now: the event may end, and clear what it found, while this runs
    Actor[] forEvent = EventBuildList()
    Actor[] forShout = ShoutBuildList(forEvent)
    int total = forEvent.Length + forShout.Length
    Form[] built = Utility.CreateFormArray(total)
    int[] handles = Utility.CreateIntArray(total)
    int i = 0
    while i < total
        if buildId != _eventBuildId || _eventBuildAllDoneId == buildId
            return ; The event ended, a newer one replaced it, or FinishEventBuild gave up waiting
        endIf
        if i == forEvent.Length
            if _eventBuildDoneId == buildId ; FinishEventBuild gave up waiting
                return
            endIf
            ; Handles first: BuiltHandle reads the actors' place in the handles, so a reader in between finds nothing rather than a wrong one
            _eventPrebuiltHandles = Utility.ResizeIntArray(handles, i)
            _eventPrebuiltActors = Utility.ResizeFormArray(built, i)
            _eventBuildDoneId = buildId
        endIf
        Actor npc
        if i < forEvent.Length
            npc = forEvent[i]
        else
            npc = forShout[i - forEvent.Length]
        endIf
        built[i] = npc
        handles[i] = BuiltHandle(npc) ; Shout may have built them meanwhile
        if handles[i] == 0
            handles[i] = buildActorSetting(npc)
        endIf
        i += 1
    endWhile
    if buildId != _eventBuildId || _eventBuildAllDoneId == buildId
        return
    endIf
    _eventPrebuiltHandles = handles
    _eventPrebuiltActors = built
    _eventBuildDoneId = buildId
    _eventBuildAllDoneId = buildId
EndEvent

; The nearest the pending event describes in full (Most People Described) who MantellaSoftware doesn't have yet
Actor[] Function EventBuildList()
    Actor[] nearby = _eventNearby
    int count = 0
    if nearby
        count = nearby.Length
    endIf
    int described = EventDescribedCount(_pendingEventKind, count)
    Actor[] found = PapyrusUtil.ActorArray(described)
    int foundCount = 0
    int i = 0
    while i < described
        if NeedsEventActorSettings(nearby[i])
            found[foundCount] = nearby[i]
            foundCount += 1
        endIf
        i += 1
    endWhile
    return FirstActors(found, foundCount)
EndFunction

; The nearest Shout will describe in full that it hasn't sent yet, and the event doesn't build already (alreadyListed). AddNewShoutActors takes
; them from Shout's list: the list it has now when shouting, otherwise the one the event will give it (the people the event found who aren't
; in the conversation)
Actor[] Function ShoutBuildList(Actor[] alreadyListed)
    Actor[] shoutNearby
    if _isShouting
        shoutNearby = _shoutNearby
    else
        shoutNearby = NotInConversation(_eventNearby)
    endIf
    int count = 0
    if shoutNearby
        count = shoutNearby.Length
    endIf
    int described = repository.shoutMaxCandidates
    if described > count
        described = count
    endIf
    if described < 0
        described = 0
    endIf
    Actor[] found = PapyrusUtil.ActorArray(described)
    int foundCount = 0
    int i = 0
    while i < described
        Actor npc = shoutNearby[i]
        if npc && alreadyListed.Find(npc) < 0 && !(_isShouting && _shoutSentActors && _shoutSentActors.Find(npc) >= 0)
            found[foundCount] = npc
            foundCount += 1
        endIf
        i += 1
    endWhile
    return FirstActors(found, foundCount)
EndFunction

; The first count actors, as a new array
Actor[] Function FirstActors(Actor[] actors, int count)
    Actor[] result = PapyrusUtil.ActorArray(count)
    int i = 0
    while i < count
        result[i] = actors[i]
        i += 1
    endWhile
    return result
EndFunction

; Waits for the build: the event's people, or with all, Shout's too. If it never began (the mod event didn't arrive), or is still running
; after MAX_BUILD_WAIT (it should never take that long), it is given up: AddEventNearby and AddNewShoutActors build whoever is missing
Function FinishEventBuild(bool all)
    int buildId = _eventBuildId
    float waited = 0.0
    while _eventBuildDoneId != buildId && buildId == _eventBuildId && (_eventBuildStartedId == buildId || waited < 2.0) && waited < MAX_BUILD_WAIT()
        Utility.WaitMenuMode(0.1)
        waited += 0.1
    endWhile
    while all && _eventBuildDoneId == buildId && _eventBuildAllDoneId != buildId && buildId == _eventBuildId && waited < MAX_BUILD_WAIT()
        Utility.WaitMenuMode(0.1)
        waited += 0.1
    endWhile
    if buildId == _eventBuildId && (_eventBuildDoneId != buildId || (all && _eventBuildAllDoneId != buildId))
        ; Never began, or given up. Marked done, so the build stops at its next step and later waits don't wait for it
        _eventBuildDoneId = buildId
        _eventBuildAllDoneId = buildId
    endIf
EndFunction

; Seconds. The longest a background build or search is waited for. Building 12 people takes about 25 seconds
float Function MAX_BUILD_WAIT() global
    return 30.0
EndFunction

; The build is no longer needed: the event ended, and the first request after it has gone
Function StopEventBuild()
    _eventBuildId += 1 ; A build still running stops
    _eventPrebuiltActors = _noForms
    _eventPrebuiltHandles = _noInts
EndFunction

; Nearby and Random: who the event can be about, nearest first. Found with the Shout Mode page's Hearing Distance, Must Be in Sight and
; Most People Listed, and the event's own Include Followers. Random: the NPCs in the conversation too.
; While shouting, Shout's own list from the last tick is used instead of scanning, as it was found with the same settings
Actor[] Function FindEventNearby(string kind)
    bool includeFollowers = repository.nearbyEventIncludeFollowers
    if kind == "random"
        includeFollowers = repository.randomEventIncludeFollowers
    endIf
    Actor[] others
    if CanUseShoutList(includeFollowers)
        others = NotInConversation(_shoutNearby) ; Someone may have joined since
        if !repository.shoutExcludeFollowers && !includeFollowers
            others = WithoutFollowers(others)
        endIf
    elseIf TakeEventScan(includeFollowers)
        others = NotInConversation(_eventScanNearby)
        if _eventScanHasFollowers && !includeFollowers
            others = WithoutFollowers(others)
        endIf
    else
        others = MantellaShout.FindNearbyWith(repository, self, repository.shoutHearingDistance, includeFollowers, repository.shoutRequireLineOfSight, repository.shoutMaxListed)
    endIf
    if kind != "random"
        return others
    endIf
    int otherCount = 0
    if others
        otherCount = others.Length
    endIf
    int total = otherCount + Participants.GetSize()
    Actor[] found = PapyrusUtil.ActorArray(total)
    float[] distances = Utility.CreateFloatArray(total)
    int count = 0
    int i = 0
    while i < otherCount
        count = MantellaWheel.InsertByDistance(found, distances, count, total, others[i], PlayerRef.GetDistance(others[i]))
        i += 1
    endWhile
    i = 0
    while i < Participants.GetSize()
        Actor npc = Participants.GetAt(i) as Actor
        if npc && npc != PlayerRef
            count = MantellaWheel.InsertByDistance(found, distances, count, total, npc, PlayerRef.GetDistance(npc))
        endIf
        i += 1
    endWhile
    Actor[] result = PapyrusUtil.ActorArray(count)
    i = 0
    while i < count
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

; Shout's list from the last tick can stand in for a search: found with the Shout Mode page's rules, with the followers the event needs.
; _shoutNearbyRefids is set with every list, also one where nobody is nearby
bool Function CanUseShoutList(bool includeFollowers)
    return _isShouting && _isShoutNearbyByShoutRules && _shoutNearbyRefids && (includeFollowers || !repository.shoutExcludeFollowers)
EndFunction

; Opening the Conversation Wheel starts searching for who is nearby, on another thread, so a Nearby or Random Event picked on it doesn't
; wait for the search: it took a second or more, and a Nearby Event searches before the NPCs are told to stop. Not needed when Shout's own
; list can be used
Function StartEventScan()
    if _hasBeenStopped || !IsRunning() || !_isGameMasterMode || _pendingEventKind != "" || !IsPlayerInConversation()
        return
    endIf
    if CanUseShoutList(repository.nearbyEventIncludeFollowers) && CanUseShoutList(repository.randomEventIncludeFollowers)
        return
    endIf
    _eventScanId += 1
    RegisterForModEvent(EVENT_SCAN_EVENT(), "OnEventScan") ; Again here, in case this save never ran RegisterForConversationEvents with it
    int eventHandle = ModEvent.Create(EVENT_SCAN_EVENT())
    if eventHandle
        ModEvent.PushInt(eventHandle, _eventScanId)
        ModEvent.Send(eventHandle)
        _eventScanSentId = _eventScanId
    endIf
EndFunction

; With the followers if either event includes them: FindEventNearby leaves them out for an event that doesn't
Event OnEventScan(int scanId)
    if scanId != _eventScanId || _eventScanStartedId == scanId || _eventScanDoneId == scanId
        return
    endIf
    _eventScanStartedId = scanId
    bool includeFollowers = repository.nearbyEventIncludeFollowers || repository.randomEventIncludeFollowers
    Actor[] found = MantellaShout.FindNearbyWith(repository, self, repository.shoutHearingDistance, includeFollowers, repository.shoutRequireLineOfSight, repository.shoutMaxListed)
    if scanId != _eventScanId
        return
    endIf
    _eventScanNearby = found
    _eventScanHasFollowers = includeFollowers
    _eventScanTime = Utility.GetCurrentRealTime()
    _eventScanDoneId = scanId
EndEvent

; True if the search started when the wheel opened can be used: it found the followers the event needs, and is recent. Waits for it if
; it is still running. A search that never began, or still runs after MAX_BUILD_WAIT, is given up, and FindEventNearby searches itself
bool Function TakeEventScan(bool includeFollowers)
    int scanId = _eventScanId
    if scanId == 0 || (_eventScanDoneId != scanId && _eventScanSentId != scanId)
        return false ; None was asked for: the conversation ended since, the last one was given up, or the wheel didn't need one
    endIf
    float waited = 0.0
    while _eventScanDoneId != scanId && scanId == _eventScanId && (_eventScanStartedId == scanId || waited < 0.5) && waited < MAX_BUILD_WAIT()
        Utility.WaitMenuMode(0.1)
        waited += 0.1
    endWhile
    if _eventScanDoneId != scanId
        if scanId == _eventScanId
            _eventScanId += 1 ; So its result is unused if it begins or finishes after all
        endIf
        return false
    endIf
    return (_eventScanHasFollowers || !includeFollowers) && Utility.GetCurrentRealTime() - _eventScanTime <= 15.0
EndFunction

Function OnConversationEventResult(int handle)
    string kind = _pendingEventKind
    Actor[] nearby = _eventNearby
    Form[] sentActors = _eventSentActors
    int[] sentHandles = _eventSentHandles
    ClearPendingEvent(keepBuild = true) ; Shout's people may still be building, for the request below
    if _hasBeenStopped || kind == ""
        StopEventBuild()
        return ; Ended meanwhile
    endIf
    if !SKSE_HTTP.getBool(handle, mConsts.KEY_EVENT_RESULT, false)
        StopEventBuild()
        if _isGameMasterMode
            Debug.Notification("Nothing happened")
        else
            Debug.Notification("Events need Game Master Mode")
        endIf
        GivePlayerTheTurn()
        return
    endIf
    string text = SKSE_HTTP.getString(handle, mConsts.KEY_EVENT_TEXT, "")
    if text != "" && repository.ShowsEventText(kind)
        ; MantellaSoftware already started writing the reactions, so they are ready sooner once the box is closed. Shout's people keep building meanwhile
        ShowEventText(kind, text)
        if _hasBeenStopped
            StopEventBuild()
            return ; Ended meanwhile
        endIf
    else
        Debug.Notification("Something happened") ; Show What Happened is off: never what happened
    endIf
    if kind != "conversation"
        if !_isShouting
            ; MantellaSoftware switched Shout on with the event, and its Game Master may already bring in someone the event was about.
            ; The next tick finds who is nearby with the Shout Mode page's settings
            _isShouting = true
            SetShoutNearby(NotInConversation(nearby))
            _shoutSentActors = Utility.CreateFormArray(0)
            _shoutSentHandles = Utility.CreateIntArray(0)
        endIf
        ; MantellaSoftware keeps them for Shout too, so they are not sent again. And someone who then joins uses the actor settings built for
        ; the event: the Game Master often brings in who the event was about
        AddShoutSentActors(sentActors, sentHandles)
        _lastEventSentActors = sentActors
        FinishEventBuild(true) ; Built while the event was generated, so usually done. The Shout values below send them
    endIf
    RequestContinueConversation()
    if _pendingEventKind == "" ; Another event picked meanwhile has its own build running
        StopEventBuild()
    endIf
EndFunction

Function AddShoutSentActors(Form[] actors, int[] handles)
    int i = 0
    while actors && i < actors.Length
        if actors[i] && !(_shoutSentActors && _shoutSentActors.Find(actors[i]) >= 0)
            int handle = 0
            if handles && i < handles.Length
                handle = handles[i]
            endIf
            AddShoutSent(actors[i], handle)
        endIf
        i += 1
    endWhile
EndFunction

; Leaves out the active followers: a Nearby or Random Event without Include Followers, using Shout's list, which has them
Actor[] Function WithoutFollowers(Actor[] actors)
    int count = 0
    if actors
        count = actors.Length
    endIf
    Actor[] found = PapyrusUtil.ActorArray(count)
    int foundCount = 0
    int i = 0
    while i < count
        if actors[i] && !MantellaActorChecks.IsActiveFollower(actors[i], repository)
            found[foundCount] = actors[i]
            foundCount += 1
        endIf
        i += 1
    endWhile
    Actor[] result = PapyrusUtil.ActorArray(foundCount)
    i = 0
    while i < foundCount
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

Actor[] Function NotInConversation(Actor[] actors)
    int count = 0
    if actors
        count = actors.Length
    endIf
    Actor[] found = PapyrusUtil.ActorArray(count)
    int foundCount = 0
    int i = 0
    while i < count
        if actors[i] && !Participants.HasForm(actors[i])
            found[foundCount] = actors[i]
            foundCount += 1
        endIf
        i += 1
    endWhile
    Actor[] result = PapyrusUtil.ActorArray(foundCount)
    i = 0
    while i < foundCount
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

; keepBuild: the event's build goes on (see OnConversationEventResult)
Function ClearPendingEvent(bool keepBuild = false)
    _pendingEventKind = ""
    _pendingEventHint = ""
    _isEventHintDone = false
    _isEventTurn = false
    _isEventSent = false
    _eventNearby = _noActors
    _eventSentActors = _noForms
    _eventSentHandles = _noInts
    if !keepBuild
        StopEventBuild()
    endIf
EndFunction

bool Function EventAsksForHint(string kind)
    if kind == "conversation"
        return repository.conversationEventAskForHint
    elseIf kind == "nearby"
        return repository.nearbyEventAskForHint
    endIf
    return repository.randomEventAskForHint
EndFunction

int Function EventMaxDescribed(string kind)
    if kind == "nearby"
        return repository.nearbyEventMaxDescribed
    endIf
    return repository.randomEventMaxDescribed
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       End conversation      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnEndConversationActionReceived(Form speaker, string sentence)
    EndConversation()
endEvent

Function EndConversation()
    if _pendingEventKind != ""
        ; Stops the event being generated. Sent right away, while the event request may still be running
        int cancelHandle = SKSE_HTTP.createDictionary()
        SKSE_HTTP.setString(cancelHandle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_INTERRUPT)
        SKSE_HTTP.setBool(cancelHandle, mConsts.KEY_EVENT_CANCEL, true)
        SKSE_HTTP.sendLocalhostHttpRequest(cancelHandle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
        ClearPendingEvent()
    endIf
    _hasBeenStopped = true
    _startNumber += 1 ; A start still being built isn't sent
    _isEarlyTurnPending = false
    _isEarlyTurn = false ; Nothing more is sent for the early turn
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE,mConsts.KEY_REQUESTTYPE_ENDCONVERSATION)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
EndFunction

; A save was loaded with a conversation still on. It ends here in the game right away: MantellaSoftware has no conversation after a
; reload, so waiting for its reply gains nothing, and a reply that never arrives would leave the conversation on for good.
; MantellaSoftware is still told, so it saves what the NPCs remember of a conversation it still has. Its reply then finds the quest
; stopped and does nothing
Function EndAfterSaveLoad()
    EndConversation()
    CleanupConversation()
EndFunction

Function CleanupConversation()
    int i = 0
    ClearParticipants()
    ClearRepeatingMessage()
    _ingameEvents = _noStrings
    _cooldownEvents = _noStrings ; So a cooldown from this conversation does not hide events in the next one
    _does_accept_player_input = false
    _isTalking = false
    _lastNpcToSpeak = None
    _lastTopicInfo = 0
    _cachedNearbyActors = _noActors
    _npcEventId = 0
    _hasNpcEventMonitorValues = false
    _sendQuestChecksCatchUp = false
    _isRoomFirstTurn = false
    _roomLine = ""
    _isEarlyTurnPending = false
    _isEarlyTurn = false
    _earlyLine = ""
    _isEarlyListening = false
    _startActors = _noActors
    if _roomMicScanId != 0
        CancelRoomScan(_roomMicScanId) ; Ended before the player spoke
        _roomMicScanId = 0
    endIf
    _isRoomConversation = false
    _isGameMasterMode = false
    _holdForEventText = false ; ShowEventText clears it too. Also here, so a hold left behind can't stop the next conversation from starting
    _shoutJoiners = _noForms
    _actorHandleActors = _noForms ; So the next conversation builds everyone fresh
    _staleActors = _noForms
    ClearPendingEvent()
    _eventScanId += 1 ; A search from the wheel is about this conversation's people
    _eventScanNearby = _noActors
    _lastEventSentActors = _noForms
    ClearPrebuiltActors()
    ClearShout()
    ;SKSE_HTTP.clearAllDictionaries()
    If (MantellaConversationParticipantsQuest.IsRunning())
        MantellaConversationParticipantsQuest.Stop()
    EndIf
    int handle = ModEvent.Create(EventInterface.EVENT_CONVERSATION_ENDED)
    if (handle)        
        ModEvent.Send(handle)
    endIf 
    Debug.Notification("Conversation ended.")  
    Stop()
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      Remove character       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnRemoveCharacterActionReceived(Form speaker, string sentence)
    Actor[] actors = new Actor[2]
    actors[0] = speaker as Actor
    RemoveActors(actors)
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Handle player speaking    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function sendRequestForPlayerInput(string playerInput, bool updateContext)
    if(!_hasBeenStopped)
        int handle = SKSE_HTTP.createDictionary()
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_PLAYERINPUT)
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE_PLAYERINPUT, playerinput)
        ; Send the topic to use in case the player's input is voiced
        ; (without this the server falls back to topic 1, which can break the topic alternation)
        SKSE_HTTP.setInt(handle, mConsts.KEY_CONTINUECONVERSATION_TOPICINFOFILE, GetNextTopicID())

        if repository.targetTrackingAngerState ; only the anger state of the NPCs is updated by UpdateNpcsInConversationArray()
            UpdateNpcsInConversationArray()
        endIf
        SKSE_HTTP.setNestedDictionariesArray(handle, mConsts.KEY_ACTORS, _actorHandles)

        if updateContext ; if context has not been refreshed recently
            BuildContext()
        endIf
        SKSE_HTTP.setNestedDictionary(handle, mConsts.KEY_CONTEXT, _contextHandle)
        bool usedRoomScan = UseRoomMicScan()
        AddShoutValues(handle)
        if usedRoomScan
            ClearPrebuiltActors() ; Built while the player spoke. Later requests build them fresh
        endIf

        AddHeardLines(handle)
        SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    EndIf
endFunction

; Saying something to the room with the microphone: who is nearby, found while the player spoke, goes with their line, so the
; Game Master can pick someone to answer. Waits if the scan is not done yet. Returns true if it was used
bool Function UseRoomMicScan()
    int scanId = _roomMicScanId
    if scanId == 0
        return false
    endIf
    _roomMicScanId = 0
    if !FinishRoomScan(scanId)
        RefreshShoutNearby() ; Replaced by another scan: looked for here instead
        return false
    endIf
    SetShoutNearby(GetRoomScanResult())
    _isShoutNearbyByShoutRules = true ; Found with the Shout Mode page's rules, as RefreshShoutNearby does
    return true
endFunction

function RequestInterrupt()
    ; A bystander of an NPC Event steps in. MantellaSoftware learns they joined from the actors sent with their input
    if(!_hasBeenStopped && IsNpcEvent() && !IsPlayerInConversation())
        Actor[] actors = new Actor[1]
        actors[0] = PlayerRef
        AddActors(actors)
        Debug.Notification("Joining the conversation...")
    endif
    ; Nothing to interrupt during the player's turn or without the player (radiant conversations), nor while an event is on its way
    if(_hasBeenStopped || _does_accept_player_input || !IsPlayerInConversation() || _pendingEventKind != "")
        return
    endif

    ; Sent while the continue request is still running. MantellaSoftware stops the NPCs and that request gives the player the turn
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_INTERRUPT)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    Debug.Notification("Interrupting...")
endFunction

; Show (hotkey or wheel): MantellaSoftware takes a picture of the game window right away, and sends it with the player's next line.
; Only in a conversation the player is in. Sent while another request may still be running, like an interruption
function RequestShow()
    if !IsRunning() || _hasBeenStopped || !IsPlayerInConversation()
        return
    endIf
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_SHOW)
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
endFunction

; The microphone starts listening right away. Gathering the game details (events, who is nearby, quests) takes a few seconds in a crowded
; place, so none are sent now: once the player has spoken, MantellaSoftware sends back what was said (KEY_REQUESTTYPE_TTS) and the game
; sends it again with the details
function sendRequestForVoiceTranscribe()
    if(!_does_accept_player_input)
        return
    Else
        _does_accept_player_input = False
    endif

    if _isEarlyTurn
        ; MantellaSoftware has no conversation yet: it only starts listening. What was said is asked for once it has (EndEarlyTurn)
        _isEarlyListening = true
        SendListenBeforeStart()
    elseIf(!_hasBeenStopped)
        int handle = SKSE_HTTP.createDictionary()
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_PLAYERINPUT)
        SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE_PLAYERINPUT, "")
        SKSE_HTTP.setBool(handle, mConsts.KEY_PLAYERINPUT_DETAILSFOLLOW, true)
        SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
    endIf
    ShowRepeatingMessage("Listening...")
endFunction

; With the names of who the conversation starts with, so the microphone hears them right from the first line
Function SendListenBeforeStart()
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setString(handle, mConsts.KEY_REQUESTTYPE, mConsts.KEY_REQUESTTYPE_LISTENBEFORESTART)
    if repository.useHotkeyToStartMic
        SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_PTT)
    else
        SKSE_HTTP.setString(handle, mConsts.KEY_INPUTTYPE, mConsts.KEY_INPUTTYPE_MIC)
    endIf
    string[] names = Utility.CreateStringArray(_startActors.Length) ; The player's place stays empty: MantellaSoftware skips it
    int i = 0
    while i < _startActors.Length
        if _startActors[i] && _startActors[i] != PlayerRef
            names[i] = _startActors[i].GetDisplayName()
        endIf
        i += 1
    endWhile
    SKSE_HTTP.setStringArray(handle, mConsts.KEY_LISTEN_NAMES, names)
    SKSE_HTTP.setString(handle, mConsts.KEY_LISTEN_PLAYERNAME, PlayerRef.GetDisplayName())
    SKSE_HTTP.sendLocalhostHttpRequest(handle, repository.HttpPort, mConsts.HTTP_ROUTE_MAIN)
EndFunction

bool _isTextBoxOpen = false ; One text box at a time: presses while it is open are ignored

; The text box opens right away. The game details are gathered after Enter, as they take a few seconds in a crowded place
function GetPlayerTextInput()
    if(!_does_accept_player_input || _isTextBoxOpen)
        return
    endif
    _isTextBoxOpen = true

    UIExtensions.InitMenu("UITextEntryMenu")
    UIExtensions.OpenMenu("UITextEntryMenu")
    string result = UIExtensions.GetMenuResultString("UITextEntryMenu")
    _isTextBoxOpen = false

    if (result && result != "" && _does_accept_player_input)
        _does_accept_player_input = False ; Before the details are gathered, so the talk key does nothing meanwhile
        ClearRepeatingMessage()
        SendTypedLine(result)
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;     Handle NPC speaking     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Actor function GetNpcToLookAt(Actor speaker, Actor lastNpcToSpeak)
    Actor NpcToLookAt = None
    if (lastNpcToSpeak != speaker)
        if (lastNpcToSpeak != None)
            NpcToLookAt = lastNpcToSpeak
        else
            lastNpcToSpeak = speaker
            int i = 0
            while i < CountActorsInConversation()
                Actor tmpActor = GetActorInConversationByIndex(i)
                if GetActorName(tmpActor) != GetActorName(speaker)
                    NpcToLookAt = tmpActor
                endIf
                i += 1
            endWhile
            if IsPlayerInConversation()
                NpcToLookAt = PlayerRef
            endIf
        endIf
    elseIf IsPlayerInConversation()
        NpcToLookAt = PlayerRef
    endIf
    return NpcToLookAt
endFunction

function WaitForNpcToFinishSpeaking(Actor speaker, Actor lastNpcToSpeak)
    ; if this is the start of the conversation there is no need to wait, so skip this function entirely
    if lastNpcToSpeak != None
        ; if the current NPC did not speak last in a multi-NPC conversation, 
        ; wait for the last NPC to finish speaking to avoid interrupting
        ; and then cast the IsTalking spell on the current NPC (mainly to check that they are not speaking non-Mantella voicelines)
        if speaker != lastNpcToSpeak 
            WaitForSpecificNpcToFinishSpeaking(lastNpcToSpeak)
            speaker.AddSpell(MantellaIsTalkingSpell, False)
            Utility.Wait(0.01) ; allow time for _isTalking to be set
        endIf
        ; wait for the current NPC to finish speaking before starting the next voiceline
        WaitForSpecificNpcToFinishSpeaking(speaker)
    endIf
endFunction

function WaitForSpecificNpcToFinishSpeaking(Actor selectedNpc)
    float waitTime = 0.01
    float totalWaitTime = 0
    while _isTalking == true ; wait until the NPC has finished speaking
        Utility.Wait(waitTime)
        totalWaitTime += waitTime
        if totalWaitTime > 10 ; note that this isn't really in seconds due to the overhead of the loop running
            Debug.Notification("NPC speaking too long, ending wait...")
            _isTalking = false
        endIf
    endWhile
    selectedNpc.RemoveSpell(MantellaIsTalkingSpell)
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Action handler        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function RaiseActionEvent(Actor speaker, int[] actionsHandles)
    ; Processes actions array, automatically detecting legacy vs advanced actions.
    ;
    ; Args:
    ;     speaker: The NPC who spoke (for context)
    ;     actionsHandles: Array of SKSE_HTTP dictionary handles, one per action
    ;
    ; Each action handle contains:
    ;     - "identifier": Action name (e.g., "mantella_npc_follow")
    ;     - "arguments" (optional): Dictionary with parameters
    ;       - If present = advanced action (sends to MantellaConversation_Advanced_Action_ prefix)
    ;       - If absent = legacy action (sends to MantellaConversation_Action_ prefix)
    ;
    ; Fallback Behavior:
    ;     If LLM forgets to include arguments for a built-in action, it will be routed
    ;     to the legacy handler, which will execute the action on the speaker only.

    if !actionsHandles || actionsHandles.Length == 0
        return ; dont send out an action event if there are no actions to act upon
    endIf

    if !(speaker)
        if _lastNpcToSpeak
            speaker = _lastNpcToSpeak
        else
            speaker = GetActorInConversationByIndex(1)
        endIf
    endIf

    int i = 0
    While i < actionsHandles.Length
        int actionHandle = actionsHandles[i]

        ; Extract action identifier
        string actionIdentifier = SKSE_HTTP.getString(actionHandle, mConsts.ACTION_IDENTIFIER, "")

        if actionIdentifier != ""
            ; Check for special handling (eg inventory action timing)
            if actionIdentifier == mConsts.ACTION_NPC_INVENTORY
                Utility.Wait(0.5)
                WaitForNpcToFinishSpeaking(speaker, _lastNpcToSpeak)
            endIf

            if actionIdentifier == mConsts.KEY_REQUESTTYPE_ENDCONVERSATION
                EndConversation()
            else
                int argumentsHandle = SKSE_HTTP.getNestedDictionary(actionHandle, mConsts.ACTION_ARGUMENTS, 0)
                ; Detect if this is an advanced action (has arguments) or legacy action (no arguments)
                if argumentsHandle != 0
                    string eventName = EventInterface.EVENT_ADVANCED_ACTIONS_PREFIX + actionIdentifier
                    int eventHandle = ModEvent.Create(eventName)
                    if eventHandle
                        ModEvent.PushForm(eventHandle, speaker)
                        ModEvent.PushForm(eventHandle, Self as Quest)  ; For name resolution
                        ModEvent.PushInt(eventHandle, argumentsHandle)
                        ModEvent.Send(eventHandle)
                    else
                        Debug.Notification("Mantella: ERROR - Failed to create advanced action event handle")
                    endIf
                else
                    ; LEGACY ACTION PATH
                    string eventName = EventInterface.EVENT_ACTIONS_PREFIX + actionIdentifier
                    ; Legacy action: no arguments, send with simple signature
                    ; This handles both:
                    ;   1. Player-created custom actions built when the old system was in place
                    ;   2. Built-in actions when LLM forgets arguments (fallback to speaker-only)
                    int eventHandle = ModEvent.Create(eventName)
                    if eventHandle
                        ModEvent.PushForm(eventHandle, speaker)
                        ModEvent.Send(eventHandle)
                    endIf
                endIf
            endIf
        else
            Debug.Trace("Mantella: Warning - Action missing identifier", 1)
        endIf

        i += 1
    EndWhile
EndFunction

Function AddExtraRequestAction(string extraAction)
    if(!_extraRequestActions)
        _extraRequestActions = Utility.CreateStringArray(1)
    Else
        _extraRequestActions = Utility.ResizeStringArray(_extraRequestActions, _extraRequestActions.Length + 1)
    endif
    _extraRequestActions[_extraRequestActions.Length - 1] = extraAction
EndFunction

Function ClearExtraRequestAction()
    _extraRequestActions = Utility.CreateStringArray(0)
EndFunction

Function SendActorAddedEvents(Form[] actorsAdded)
    int index = 0
    While (index < actorsAdded.Length)
        Actor speaker = actorsAdded[index] as Actor
        If (speaker)
            int handle = ModEvent.Create(EventInterface.EVENT_CONVERSATION_NPC_ADDED)
            if (handle)
                ModEvent.PushForm(handle, speaker)
                ModEvent.Send(handle)
            endIf 
        EndIf
        index += 1
    EndWhile
EndFunction

Function SendActorRemovedEvents(Form[] actorsRemoved)
    int index = 0
    While (index < actorsRemoved.Length)
        Actor speaker = actorsRemoved[index] as Actor
        int handle = ModEvent.Create(EventInterface.EVENT_CONVERSATION_NPC_REMOVED)
        if (handle)
            ModEvent.PushForm(handle, speaker)
            ModEvent.Send(handle)
        endIf 
        index += 1
    EndWhile
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Ingame events        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function AddIngameEvent(string eventText)
    if (eventText != "")
        if(!_ingameEvents)
            _ingameEvents = Utility.CreateStringArray(1)
        Else
            _ingameEvents = Utility.ResizeStringArray(_ingameEvents, _ingameEvents.Length + 1)
        endif
        _ingameEvents[_ingameEvents.Length - 1] = eventText
    endIf
EndFunction

; The hits, spell casts and bow shots added most recently and when, so one that keeps repeating (eg a continuous spell) is only added once per cooldown
String[] _cooldownEvents
float[] _cooldownEventTimes
int _nextCooldownEvent = 0

Function AddIngameEventWithCooldown(string eventText)
    float cooldown = repository.eventRepeatCooldown
    if cooldown <= 0 ; Not set yet: the MCM version update has not run on this save
        cooldown = 10
    endIf
    if !_cooldownEvents
        _cooldownEvents = new String[32]
        _cooldownEventTimes = new float[32]
    endIf
    float now = Utility.GetCurrentRealTime()
    int index = _cooldownEvents.Find(eventText)
    if index >= 0
        float elapsed = now - _cooldownEventTimes[index]
        if elapsed >= 0 && elapsed < cooldown ; Real time starts from 0 on every game launch, so a time kept in the save can be in the future
            return
        endIf
    else
        index = _nextCooldownEvent
        _cooldownEvents[index] = eventText
        _nextCooldownEvent = (index + 1) % _cooldownEvents.Length
    endIf
    _cooldownEventTimes[index] = now
    AddIngameEvent(eventText)
EndFunction

Function ClearIngameEvent()
    _ingameEvents = Utility.CreateStringArray(0)
EndFunction


event OnAddEventReceived(string text)
    AddIngameEvent(text)
endEvent

event OnActionResponseCompleted(string actionIdentifier)
    _waitingForActionResponse = false
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Action: Reload conversation ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnReloadConversationActionReceived(Form speaker, string sentence)
    ; Debug.Notification("OnReloadConversationActionReceived triggered")
    AddExtraRequestAction(mConsts.ACTION_RELOADCONVERSATION)
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Error handling        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnHttpErrorReceived(int typedDictionaryHandle)
    If (!IsRunning())
        return ; Not about a conversation, e.g. a failed NPC Initiative check
    EndIf
    string errorMessage = SKSE_HTTP.getString(typedDictionaryHandle, mConsts.HTTP_ERROR ,"error")
    If (errorMessage != "error")
        Debug.Notification("Received SKSE_HTTP error: " + errorMessage)        
        CleanupConversation()
    Else
        Debug.Notification("Error: Received an error event from SKSE_HTTP but did not receive an error message.")
        CleanupConversation()
    EndIf
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;            Access           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;            Utils            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bool Function IsPlayerInConversation()
    int i = 0
    While i < Participants.GetSize()
        if (Participants.GetAt(i) == PlayerRef)
            return true
        endif
        i += 1
    EndWhile
    return false    
EndFunction

Function CauseReassignmentOfParticipantAlias()
    If (MantellaConversationParticipantsQuest.IsRunning())
        ;Debug.Notification("Stopping MantellaConversationParticipantsQuest")
        MantellaConversationParticipantsQuest.Stop()
    EndIf
    ;Debug.Notification("Starting MantellaConversationParticipantsQuest to asign QuestAlias")
    MantellaConversationParticipantsQuest.Start()
EndFunction

Function AddActors(Actor[] actorsToAdd)
    int i = 0
    Form[] actorsAdded = Utility.CreateFormArray(0)
    While i < actorsToAdd.Length
        Actor possibleNewActor = actorsToAdd[i]
        ; An empty place is skipped: it would reach the Vanilla Dialogue plugin through SendActorAddedEvents, which can crash the game
        if possibleNewActor && Participants.Find(possibleNewActor) < 0
            Participants.AddForm(possibleNewActor)
            possibleNewActor.AddToFaction(MantellaConversationParticipantsFaction)
            actorsAdded = Utility.ResizeFormArray(actorsAdded, actorsAdded.Length + 1)
            actorsAdded[actorsAdded.Length - 1] = possibleNewActor

            ; check if there are multiple actors with the same name
            int nameCount = 0
            int j = 0
            bool break = false
            if (possibleNewActor != PlayerRef) ; ignore the player having the same name as an actor
                While (j < Participants.GetSize()) && (break==false)
                    Actor currentActor = Participants.GetAt(j) as Actor
                    if (currentActor.GetDisplayName() == possibleNewActor.GetDisplayName())
                        nameCount += 1
                        if (currentActor == possibleNewActor) ; stop counting when the exact actor is found (not just the same name)
                            break = true
                        endIf
                    endIf
                    j += 1
                EndWhile

                if (nameCount > 1)
                    ; set an ID to this non-uniquely-named actor in the form of a faction rank
                    ; these uniquely ID'd names can be called via the GetActorName() function
                    possibleNewActor.SetFactionRank(MantellaConversationParticipantsFaction, nameCount)
                endIf
            endIf
        endIf
        i += 1
    EndWhile
    If (actorsAdded.Length > 0)
        CauseReassignmentOfParticipantAlias()
        BuildNpcsInConversationArray()
        SendActorAddedEvents(actorsAdded)
    EndIf
    
    ;PrintActorsInConversation()
EndFunction

Function RemoveActors(Actor[] actorsToRemove)
    PrintActorsArray("Actors to remove: ",actorsToRemove)
    Form[] actorsRemoved = Utility.CreateFormArray(0)
    int i = 0
    While (i < actorsToRemove.Length)
        Actor actorInQuestion = actorsToRemove[i]
        If (Participants.HasForm(actorInQuestion))
            actorsRemoved = Utility.ResizeFormArray(actorsRemoved, actorsRemoved.Length + 1)
            actorsRemoved[actorsRemoved.Length - 1] = actorInQuestion
            Participants.RemoveAddedForm(actorInQuestion)
            actorInQuestion.RemoveFromFaction(MantellaConversationParticipantsFaction)
            Debug.Notification(actorInQuestion.GetDisplayName()+" left the conversation.")
            int joinerIndex = -1
            if _shoutJoiners
                joinerIndex = _shoutJoiners.Find(actorInQuestion)
            endIf
            if joinerIndex >= 0
                _shoutJoiners[joinerIndex] = None ; If the player brings them back in, they no longer count as joined by shouting
            endIf
        EndIf
        i += 1
    EndWhile
    if (Participants.GetSize() < 2)
        EndConversation()
    ElseIf (actorsRemoved.Length > 0)
        CauseReassignmentOfParticipantAlias()
        BuildNpcsInConversationArray()
        SendActorRemovedEvents(actorsRemoved)
    endIf
    ;PrintActorsInConversation()
EndFunction

Function ClearParticipants()
    int i = 0
    While i < Participants.GetSize()
        (Participants.GetAt(i) as Actor).RemoveFromFaction(MantellaConversationParticipantsFaction)
        i += 1
    EndWhile
    Participants.Revert()
EndFunction

bool Function ContainsActor(Actor[] arrayToCheck, Actor actorCheckFor)
    int i = 0
    While i < arrayToCheck.Length
        If (arrayToCheck[i] == actorCheckFor)
            return True
        EndIf
        i += 1
    EndWhile
    return False
EndFunction

Function PrintActorsArray(string prefix, Actor[] actors)
    int i = 0
    string actor_message = ""
    While i < actors.Length
        actor_message += GetActorName(actors[i]) + ", "
        i += 1
    EndWhile
    ;Debug.Notification(prefix + actor_message)
EndFunction

Function PrintActorsInConversation()
    int i = 0
    string actor_message = ""
    While i < Participants.GetSize()
        actor_message += GetActorName(Participants.GetAt(i) as Actor) + ", "
        i += 1
    EndWhile
    Debug.Notification(actor_message)
EndFunction

int Function CountActorsInConversation()
    return Participants.GetSize()
EndFunction

Actor Function GetActorInConversationByIndex(int indexOfActor) 
    If (indexOfActor >= 0 && indexOfActor < Participants.getSize())
        return Participants.GetAt(indexOfActor) as Actor
    EndIf
    return none
EndFunction

Function AddCurrentActorsAndContext(int handleToAddTo, bool isConversationStart = false)
    ;Add Actors
    SKSE_HTTP.setNestedDictionariesArray(handleToAddTo, mConsts.KEY_ACTORS, _actorHandles)
    ;add context
    SKSE_HTTP.setNestedDictionary(handleToAddTo, mConsts.KEY_CONTEXT, _contextHandle)
EndFunction

; Only who is new is built now: building someone's actor settings takes a moment, which held up joins and stepping into an NPC Event.
; Who was already in the conversation keeps theirs, and so does someone built earlier in it (BuiltHandle): by a room scan or the NPC Event
; check, or sent by Shout or with an event. Their actor settings are built again on the next ticks (RefreshStaleActors), as they used to be
; on every join and leave
int[] function BuildNpcsInConversationArray()
    int count = Participants.GetSize()
    int[] handles = Utility.CreateIntArray(count)
    Form[] actors = Utility.CreateFormArray(count)
    Form[] stale = Utility.CreateFormArray(count)
    int staleCount = 0
    int i = 0
    While i < count
        Actor npc = Participants.GetAt(i) as Actor
        actors[i] = npc
        int kept = -1
        if _actorHandleActors
            kept = _actorHandleActors.Find(npc)
        endIf
        int built = 0
        if kept >= 0 && kept < _actorHandles.Length
            built = _actorHandles[kept]
        else
            built = BuiltHandle(npc)
        endIf
        if built != 0
            handles[i] = built
            stale[staleCount] = npc
            staleCount += 1
        else
            handles[i] = buildActorSetting(npc)
        endIf
        i += 1
    EndWhile
    _actorHandles = handles
    _actorHandleActors = actors
    _staleActors = Utility.ResizeFormArray(stale, staleCount)
    _actorsUpdated = true
endFunction

; Called on the listener's ticks. Builds again the actor settings kept by the last join or leave (see BuildNpcsInConversationArray),
; and sends them with the next request
Function RefreshStaleActors()
    bool refreshed = false
    while _staleActors && _staleActors.Length > 0 && IsRunning() && !_hasBeenStopped
        Actor npc = _staleActors[_staleActors.Length - 1] as Actor
        _staleActors = Utility.ResizeFormArray(_staleActors, _staleActors.Length - 1)
        if npc
            int handle = buildActorSetting(npc)
            int index = -1
            if _actorHandleActors
                index = _actorHandleActors.Find(npc) ; Looked up after building: someone may have joined or left meanwhile
            endIf
            if index >= 0 && index < _actorHandles.Length
                _actorHandles[index] = handle
                refreshed = true
            endIf
        endIf
    endWhile
    if refreshed
        _actorsUpdated = true
    endIf
EndFunction

int[] function UpdateNpcsInConversationArray()
    ; Update NPC details where variables are dynamic
    int i = 0
    While i < Participants.GetSize()
        Actor actorToBuild = Participants.GetAt(i) as Actor
        SKSE_HTTP.setBool(_actorHandles[i], mConsts.KEY_ACTOR_ISINCOMBAT, actorToBuild.IsInCombat())
        i += 1
    EndWhile
endFunction

int function buildActorSetting(Actor actorToBuild)  
    int handle = SKSE_HTTP.createDictionary()
    SKSE_HTTP.setInt(handle, mConsts.KEY_ACTOR_BASEID, (actorToBuild.getactorbase() as form).getformid())
    SKSE_HTTP.setInt(handle, mConsts.KEY_ACTOR_REFID, (actorToBuild as form).getformid())
    SKSE_HTTP.setString(handle, mConsts.KEY_ACTOR_NAME, GetActorName(actorToBuild))
    bool isPlayerCharacter = actorToBuild == PlayerRef
    SKSE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISPLAYER, isPlayerCharacter)
    SKSE_HTTP.setInt(handle, mConsts.KEY_ACTOR_GENDER, actorToBuild.getleveledactorbase().getsex())
    SKSE_HTTP.setString(handle, mConsts.KEY_ACTOR_RACE, actorToBuild.getrace())
    SKSE_HTTP.setInt(handle, mConsts.KEY_ACTOR_RELATIONSHIPRANK, actorToBuild.getrelationshiprank(PlayerRef))
    SKSE_HTTP.setString(handle, mConsts.KEY_ACTOR_VOICETYPE, actorToBuild.GetVoiceType())
    SKSE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISGHOST, actorToBuild.IsGhost())
    if !isPlayerCharacter && repository.IsVoiceClipsInstalled()
        ActorBase npc = actorToBuild.GetActorBase()
        SKSE_HTTP.setString(handle, mConsts.KEY_ACTOR_PLUGIN, MantellaVoiceClips.GetSourcePlugin(npc))
        SKSE_HTTP.setInt(handle, mConsts.KEY_ACTOR_LOCALID, MantellaVoiceClips.GetLocalFormID(npc))
    endIf
    SKSE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISINCOMBAT, actorToBuild.IsInCombat())
    SKSE_HTTP.setBool(handle, mConsts.KEY_ACTOR_ISENEMY, actorToBuild.getcombattarget() == PlayerRef)
    EquipmentDescriber.AddEquipmentDescription(handle, actorToBuild, isPlayerCharacter, repository)
    int customActorValuesHandle = SKSE_HTTP.createDictionary()
    If (isPlayerCharacter)
        AddCustomPCValues(customActorValuesHandle, actorToBuild)
    EndIf
    SKSE_HTTP.setNestedDictionary(handle, mConsts.KEY_ACTOR_CUSTOMVALUES, customActorValuesHandle)
    return handle
endFunction

Function AddCustomPCValues(int customActorValuesHandle, Actor actorToBuildCustomValuesFor)
    if(!repository.IsVR())
        string description = repository.playerCharacterDescription1
        If (repository.playerCharacterUsePlayerDescription2)
            description = repository.playerCharacterDescription2
        EndIf
        SKSE_HTTP.setString(customActorValuesHandle, mConsts.KEY_ACTOR_PC_DESCRIPTION, description)
        SKSE_HTTP.setBool(customActorValuesHandle, mConsts.KEY_ACTOR_PC_VOICEPLAYERINPUT, repository.playerCharacterVoicePlayerInput)
        If (repository.playerCharacterVoicePlayerInput)
            SKSE_HTTP.setString(customActorValuesHandle, mConsts.KEY_ACTOR_PC_VOICEMODEL, repository.playerCharacterVoiceModel)
        EndIf
    endIf
EndFunction

int function BuildContext(bool isConversationStart = false)
    _contextHandle = SKSE_HTTP.createDictionary()
    if (isConversationStart)
        _location = ((Participants.GetAt(0) as Actor).GetCurrentLocation() as Form).getName()
        if _location == ""
            _location = "Skyrim"
        endIf
        SKSE_HTTP.setString(_contextHandle, mConsts.KEY_CONTEXT_LOCATION, _location)
    endIf

    if (isConversationStart || repository.playerTrackingOnWeatherChange)
        AddCurrentWeather(_contextHandle)
    endIf

    if (isConversationStart || repository.playerTrackingOnTimeChange)
        _initialTime = GetCurrentHourOfDay()
    endIf
    SKSE_HTTP.setInt(_contextHandle, mConsts.KEY_CONTEXT_TIME, _initialTime)

    string[] past_events = deepcopy(_ingameEvents)
    SKSE_HTTP.setStringArray(_contextHandle, mConsts.KEY_CONTEXT_INGAMEEVENTS, past_events)
    ClearIngameEvent()
    AddQuestCheckResults(_contextHandle)

    ; Add nearby actors context for action targeting
    int[] nearbyActorHandles = BuildNearbyActorsContext()
    if nearbyActorHandles && nearbyActorHandles.Length > 0
        SKSE_HTTP.setNestedDictionariesArray(_contextHandle, mConsts.KEY_CONTEXT_NEARBYACTORS, nearbyActorHandles)
    endIf
endFunction

int[] function BuildNearbyActorsContext()
    ; Scan for nearby actors (excludes Mantella conversation participants)
    Actor[] nearbyActors = Listener.ScanNearbyActors()
    _cachedNearbyActors = nearbyActors

    if !nearbyActors || nearbyActors.Length == 0
        return Utility.CreateIntArray(0)
    endIf

    int totalEntries = nearbyActors.Length
    int[] nearbyActorHandles = Utility.CreateIntArray(totalEntries)
    int handleIndex = 0
    float toMeters = 1.0 / 71.0210
    int i = 0
    While i < totalEntries
        Actor nearbyActor = nearbyActors[i]
        if nearbyActor != None
            int actorHandle = SKSE_HTTP.createDictionary()
            SKSE_HTTP.setString(actorHandle, "name", nearbyActor.GetDisplayName())
            float distanceInMeters = PlayerRef.GetDistance(nearbyActor) * toMeters
            SKSE_HTTP.setFloat(actorHandle, "distance", distanceInMeters)
            nearbyActorHandles[handleIndex] = actorHandle
            handleIndex += 1
        endIf
        i += 1
    EndWhile

    if handleIndex == 0
        return Utility.CreateIntArray(0)
    endIf

    if handleIndex != totalEntries
        nearbyActorHandles = Utility.ResizeIntArray(nearbyActorHandles, handleIndex)
    endIf

    return nearbyActorHandles
endFunction

; The lines the Vanilla Dialogues plugin caught since the last request. It forgets them once handed over, so call this only right before sending
Function AddHeardLines(int handle)
    if !repository.IsHeardLinesInstalled()
        return
    endIf
    string lines = MantellaHeardLines.TakeLines()
    if lines != ""
        SKSE_HTTP.setString(handle, mConsts.KEY_HEARDLINES, lines)
    endIf
EndFunction

; Adds the quest tag check plugin's answers, so MantellaSoftware can tell which quests moved on
Function AddQuestCheckResults(int handleToAddTo)
    if !repository.IsQuestChecksInstalled()
        return
    endIf
    ; The version first: if a new list arrives in between, MantellaSoftware sees the old version and ignores these answers
    SKSE_HTTP.setString(handleToAddTo, mConsts.KEY_QUESTCHECKS_VERSION, MantellaQuestChecks.GetListVersion())
    SKSE_HTTP.setFloatArray(handleToAddTo, mConsts.KEY_QUESTCHECKS_RESULTS, MantellaQuestChecks.Evaluate())
EndFunction

int function AddCurrentWeather(int contextHandle)
    If (!PlayerRef.IsInInterior())
        int handle = SKSE_HTTP.createDictionary()
        Weather currentWeather = Weather.GetCurrentWeather()
        SKSE_HTTP.setString(handle, mConsts.KEY_CONTEXT_WEATHER_ID, currentWeather.GetFormID())
        SKSE_HTTP.setInt(handle, mConsts.KEY_CONTEXT_WEATHER_CLASSIFICATION, currentWeather.GetClassification())
        SKSE_HTTP.setNestedDictionary(contextHandle, mConsts.KEY_CONTEXT_WEATHER, handle)
    EndIf
endFunction

int function GetCurrentHourOfDay()
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	int Hour = Math.Floor(Time) ; Get whole hour
	return Hour
endFunction

string[] function deepcopy(string[] array_to_copy)
    string[] result = Utility.CreateStringArray(array_to_copy.Length)
    int i = 0
    While i < array_to_copy.Length
        result[i] = array_to_copy[i]
        i += 1
    EndWhile
    return result
endFunction

Function ShowRepeatingMessage(string messageToShow)
    _repeatingMessage = messageToShow
    Debug.Notification(_repeatingMessage)
    if repository.showReminderMessages ; OnUpdate repeats it until it is cleared
        RegisterForSingleUpdate(10)
    endIf
EndFunction

Function ClearRepeatingMessage()
    _repeatingMessage = ""
EndFunction
