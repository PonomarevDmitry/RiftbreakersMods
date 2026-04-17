require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeBlueprintLifeTimeDesc = function(blueprintName, newLifeTimeValue)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )

    if ( blueprint == nil ) then

        LogService:Log("InjectChangeBlueprintLifeTimeDesc Blueprint " .. blueprintName .. " NOT EXISTS.")
        return
    end

    local lifeTimeDesc = blueprint:GetComponent("LifeTimeDesc")

    if ( lifeTimeDesc ~= nil ) then
    
        lifeTimeDesc:GetField("time"):SetValue(newLifeTimeValue)
    else
                
        LogService:Log("InjectChangeBlueprintLifeTimeDesc Blueprint " .. blueprintName .. " LifeTimeDesc NOT EXISTS.")
    end

    local lifeTimeComponent = blueprint:GetComponent("LifeTimeComponent")

    if ( lifeTimeComponent ~= nil ) then
    
        local timeValue = lifeTimeComponent:GetField("time")

        if timeValue ~= nil then
    
            timeValue:GetField("timeLimit"):SetValue(newLifeTimeValue)

        else
                
            LogService:Log("InjectChangeBlueprintLifeTimeDesc Blueprint " .. blueprintName .. " LifeTimeComponent timeValue == nil.")
        end
    else
                
        LogService:Log("InjectChangeBlueprintLifeTimeDesc Blueprint " .. blueprintName .. " LifeTimeComponent NOT EXISTS.")
    end
end



InjectChangeBlueprintLifeTimeDesc("items/special/multiplayer_boost_interactive_overchage", "300")

InjectChangeBlueprintLifeTimeDesc("items/special/multiplayer_boost_effect_2", "300")

InjectChangeBlueprintLifeTimeDesc("items/special/multiplayer_boost_effect_3", "400")

InjectChangeBlueprintLifeTimeDesc("items/special/multiplayer_boost_effect_4", "500")
