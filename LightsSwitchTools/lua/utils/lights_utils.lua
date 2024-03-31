require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local LightsUtils = {}

function LightsUtils:BlueprintHasEffectGroup( blueprintName, effectGroupName )

    if ( blueprintName == nil or blueprintName == "" ) then
        return false
    end

    if ( global_lights_cache == nil ) then
        global_lights_cache = {}
    end

    if ( global_lights_cache[blueprintName] == nil ) then
        global_lights_cache[blueprintName] = {}
    end

    local blueprintCache = global_lights_cache[blueprintName]

    if ( blueprintCache[effectGroupName] == nil ) then
        blueprintCache[effectGroupName] = LightsUtils:CalcBlueprintHasEffectGroup( blueprintName, effectGroupName )
    end

    return blueprintCache[effectGroupName]
end

function LightsUtils:CalcBlueprintHasEffectGroup( blueprintName, effectGroupName )

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local effectDesc = blueprint:GetComponent("EffectDesc")
    if ( effectDesc == nil ) then
        return false
    end

    local effectDescRef = setmetatable( {}, TypeValueHelper.mt );
    rawset(effectDescRef, "__ptr", effectDesc);

    if ( effectDescRef.Effects ) then

        for i=1,effectDescRef.Effects.count do

            local effectInstance = effectDescRef.Effects[i]

            if ( effectInstance and effectInstance.group and effectInstance.group == effectGroupName ) then

                return true
            end
        end
    end

    return false
end

return LightsUtils