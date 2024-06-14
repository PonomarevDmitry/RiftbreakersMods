require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local PowerUtils = {}

function PowerUtils:CanChangePower( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( blueprintName == nil or blueprintName == "" ) then
        return false
    end

    return PowerUtils:BlueprintCanChangePower( blueprintName )
end

function PowerUtils:BlueprintCanChangePower( blueprintName )

    if ( blueprintName == nil or blueprintName == "" ) then
        return false
    end

    if ( switch_turn_on_off_toolCache == nil ) then
        switch_turn_on_off_toolCache = {}
    end

    if ( switch_turn_on_off_toolCache[blueprintName] == nil ) then
        switch_turn_on_off_toolCache[blueprintName] = PowerUtils:CalcCanChangePower( blueprintName )
    end

    return switch_turn_on_off_toolCache[blueprintName]
end

function PowerUtils:CalcCanChangePower( blueprintName )

    local blueprintBuildingDesc = EntityService:GetBlueprintComponent(blueprintName, "BuildingDesc")
    if ( blueprintBuildingDesc == nil ) then
        return false
    end

    local disableableValue = tonumber( blueprintBuildingDesc:GetField( "disableable" ):GetValue() )
    if ( disableableValue ~= 1 ) then
        return false
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
    if ( resourceConverterDesc == nil ) then
        return false
    end

    local resourceConverterRef = reflection_helper(resourceConverterDesc)
    if ( resourceConverterRef == nil or resourceConverterRef["in"] == nil ) then
        return false
    end

    local inValue = resourceConverterRef["in"]
    if ( inValue.count == 0 ) then
        return false
    end

    for i = 1,inValue.count do

        local resource = inValue[i]

        if ( resource ~= nil and resource.value ~= nil and resource.value > 0 ) then
            return true
        end
    end

    return false
end

return PowerUtils