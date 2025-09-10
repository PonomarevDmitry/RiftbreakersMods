require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local supported_item_blueprints = {
    "buildings/decorations/base_lamp",
    "buildings/decorations/base_lamp_blue",
    "buildings/decorations/base_lamp_cyan",
    "buildings/decorations/base_lamp_green",

    "buildings/decorations/base_lamp_orange",
    "buildings/decorations/base_lamp_red",
    "buildings/decorations/base_lamp_violet",
    "buildings/decorations/base_lamp_yellow",

    "buildings/decorations/crystal_lamp",
    "buildings/decorations/crystal_lamp_blue",
    "buildings/decorations/crystal_lamp_cyan",
    "buildings/decorations/crystal_lamp_green",

    "buildings/decorations/crystal_lamp_orange",
    "buildings/decorations/crystal_lamp_red",
    "buildings/decorations/crystal_lamp_violet",
    "buildings/decorations/crystal_lamp_yellow",
}

local hashLampValue = CalcHash("lamp")

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if building_component ~= nil then

        building_component:GetField("type"):SetValue("lamp")

        local overridesArray = building_component:GetField("overrides"):ToContainer()

        local existedStringHash = nil

        for k=0,overridesArray:GetItemCount()-1 do

            local stringHash = overridesArray:GetItem(k)

            local stringHashRef = reflection_helper(stringHash)

            if ( stringHashRef.hash == hashLampValue  ) then

                existedStringHash = stringHash
            end
        end

        if ( existedStringHash == nil ) then

            local newStringHash = overridesArray:CreateItem()

            newStringHash:GetField("hash"):SetValue(tostring(hashLampValue))
        end
    end



    local building_component = blueprint:GetComponent("BuildingComponent")

    if building_component ~= nil then

        building_component:GetField("type"):SetValue("lamp")
    end
end