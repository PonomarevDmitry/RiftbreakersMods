require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local itemList = {

    "items/mass_disassembly_rarity/standard",
    "items/mass_disassembly_rarity/advanced",
    "items/mass_disassembly_rarity/superior",
    "items/mass_disassembly_rarity/extreme"
}

for itemName in Iter( itemList ) do

    if ( IndexOf( mod_autoadding_player_inventory_list, itemName ) == nil ) then

        Insert(mod_autoadding_player_inventory_list, itemName)
    end
end



local mass_disassembly_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/main/mass_disassembly")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_by_rarity")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_equal_and_lower")
        
    BuildingService:UnlockBuilding("buildings/tools/mass_disassembly_by_rarity_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)