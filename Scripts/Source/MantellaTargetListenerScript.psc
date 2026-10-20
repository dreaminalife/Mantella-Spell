Scriptname MantellaTargetListenerScript extends ReferenceAlias
;new property added after Mantella 0.9.2

Actor Property PlayerRef Auto
MantellaRepository property repository auto
MantellaConversation Property conversation auto

event OnInit()
    conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
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

string Function getPlayerName(bool isStartOfSentence = True)
    if (repository.playerTrackingUsePCName)
        return PlayerRef.GetDisplayName()
    Elseif (isStartOfSentence)
        return "The player"
    Else
        return "the player"
    endif
EndFunction

;All the event listeners below have 'if' clauses added after Mantella 0.9.2 (except ondying)
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if repository.targetTrackingItemAdded 
        String selfName = self.GetActorReference().getdisplayname()
        string itemName = akBaseItem.GetName()
        string itemCount = ""
        if itemName == "gold" ; only count the number of items if it is gold
            itemCount = aiItemCount+" "
        endIf

        string itemPickedUpMessage = selfName+" picked up " + itemCount + itemName 

        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != ""
            itemPickedUpMessage = selfName+" picked up " + itemCount + itemName + " from " + sourceName 
        endIf
        
        if (itemName != "Iron Arrow") && (itemName != "") && sourceName != PlayerRef.GetDisplayName() ;Papyrus hallucinates iron arrows
            ;Debug.Notification(itemPickedUpMessage)
            AddIngameEventToConversation( itemPickedUpMessage)
        endIf
    endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if repository.targetTrackingItemRemoved  
        String selfName = self.GetActorReference().getdisplayname()
        string itemName = akBaseItem.GetName()
        string itemCount = ""
        if itemName == "gold" ; only count the number of items if it is gold
            itemCount = aiItemCount+" "
        endIf

        string itemDroppedMessage = selfName+" dropped " + itemCount + itemName

        string destName = akDestContainer.getbaseobject().getname()
        if (destName != "")
            itemDroppedMessage = selfName+" placed " + itemCount + itemName + " in/on " + destName 
        endIf
        
        if  (itemName != "Iron Arrow") && (itemName != "") && destName != PlayerRef.GetDisplayName() ; Papyrus hallucinates iron arrows
            ;Debug.Notification(itemDroppedMessage)
            AddIngameEventToConversation(itemDroppedMessage)
        endIf
    endif
endEvent


Event OnSpellCast(Form akSpell)
    if repository.targetTrackingOnSpellCast 
        String selfName = self.GetActorReference().getdisplayname()
        string spellCast = (akSpell as form).getname()
        if spellCast 
            ;Debug.Notification(selfName+" casted the spell "+ spellCast)
            AddIngameEventToConversation(selfName+" casted the spell " + spellCast , true)
        endIf
    endif
endEvent


Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    if repository.targetTrackingOnHit 
        String aggressor
        if akAggressor == PlayerRef
            aggressor = getPlayerName()
        else
            aggressor = akAggressor.getdisplayname()
        endif
        string hitSource = akSource.getname()
        String selfName = self.GetActorReference().getdisplayname()

        ; Continuous spells hit very frequently, so repeats are limited by the event repeat cooldown
        if (hitSource != "Mantella") && (hitSource != "Mantella Remove NPC") && (hitSource != "Mantella End Conversation")
            if (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched "+selfName+".")
                AddIngameEventToConversation(aggressor + " punched "+selfName, true)
            elseif hitSource == "Mantella"
                ; Do not save event if Mantella itself is cast
            else
                ;Debug.MessageBox(aggressor + " hit "+selfName+" with a(n) " + hitSource)
                AddIngameEventToConversation(aggressor + " hit "+selfName+" with " + hitSource, true)
            endIf
        endIf
    endif
EndEvent


Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
    if repository.targetTrackingOnCombatStateChanged
        String selfName = self.GetActorReference().getdisplayname()
        String targetName
        if akTarget == PlayerRef
            targetName = getPlayerName(False)
        else
            targetName = akTarget.getdisplayname()
        endif

        if (aeCombatState == 0)
            ;Debug.MessageBox(selfName+" is no longer in combat")
            AddIngameEventToConversation(selfName+" is no longer in combat.")
            ;ToDo: Find a new way to trigger interrupting the LLM when combat state changes
            ;MiscUtil.WriteToFile("_mantella_actor_is_in_combat.txt", "False", append=false)
        elseif (aeCombatState == 1)
            ;Debug.MessageBox(selfName+" has entered combat with "+targetName)
            AddIngameEventToConversation(selfName+" has entered combat with "+targetName)
            ;ToDo: Find a new way to trigger interrupting the LLM when combat state changes
            ;MiscUtil.WriteToFile("_mantella_actor_is_in_combat.txt", "True", append=false)
        elseif (aeCombatState == 2)
            ;Debug.MessageBox(selfName+" is searching for "+targetName)
            AddIngameEventToConversation( selfName+" is searching for "+targetName)
        endIf
    endif
endEvent


Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectEquipped
        String selfName = self.GetActorReference().getdisplayname()
        string itemEquipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" equipped " + itemEquipped)
        AddIngameEventToConversation(selfName+" equipped " + itemEquipped )
    endif
endEvent


Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
    if repository.targetTrackingOnObjectUnequipped
        String selfName = self.GetActorReference().getdisplayname()
        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox(selfName+" unequipped " + itemUnequipped)
        AddIngameEventToConversation(selfName+" unequipped " + itemUnequipped )
    endif
endEvent


Event OnSit(ObjectReference akFurniture)
    if repository.targetTrackingOnSit
        String selfName = self.GetActorReference().getdisplayname()
        ;Debug.MessageBox(selfName+" sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            AddIngameEventToConversation(selfName+" rested on / used a(n) "+furnitureName)
        endIf
    endif
endEvent


Event OnGetUp(ObjectReference akFurniture)
    if  repository.targetTrackingOnGetUp
        String selfName = self.GetActorReference().getdisplayname()
        ;Debug.MessageBox(selfName+" stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        ; only save event if actor is sitting / resting on furniture (and not just, for example, leaning on a bar table)
        if furnitureName != ""
            AddIngameEventToConversation(selfName+" stood up from a(n) "+furnitureName)
        endIf
    endif
EndEvent


; The conversation goes on without the dead NPC. It only ends if fewer than two participants are left
Event OnDying(Actor akKiller)
    If (conversation.IsRunning())
        Actor selfActor = self.GetActorReference()
        If (!selfActor) ; The alias was cleared, e.g. by another participant leaving at the same time
            return
        EndIf
        String deathMessage = selfActor.GetDisplayName() + " died"
        If (akKiller == PlayerRef)
            deathMessage = selfActor.GetDisplayName() + " was killed by " + getPlayerName(False)
        ElseIf (akKiller)
            deathMessage = selfActor.GetDisplayName() + " was killed by " + akKiller.GetDisplayName()
        EndIf
        AddIngameEventToConversation(deathMessage)

        Actor[] actors = new Actor[1]
        actors[0] = selfActor
        conversation.RemoveActorsFromConversation(actors)
    EndIf
EndEvent
