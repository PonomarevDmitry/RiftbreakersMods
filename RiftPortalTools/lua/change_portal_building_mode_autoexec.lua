------ #warning Commented Local ------
do return end

local supported_item_blueprints = {

     "buildings/defense/portal",
     "buildings/defense/portal_ghost",
}

local change_portal_building_mode_autoexec = function()

    for _,blueprintName in ipairs(supported_item_blueprints) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        local buildingDesc = blueprint:GetComponent("BuildingDesc")

        if ( buildingDesc ~= nil ) then

            buildingDesc:GetField("building_mode"):SetValue("portal_construction")
        end
    end
end

change_portal_building_mode_autoexec()

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    change_portal_building_mode_autoexec()
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    change_portal_building_mode_autoexec()
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    change_portal_building_mode_autoexec()
end)