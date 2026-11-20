Scriptname MantellaAdvancedAction_AddToConv extends Quest Hidden 

Actor Property PlayerRef Auto
MantellaConstants property mConsts auto
MantellaInterface property EventInterface Auto

event OnInit()
    RegisterForModEvent(EventInterface.EVENT_ADVANCED_ACTIONS_PREFIX + mConsts.ACTION_NPC_ADDTOCONVERSATION, "OnNpcAddToConversationAdvancedActionReceived")
EndEvent


event OnNpcAddToConversationAdvancedActionReceived(Form speaker, Form conversationQuest, int argumentsHandle)
    MantellaConversation conversation = conversationQuest as MantellaConversation
    int maxActors = 5
    
    ; Extract NPC names from parameters
    string[] sourceNames = SKSE_HTTP.getStringArray(argumentsHandle, mConsts.ACTION_ARG_SOURCE)
    Actor[] found = new Actor[5]
    int foundCount = 0

    ; Resolve each name to an Actor reference. Only people who are free to talk are called over: not dead, hostile, in combat, in a scene...
    int i = 0
    While (i < sourceNames.Length) && (i < maxActors)
        Actor sourceActor = conversation.GetActorByName(sourceNames[i])
        if sourceActor && found.Find(sourceActor) < 0
            string reason = MantellaActorChecks.UnavailableReason(sourceActor)
            if reason == ""
                Debug.Notification("Adding " + sourceNames[i] + " to conversation...")
                found[foundCount] = sourceActor
                foundCount += 1
            else
                Debug.Notification(sourceNames[i] + " can't join: " + reason)
            endif
        endif
        i += 1
    EndWhile

    if foundCount == 0
        return
    endif
    ; Only the people found, without empty places: the Vanilla Dialogue plugin is told who joined, and an empty place could crash it
    Actor[] sourceActors = PapyrusUtil.ActorArray(foundCount)
    int j = 0
    While j < foundCount
        sourceActors[j] = found[j]
        j += 1
    EndWhile
    conversation.AddActorsToConversation(sourceActors)
endEvent