Scriptname MantellaMCM_ShoutSettings  Hidden
{The Shout Mode page. Shout itself is switched on and off from the Conversation Wheel}

function Render(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)
    LeftColumn(mcm, Repository)
    mcm.SetCursorPosition(1)
    RightColumn(mcm, Repository)
endfunction

function LeftColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Joining")
    mcm.oid_shoutLinesBetweenJoins = mcm.AddSliderOption("Lines Between Joins", repository.shoutLinesBetweenJoins)
    mcm.oid_shoutMaxPeople = mcm.AddSliderOption("Most People in Conversation", repository.shoutMaxPeople)
    mcm.oid_showShoutMessages = mcm.AddToggleOption("Show Messages", repository.showShoutMessages)
endfunction

function RightColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Who Is Nearby")
    mcm.oid_shoutHearingDistance = mcm.AddSliderOption("Hearing Distance (m)", repository.shoutHearingDistance)
    mcm.oid_shoutMaxListed = mcm.AddSliderOption("Most People Listed", repository.shoutMaxListed)
    mcm.oid_shoutMaxCandidates = mcm.AddSliderOption("Most People Described", repository.shoutMaxCandidates)
    mcm.oid_shoutRequireLineOfSight = mcm.AddToggleOption("Must Be in Sight", repository.shoutRequireLineOfSight)
endfunction

function SliderOptionOpen(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_shoutLinesBetweenJoins
        mcm.SetSliderDialogStartValue(repository.shoutLinesBetweenJoins)
        mcm.SetSliderDialogDefaultValue(3)
        mcm.SetSliderDialogRange(0, 20)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_shoutMaxPeople
        mcm.SetSliderDialogStartValue(repository.shoutMaxPeople)
        mcm.SetSliderDialogDefaultValue(6)
        mcm.SetSliderDialogRange(2, 10)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_shoutHearingDistance
        mcm.SetSliderDialogStartValue(repository.shoutHearingDistance)
        mcm.SetSliderDialogDefaultValue(20)
        mcm.SetSliderDialogRange(5, 100)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_shoutMaxCandidates
        mcm.SetSliderDialogStartValue(repository.shoutMaxCandidates)
        mcm.SetSliderDialogDefaultValue(6)
        mcm.SetSliderDialogRange(0, 10)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_shoutMaxListed
        mcm.SetSliderDialogStartValue(repository.shoutMaxListed)
        mcm.SetSliderDialogDefaultValue(30)
        mcm.SetSliderDialogRange(1, 30)
        mcm.SetSliderDialogInterval(1)
    endif
endfunction

function SliderOptionAccept(MantellaMCM mcm, int optionID, float value, MantellaRepository Repository) global
    mcm.SetSliderOptionValue(optionId, value)
    If optionId == mcm.oid_shoutLinesBetweenJoins
        Repository.shoutLinesBetweenJoins = value as int
    elseIf optionId == mcm.oid_shoutMaxPeople
        Repository.shoutMaxPeople = value as int
    elseIf optionId == mcm.oid_shoutHearingDistance
        Repository.shoutHearingDistance = value
    elseIf optionId == mcm.oid_shoutMaxCandidates
        Repository.shoutMaxCandidates = value as int
    elseIf optionId == mcm.oid_shoutMaxListed
        Repository.shoutMaxListed = value as int
    EndIf
endfunction

function OptionUpdate(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_shoutRequireLineOfSight
        Repository.shoutRequireLineOfSight =! Repository.shoutRequireLineOfSight
        mcm.SetToggleOptionValue(optionID, Repository.shoutRequireLineOfSight)
    elseIf optionID == mcm.oid_showShoutMessages
        Repository.showShoutMessages =! Repository.showShoutMessages
        mcm.SetToggleOptionValue(optionID, Repository.showShoutMessages)
    endif
endfunction
