Scriptname MantellaEquipmentDescriber extends Quest hidden

Import SKSE_HTTP

string property Equipment = "mantella_equipment" auto
string property Body = "body" auto
string property Head = "head" auto
string property hands = "hands" auto
string property Feet = "feet" auto
string property Amulet = "amulet" auto
string property RightHand = "righthand" auto
string property LeftHand = "lefthand" auto

int[] _armorSlots
string[] _constants
string[] _spells

event OnInit()
    _armorSlots = new int[5]
    _constants = new string[5]
    _armorSlots[0] = 32
    _constants[0] = Body
    _armorSlots[1] = 31
    _constants[1] = Head
    _armorSlots[2] = 33
    _constants[2] = hands
    _armorSlots[3] = 37
    _constants[3] = Feet
    _armorSlots[4] = 35
    _constants[4] = Amulet
endEvent

int Function AddEquipmentDescription(int handle, Actor actorToDescribeEquipmentOf, bool isPlayer, MantellaRepository repository)
    int equipmentHandle = SKSE_HTTP.createDictionary()
    bool[] trackingOptions
    If (isPlayer)
        trackingOptions = GetPlayerSlotTrackingOptions(repository)
    else
        trackingOptions = GetTargetSlotTrackingOptions(repository)
    EndIf
    int i = 0
    While (i < 5)
        if(trackingOptions[i])
            Armor equippedArmor = actorToDescribeEquipmentOf.GetEquippedArmorInSlot(_armorSlots[i])
            If (equippedArmor)
                SKSE_HTTP.setString(equipmentHandle, _constants[i], equippedArmor.GetName())
            EndIf
        EndIf
        i += 1
    EndWhile
    
    ;Right Hand
    if(trackingOptions[5])
        Weapon equippedWeapon = actorToDescribeEquipmentOf.GetEquippedWeapon(false)
        If (equippedWeapon)
            SKSE_HTTP.setString(equipmentHandle, RightHand, equippedWeapon.GetName())
        EndIf
    EndIf
    ;Offhand
    if(trackingOptions[6])
        Weapon equippedWeapon = actorToDescribeEquipmentOf.GetEquippedWeapon(true)
        If (equippedWeapon)
            SKSE_HTTP.setString(equipmentHandle, LeftHand, equippedWeapon.GetName())
        EndIf
    EndIf

    ; Spells
    if !(isPlayer)
        _spells = GetSpellListFromActor(actorToDescribeEquipmentOf)
        SKSE_HTTP.setStringArray(equipmentHandle, "Spells", _spells)
    endIf
    

    SKSE_HTTP.setNestedDictionary(handle, Equipment, equipmentHandle)
EndFunction


bool[] Function GetPlayerSlotTrackingOptions(MantellaRepository repository)
    bool[] result = new bool[7]
    result[0] = repository.playerEquipmentBody
    result[1] = repository.playerEquipmentHead
    result[2] = repository.playerEquipmentHands
    result[3] = repository.playerEquipmentFeet
    result[4] = repository.playerEquipmentAmulet
    result[5] = repository.playerEquipmentRightHand
    result[6] = repository.playerEquipmentLeftHand
    return result
EndFunction

bool[] Function GetTargetSlotTrackingOptions(MantellaRepository repository)
    bool[] result = new bool[7]
    result[0] = repository.targetEquipmentBody
    result[1] = repository.targetEquipmentHead
    result[2] = repository.targetEquipmentHands
    result[3] = repository.targetEquipmentFeet
    result[4] = repository.targetEquipmentAmulet
    result[5] = repository.targetEquipmentRightHand
    result[6] = repository.targetEquipmentLeftHand
    return result
EndFunction


; The spells the NPC can cast, for CastSpell. Up to 20, the spells added to this NPC first (AddSpell), then those of their kind. Left out:
; abilities, which are always on and can't be cast (other mods give NPCs many, mostly without a name), and hidden spells mods cast by
; script. Otherwise they take the places of the real spells, and the NPC is told it knows spells it can't cast
string[] Function GetSpellListFromActor(actor currentActor)
    int spellCap = 20
    string[] spellNames = Utility.CreateStringArray(spellCap) ; Places left empty are skipped by Mantella
    int spellIndex = 0

    int i = 0
    int actorSpellCount = currentActor.GetSpellCount()
    while (i < actorSpellCount) && (spellIndex < spellCap)
        spellIndex = AddCastableSpell(currentActor.GetNthSpell(i), spellNames, spellIndex)
        i += 1
    endwhile

    ActorBase currentActorBase = currentActor.GetActorBase()
    int j = 0
    int actorBaseSpellCount = currentActorBase.GetSpellCount()
    while (j < actorBaseSpellCount) && (spellIndex < spellCap)
        spellIndex = AddCastableSpell(currentActorBase.GetNthSpell(j), spellNames, spellIndex)
        j += 1
    endwhile

    return spellNames
Endfunction

; Puts the spell's name in the next free place if it can be cast and isn't listed yet. Returns where the next one goes
int Function AddCastableSpell(Spell currentSpell, string[] spellNames, int spellIndex)
    if !CanBeCast(currentSpell)
        return spellIndex
    endIf
    string spellName = currentSpell.GetName()
    if spellNames.Find(spellName) >= 0
        return spellIndex
    endIf
    spellNames[spellIndex] = spellName
    return spellIndex + 1
EndFunction

bool Function CanBeCast(Spell currentSpell)
    if !currentSpell
        return false
    endIf
    string spellName = currentSpell.GetName()
    if spellName == "" || spellName == "MantellaIsTalkingSpell"
        return false
    endIf
    MagicEffect mainEffect = currentSpell.GetNthEffectMagicEffect(currentSpell.GetCostliestEffectIndex())
    if !mainEffect
        return false
    endIf
    if mainEffect.GetCastingType() == 0 ; Constant Effect: an ability
        return false
    endIf
    return !mainEffect.IsEffectFlagSet(0x00008000) ; HideInUI: a spell mods cast by script, never shown to the player
EndFunction