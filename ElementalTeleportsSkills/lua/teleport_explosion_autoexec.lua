RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    PlayerService:AddGlobalAward("items/skills/teleport_attack_standard_item", false)

    PlayerService:AddGlobalAward("items/skills/teleport_emergency_standard_item", false)

    PlayerService:AddGlobalAward("items/skills/teleport_double_standard_item", false)

    PlayerService:AddGlobalAward("items/skills/teleport_double_acid_standard_item", false)
end)