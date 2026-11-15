Scriptname MantellaEventTest Hidden
{In-game test of the Conversation Wheel events. Runs each event without the wheel, so the player only watches and answers the Private menu.
Started from the console by the batch file that tests/ingame/conversation_events/conversation_events_ingame.py in the Mantella repository
writes. That script then checks Mantella's log for what the game sent and what MantellaSoftware did. See docs/conversation_wheel.md there,
"Automated tests"}

float Function TIMEOUT() global ; Seconds to wait for each step
    return 90.0
EndFunction

Function Run(MantellaRepository repository, MantellaConversation conversation, MantellaListenerScript listener) global
    if conversation.IsRunning()
        Stop("end the conversation first")
        return
    endIf
    Note("starting")
    Utility.Wait(3.0) ; The place has just loaded
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    if people.Length < 3
        Stop("it needs at least 3 people within 20 m, found " + people.Length)
        return
    endIf
    Actor player = Game.GetPlayer()

    ; 1. One-on-one: the three events in the player's turn, then Private
    Actor[] actors = new Actor[2]
    actors[0] = player
    actors[1] = people[0]
    if StartConversation(conversation, actors, false)
        WaitForTurn(conversation)
        RunEvent(conversation, "conversation")
        NoteNearby(conversation, "nearby")
        RunEvent(conversation, "nearby")
        JoinOneDescribed(conversation, "Nearby")
        NoteNearby(conversation, "random")
        RunEvent(conversation, "random")
        JoinOneDescribed(conversation, "Random")
        Note("Private. If a menu asks, pick Yes")
        conversation.SetShout(false)
        RunEvent(conversation, "conversation") ; MantellaSoftware learns about Private with the next request
        EndConversation(conversation)
    endIf

    ; 2. A group: a Conversation Event, another one picked while an NPC reacts to it, then ending while a third is being written
    actors = new Actor[3]
    actors[0] = player
    actors[1] = people[0]
    actors[2] = people[1]
    if StartConversation(conversation, actors, true)
        RunEvent(conversation, "conversation", false)
        if WaitForNpcLine(conversation, conversation.NpcLinesReceived())
            Note("picking an event while an NPC talks")
            RunEvent(conversation, "conversation")
        endIf
        WaitForTurn(conversation)
        Note("ending while an event is generating")
        conversation.RequestConversationEvent("conversation")
        EndConversation(conversation)
    endIf

    ; 3. An NPC Event: the player watches, steps in and picks a Conversation Event
    string reason = StartNpcEvent(listener, conversation)
    if reason == ""
        Utility.Wait(15.0) ; Watching a few lines
        if conversation.IsRunning() && !conversation.IsEnding()
            Note("stepping into the NPC Event")
            conversation.RequestInterrupt()
            WaitForTurn(conversation)
            RunEvent(conversation, "conversation")
            EndConversation(conversation)
        endIf
    else
        Note("no NPC Event after 3 tries (" + reason + "). Run the test again for this part")
    endIf
    Done()
EndFunction

bool Function StartConversation(MantellaConversation conversation, Actor[] actors, bool isGroup) global
    Note("conversation with " + actors[1].GetDisplayName())
    conversation.Start()
    if isGroup
        conversation.SetGroupStart()
    endIf
    conversation.StartConversation(actors)
    ; Until someone speaks or the player has the turn, so MantellaSoftware's start reply has arrived
    float waited = 0.0
    while conversation.IsRunning() && !conversation.IsPlayersTurn() && !conversation.GetIsTalking() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return conversation.IsRunning() && (conversation.IsPlayersTurn() || conversation.GetIsTalking())
EndFunction

; Picks the event as the wheel does, and waits until its result has arrived and, with waitForTurn, the player has the turn again
Function RunEvent(MantellaConversation conversation, string kind, bool waitForTurn = true) global
    Note(kind + " event")
    conversation.RequestConversationEvent(kind)
    float waited = 0.0
    while conversation.IsEventPending() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    if waitForTurn
        WaitForTurn(conversation)
    endIf
EndFunction

; Until an NPC line arrives after the first linesBefore. False if the player gets the turn first (nothing happened, or the player reacts first).
; Not until the NPC counts as talking: that can start before the line has arrived, and then no line is interrupted
bool Function WaitForNpcLine(MantellaConversation conversation, int linesBefore) global
    float waited = 0.0
    while conversation.IsRunning() && conversation.NpcLinesReceived() == linesBefore && !conversation.IsPlayersTurn() && waited < TIMEOUT()
        Utility.Wait(0.1)
        waited += 0.1
    endWhile
    return conversation.IsRunning() && conversation.NpcLinesReceived() > linesBefore
EndFunction

; With the microphone on, the player's turn can't be seen here, so each wait runs until its timeout
Function WaitForTurn(MantellaConversation conversation) global
    float waited = 0.0
    while conversation.IsRunning() && !conversation.IsPlayersTurn() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
EndFunction

; Asks for an NPC Event and waits until it runs. Asks again, up to 3 times, if it doesn't: someone in it may have become busy, e.g. in
; one of the inn's scenes, while MantellaSoftware wrote it, or nothing happened. "" once one runs, else why the last try didn't
string Function StartNpcEvent(MantellaListenerScript listener, MantellaConversation conversation) global
    string reason = ""
    int tries = 0
    while tries < 3
        if tries > 0
            Debug.Trace("Mantella NPC Event: asking again (" + reason + ")")
            Utility.Wait(5.0)
        endIf
        tries += 1
        reason = listener.TryNpcEventCheck(true)
        if reason == ""
            float waited = 0.0 ; Until MantellaSoftware answers. A scene that starts is running by then
            while !listener.IsNpcEventCheckAnswered() && waited < TIMEOUT()
                Utility.Wait(0.5)
                waited += 0.5
            endWhile
            if WaitForNpcEvent(conversation, 10.0)
                return ""
            endIf
            reason = listener.LastNpcEventOutcome()
        endIf
    endWhile
    return reason
EndFunction

bool Function WaitForNpcEvent(MantellaConversation conversation, float seconds = 90.0) global
    float waited = 0.0
    while !(conversation.IsRunning() && conversation.IsNpcEvent() && !conversation.IsEnding()) && waited < seconds
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return conversation.IsRunning() && conversation.IsNpcEvent()
EndFunction

Function EndConversation(MantellaConversation conversation) global
    if conversation.IsRunning() && !conversation.IsEnding()
        conversation.EndConversation()
    endIf
    float waited = 0.0
    while conversation.IsRunning() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
EndFunction

; Who a Nearby or Random Event would be about, found by the same function the event uses
Function NoteNearby(MantellaConversation conversation, string kind) global
    Actor[] found = conversation.FindEventNearby(kind)
    int count = 0
    if found
        count = found.Length
    endIf
    string names = ""
    int i = 0
    while i < count && i < 4
        names += found[i].GetDisplayName() + ", "
        i += 1
    endWhile
    Note(kind + " event would be about " + count + " people: " + names)
EndFunction

; Brings in the nearest person the event sent in full who isn't in the conversation, as if the Game Master picked them. Someone who joins after
; an event uses the actor settings built for it (BuiltHandle), and once those turned out wrong, so this tries it on every run. The next request
; carries them. See the "Mantella store:" lines in Papyrus.0.log
Function JoinOneDescribed(MantellaConversation conversation, string label) global
    if !conversation.IsRunning() || conversation.IsEnding() || !conversation.IsShouting()
        Note(label + " Event: nobody brought in, as nothing happened or the conversation ended")
        return
    endIf
    Form[] sent = conversation.LastEventSentActors()
    int i = 0
    while sent && i < sent.Length
        Actor npc = sent[i] as Actor
        if npc && !conversation.Participants.HasForm(npc)
            Note(label + " Event: bringing in " + npc.GetDisplayName() + ", as if by shouting")
            conversation.JoinByShouting(npc)
            return
        endIf
        i += 1
    endWhile
    Note(label + " Event: nobody brought in, as it sent nobody new in full")
EndFunction

; On screen, and in the Papyrus log (Papyrus.0.log) when Papyrus logging is on
; Stays on screen until closed, so the end isn't missed
Function Done() global
    Stop("done. Now press Enter in the window of conversation_events_ingame.py")
EndFunction

; A last note that stays on screen until closed
Function Stop(string text) global
    Note(text)
    Debug.MessageBox("Event test: " + text)
EndFunction

Function Note(string text) global
    Debug.Notification("Event test: " + text)
    Debug.Trace("Event test: " + text)
EndFunction
