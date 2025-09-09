require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeListTowersValues = function()

    local supported_item_blueprints = {

        "buildings/defense/repair_facility",
        "buildings/defense/repair_facility_lvl_2",
        "buildings/defense/repair_facility_lvl_3",
    }

    local hashLampValues = 
    {
        CalcHash("wall"),
        CalcHash("tower"),
    }

    for _,blueprint_name in ipairs(supported_item_blueprints) do

        local blueprint = ResourceManager:GetBlueprint( blueprint_name )

        local building_component = blueprint:GetComponent("BuildingDesc")

        if building_component ~= nil then

            building_component:GetField("type"):SetValue("tower")

            local overridesArray = building_component:GetField("overrides"):ToContainer()

            for hashValue in Iter( hashLampValues ) do

                for k=0,overridesArray:GetItemCount()-1 do

                    local stringHash = overridesArray:GetItem(k)

                    local stringHashRef = reflection_helper(stringHash)

                    if ( stringHashRef.hash == hashValue  ) then

                        goto labelContinue
                    end
                end



                local newStringHash = overridesArray:CreateItem()

                newStringHash:GetField("hash"):SetValue(tostring(hashValue))



                ::labelContinue::
            end
        end



        local building_component = blueprint:GetComponent("BuildingComponent")

        if building_component ~= nil then

            building_component:GetField("type"):SetValue("tower")
        end
    end
end

InjectChangeListTowersValues()