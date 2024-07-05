require("lua/utils/reflection.lua")

local InjectChangeCharacterBlueprintRadar = function(blueprintName)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeCharacterBlueprintRadar Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local entityStatComponent = blueprint:GetComponent("EntityStatComponent")
    if ( entityStatComponent == nil ) then
        LogService:Log("InjectChangeCharacterBlueprintRadar Blueprint '" .. blueprintName .. "' EntityStatComponent NOT EXISTS.")
        return
    end

    local baseStatsArray = entityStatComponent:GetField("base_stats"):ToContainer()
    if ( baseStatsArray == nil ) then
        LogService:Log("InjectChangeCharacterBlueprintRadar Blueprint '" .. blueprintName .. "' equipmentItem:GetField('base_statsArray'):ToContainer() NOT EXISTS.")
        return
    end

    for i=0,baseStatsArray:GetItemCount()-1 do

        local statObject = baseStatsArray:GetItem(i)

        local key = tonumber( statObject:GetField("key"):GetValue() )

        if ( key == EntityModType.radar_range ) then

            statObject:GetField("value"):SetValue("200")
            break
        end
    end
end

InjectChangeCharacterBlueprintRadar("player/character_base")
InjectChangeCharacterBlueprintRadar("player/character")